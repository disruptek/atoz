
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

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
  awsServiceName = "apigateway"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_601012 = ref object of OpenApiRestCall_600410
proc url_CreateApiKey_601014(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApiKey_601013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601015 = header.getOrDefault("X-Amz-Date")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Date", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Security-Token")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Security-Token", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-Content-Sha256", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Algorithm")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Algorithm", valid_601018
  var valid_601019 = header.getOrDefault("X-Amz-Signature")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-Signature", valid_601019
  var valid_601020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-SignedHeaders", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Credential")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Credential", valid_601021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601023: Call_CreateApiKey_601012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_601023.validator(path, query, header, formData, body)
  let scheme = call_601023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601023.url(scheme.get, call_601023.host, call_601023.base,
                         call_601023.route, valid.getOrDefault("path"))
  result = hook(call_601023, url, valid)

proc call*(call_601024: Call_CreateApiKey_601012; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_601025 = newJObject()
  if body != nil:
    body_601025 = body
  result = call_601024.call(nil, nil, nil, nil, body_601025)

var createApiKey* = Call_CreateApiKey_601012(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_601013, base: "/", url: url_CreateApiKey_601014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_600752 = ref object of OpenApiRestCall_600410
proc url_GetApiKeys_600754(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApiKeys_600753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600866 = query.getOrDefault("customerId")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "customerId", valid_600866
  var valid_600867 = query.getOrDefault("includeValues")
  valid_600867 = validateParameter(valid_600867, JBool, required = false, default = nil)
  if valid_600867 != nil:
    section.add "includeValues", valid_600867
  var valid_600868 = query.getOrDefault("name")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "name", valid_600868
  var valid_600869 = query.getOrDefault("position")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "position", valid_600869
  var valid_600870 = query.getOrDefault("limit")
  valid_600870 = validateParameter(valid_600870, JInt, required = false, default = nil)
  if valid_600870 != nil:
    section.add "limit", valid_600870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600900: Call_GetApiKeys_600752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_600900.validator(path, query, header, formData, body)
  let scheme = call_600900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600900.url(scheme.get, call_600900.host, call_600900.base,
                         call_600900.route, valid.getOrDefault("path"))
  result = hook(call_600900, url, valid)

proc call*(call_600971: Call_GetApiKeys_600752; customerId: string = "";
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
  var query_600972 = newJObject()
  add(query_600972, "customerId", newJString(customerId))
  add(query_600972, "includeValues", newJBool(includeValues))
  add(query_600972, "name", newJString(name))
  add(query_600972, "position", newJString(position))
  add(query_600972, "limit", newJInt(limit))
  result = call_600971.call(nil, query_600972, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_600752(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_600753,
                                      base: "/", url: url_GetApiKeys_600754,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_601057 = ref object of OpenApiRestCall_600410
proc url_CreateAuthorizer_601059(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateAuthorizer_601058(path: JsonNode; query: JsonNode;
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
  var valid_601060 = path.getOrDefault("restapi_id")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = nil)
  if valid_601060 != nil:
    section.add "restapi_id", valid_601060
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
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_CreateAuthorizer_601057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"))
  result = hook(call_601069, url, valid)

proc call*(call_601070: Call_CreateAuthorizer_601057; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601071 = newJObject()
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  add(path_601071, "restapi_id", newJString(restapiId))
  result = call_601070.call(path_601071, nil, nil, nil, body_601072)

var createAuthorizer* = Call_CreateAuthorizer_601057(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_601058, base: "/",
    url: url_CreateAuthorizer_601059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_601026 = ref object of OpenApiRestCall_600410
proc url_GetAuthorizers_601028(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAuthorizers_601027(path: JsonNode; query: JsonNode;
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
  var valid_601043 = path.getOrDefault("restapi_id")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "restapi_id", valid_601043
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601044 = query.getOrDefault("position")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "position", valid_601044
  var valid_601045 = query.getOrDefault("limit")
  valid_601045 = validateParameter(valid_601045, JInt, required = false, default = nil)
  if valid_601045 != nil:
    section.add "limit", valid_601045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601053: Call_GetAuthorizers_601026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_601053.validator(path, query, header, formData, body)
  let scheme = call_601053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601053.url(scheme.get, call_601053.host, call_601053.base,
                         call_601053.route, valid.getOrDefault("path"))
  result = hook(call_601053, url, valid)

proc call*(call_601054: Call_GetAuthorizers_601026; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601055 = newJObject()
  var query_601056 = newJObject()
  add(query_601056, "position", newJString(position))
  add(query_601056, "limit", newJInt(limit))
  add(path_601055, "restapi_id", newJString(restapiId))
  result = call_601054.call(path_601055, query_601056, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_601026(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_601027, base: "/", url: url_GetAuthorizers_601028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_601090 = ref object of OpenApiRestCall_600410
proc url_CreateBasePathMapping_601092(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateBasePathMapping_601091(path: JsonNode; query: JsonNode;
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
  var valid_601093 = path.getOrDefault("domain_name")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = nil)
  if valid_601093 != nil:
    section.add "domain_name", valid_601093
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_CreateBasePathMapping_601090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"))
  result = hook(call_601102, url, valid)

proc call*(call_601103: Call_CreateBasePathMapping_601090; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_601104 = newJObject()
  var body_601105 = newJObject()
  add(path_601104, "domain_name", newJString(domainName))
  if body != nil:
    body_601105 = body
  result = call_601103.call(path_601104, nil, nil, nil, body_601105)

var createBasePathMapping* = Call_CreateBasePathMapping_601090(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_601091, base: "/",
    url: url_CreateBasePathMapping_601092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_601073 = ref object of OpenApiRestCall_600410
proc url_GetBasePathMappings_601075(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBasePathMappings_601074(path: JsonNode; query: JsonNode;
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
  var valid_601076 = path.getOrDefault("domain_name")
  valid_601076 = validateParameter(valid_601076, JString, required = true,
                                 default = nil)
  if valid_601076 != nil:
    section.add "domain_name", valid_601076
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601077 = query.getOrDefault("position")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "position", valid_601077
  var valid_601078 = query.getOrDefault("limit")
  valid_601078 = validateParameter(valid_601078, JInt, required = false, default = nil)
  if valid_601078 != nil:
    section.add "limit", valid_601078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601079 = header.getOrDefault("X-Amz-Date")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Date", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Security-Token")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Security-Token", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Content-Sha256", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Algorithm")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Algorithm", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Signature")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Signature", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-SignedHeaders", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Credential")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Credential", valid_601085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_GetBasePathMappings_601073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_GetBasePathMappings_601073; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_601088 = newJObject()
  var query_601089 = newJObject()
  add(path_601088, "domain_name", newJString(domainName))
  add(query_601089, "position", newJString(position))
  add(query_601089, "limit", newJInt(limit))
  result = call_601087.call(path_601088, query_601089, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_601073(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_601074, base: "/",
    url: url_GetBasePathMappings_601075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_601123 = ref object of OpenApiRestCall_600410
proc url_CreateDeployment_601125(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDeployment_601124(path: JsonNode; query: JsonNode;
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
  var valid_601126 = path.getOrDefault("restapi_id")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "restapi_id", valid_601126
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
  var valid_601127 = header.getOrDefault("X-Amz-Date")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Date", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Security-Token")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Security-Token", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Content-Sha256", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Algorithm")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Algorithm", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Signature")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Signature", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-SignedHeaders", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Credential")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Credential", valid_601133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601135: Call_CreateDeployment_601123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_601135.validator(path, query, header, formData, body)
  let scheme = call_601135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601135.url(scheme.get, call_601135.host, call_601135.base,
                         call_601135.route, valid.getOrDefault("path"))
  result = hook(call_601135, url, valid)

proc call*(call_601136: Call_CreateDeployment_601123; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601137 = newJObject()
  var body_601138 = newJObject()
  if body != nil:
    body_601138 = body
  add(path_601137, "restapi_id", newJString(restapiId))
  result = call_601136.call(path_601137, nil, nil, nil, body_601138)

var createDeployment* = Call_CreateDeployment_601123(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_601124, base: "/",
    url: url_CreateDeployment_601125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_601106 = ref object of OpenApiRestCall_600410
proc url_GetDeployments_601108(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeployments_601107(path: JsonNode; query: JsonNode;
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
  var valid_601109 = path.getOrDefault("restapi_id")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "restapi_id", valid_601109
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601110 = query.getOrDefault("position")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "position", valid_601110
  var valid_601111 = query.getOrDefault("limit")
  valid_601111 = validateParameter(valid_601111, JInt, required = false, default = nil)
  if valid_601111 != nil:
    section.add "limit", valid_601111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601112 = header.getOrDefault("X-Amz-Date")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Date", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Security-Token")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Security-Token", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Content-Sha256", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Algorithm")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Algorithm", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Signature")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Signature", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-SignedHeaders", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Credential")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Credential", valid_601118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601119: Call_GetDeployments_601106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_601119.validator(path, query, header, formData, body)
  let scheme = call_601119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601119.url(scheme.get, call_601119.host, call_601119.base,
                         call_601119.route, valid.getOrDefault("path"))
  result = hook(call_601119, url, valid)

proc call*(call_601120: Call_GetDeployments_601106; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601121 = newJObject()
  var query_601122 = newJObject()
  add(query_601122, "position", newJString(position))
  add(query_601122, "limit", newJInt(limit))
  add(path_601121, "restapi_id", newJString(restapiId))
  result = call_601120.call(path_601121, query_601122, nil, nil, nil)

var getDeployments* = Call_GetDeployments_601106(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_601107, base: "/", url: url_GetDeployments_601108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_601173 = ref object of OpenApiRestCall_600410
proc url_ImportDocumentationParts_601175(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ImportDocumentationParts_601174(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_601176 = path.getOrDefault("restapi_id")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "restapi_id", valid_601176
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_601177 = query.getOrDefault("mode")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = newJString("merge"))
  if valid_601177 != nil:
    section.add "mode", valid_601177
  var valid_601178 = query.getOrDefault("failonwarnings")
  valid_601178 = validateParameter(valid_601178, JBool, required = false, default = nil)
  if valid_601178 != nil:
    section.add "failonwarnings", valid_601178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Content-Sha256", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Algorithm")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Algorithm", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Signature")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Signature", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-SignedHeaders", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Credential")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Credential", valid_601185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_ImportDocumentationParts_601173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_ImportDocumentationParts_601173; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601189 = newJObject()
  var query_601190 = newJObject()
  var body_601191 = newJObject()
  add(query_601190, "mode", newJString(mode))
  add(query_601190, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_601191 = body
  add(path_601189, "restapi_id", newJString(restapiId))
  result = call_601188.call(path_601189, query_601190, nil, nil, body_601191)

var importDocumentationParts* = Call_ImportDocumentationParts_601173(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_601174, base: "/",
    url: url_ImportDocumentationParts_601175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_601192 = ref object of OpenApiRestCall_600410
proc url_CreateDocumentationPart_601194(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDocumentationPart_601193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_601195 = path.getOrDefault("restapi_id")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = nil)
  if valid_601195 != nil:
    section.add "restapi_id", valid_601195
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
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Content-Sha256", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Algorithm")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Algorithm", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Signature")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Signature", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-SignedHeaders", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Credential")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Credential", valid_601202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601204: Call_CreateDocumentationPart_601192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601204.validator(path, query, header, formData, body)
  let scheme = call_601204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601204.url(scheme.get, call_601204.host, call_601204.base,
                         call_601204.route, valid.getOrDefault("path"))
  result = hook(call_601204, url, valid)

proc call*(call_601205: Call_CreateDocumentationPart_601192; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601206 = newJObject()
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  add(path_601206, "restapi_id", newJString(restapiId))
  result = call_601205.call(path_601206, nil, nil, nil, body_601207)

var createDocumentationPart* = Call_CreateDocumentationPart_601192(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_601193, base: "/",
    url: url_CreateDocumentationPart_601194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_601139 = ref object of OpenApiRestCall_600410
proc url_GetDocumentationParts_601141(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentationParts_601140(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_601142 = path.getOrDefault("restapi_id")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "restapi_id", valid_601142
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
  var valid_601156 = query.getOrDefault("type")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = newJString("API"))
  if valid_601156 != nil:
    section.add "type", valid_601156
  var valid_601157 = query.getOrDefault("path")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "path", valid_601157
  var valid_601158 = query.getOrDefault("locationStatus")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_601158 != nil:
    section.add "locationStatus", valid_601158
  var valid_601159 = query.getOrDefault("name")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "name", valid_601159
  var valid_601160 = query.getOrDefault("position")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "position", valid_601160
  var valid_601161 = query.getOrDefault("limit")
  valid_601161 = validateParameter(valid_601161, JInt, required = false, default = nil)
  if valid_601161 != nil:
    section.add "limit", valid_601161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601162 = header.getOrDefault("X-Amz-Date")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Date", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Security-Token")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Security-Token", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Content-Sha256", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Algorithm")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Algorithm", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Signature")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Signature", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-SignedHeaders", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Credential")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Credential", valid_601168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_GetDocumentationParts_601139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_GetDocumentationParts_601139; restapiId: string;
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
  var path_601171 = newJObject()
  var query_601172 = newJObject()
  add(query_601172, "type", newJString(`type`))
  add(query_601172, "path", newJString(path))
  add(query_601172, "locationStatus", newJString(locationStatus))
  add(query_601172, "name", newJString(name))
  add(query_601172, "position", newJString(position))
  add(query_601172, "limit", newJInt(limit))
  add(path_601171, "restapi_id", newJString(restapiId))
  result = call_601170.call(path_601171, query_601172, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_601139(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_601140, base: "/",
    url: url_GetDocumentationParts_601141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_601225 = ref object of OpenApiRestCall_600410
proc url_CreateDocumentationVersion_601227(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDocumentationVersion_601226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_601228 = path.getOrDefault("restapi_id")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "restapi_id", valid_601228
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
  var valid_601229 = header.getOrDefault("X-Amz-Date")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Date", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Security-Token")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Security-Token", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Content-Sha256", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Algorithm")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Algorithm", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Signature")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Signature", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-SignedHeaders", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Credential")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Credential", valid_601235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601237: Call_CreateDocumentationVersion_601225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601237.validator(path, query, header, formData, body)
  let scheme = call_601237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601237.url(scheme.get, call_601237.host, call_601237.base,
                         call_601237.route, valid.getOrDefault("path"))
  result = hook(call_601237, url, valid)

proc call*(call_601238: Call_CreateDocumentationVersion_601225; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601239 = newJObject()
  var body_601240 = newJObject()
  if body != nil:
    body_601240 = body
  add(path_601239, "restapi_id", newJString(restapiId))
  result = call_601238.call(path_601239, nil, nil, nil, body_601240)

var createDocumentationVersion* = Call_CreateDocumentationVersion_601225(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_601226, base: "/",
    url: url_CreateDocumentationVersion_601227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_601208 = ref object of OpenApiRestCall_600410
proc url_GetDocumentationVersions_601210(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentationVersions_601209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_601211 = path.getOrDefault("restapi_id")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "restapi_id", valid_601211
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601212 = query.getOrDefault("position")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "position", valid_601212
  var valid_601213 = query.getOrDefault("limit")
  valid_601213 = validateParameter(valid_601213, JInt, required = false, default = nil)
  if valid_601213 != nil:
    section.add "limit", valid_601213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601214 = header.getOrDefault("X-Amz-Date")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Date", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Security-Token")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Security-Token", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Content-Sha256", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Algorithm")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Algorithm", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Signature")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Signature", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-SignedHeaders", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Credential")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Credential", valid_601220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_GetDocumentationVersions_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_GetDocumentationVersions_601208; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601223 = newJObject()
  var query_601224 = newJObject()
  add(query_601224, "position", newJString(position))
  add(query_601224, "limit", newJInt(limit))
  add(path_601223, "restapi_id", newJString(restapiId))
  result = call_601222.call(path_601223, query_601224, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_601208(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_601209, base: "/",
    url: url_GetDocumentationVersions_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_601256 = ref object of OpenApiRestCall_600410
proc url_CreateDomainName_601258(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDomainName_601257(path: JsonNode; query: JsonNode;
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
  var valid_601259 = header.getOrDefault("X-Amz-Date")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Date", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Security-Token")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Security-Token", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Content-Sha256", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Algorithm")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Algorithm", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Signature")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Signature", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-SignedHeaders", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Credential")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Credential", valid_601265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601267: Call_CreateDomainName_601256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_601267.validator(path, query, header, formData, body)
  let scheme = call_601267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601267.url(scheme.get, call_601267.host, call_601267.base,
                         call_601267.route, valid.getOrDefault("path"))
  result = hook(call_601267, url, valid)

proc call*(call_601268: Call_CreateDomainName_601256; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_601269 = newJObject()
  if body != nil:
    body_601269 = body
  result = call_601268.call(nil, nil, nil, nil, body_601269)

var createDomainName* = Call_CreateDomainName_601256(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_601257, base: "/",
    url: url_CreateDomainName_601258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_601241 = ref object of OpenApiRestCall_600410
proc url_GetDomainNames_601243(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainNames_601242(path: JsonNode; query: JsonNode;
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
  var valid_601244 = query.getOrDefault("position")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "position", valid_601244
  var valid_601245 = query.getOrDefault("limit")
  valid_601245 = validateParameter(valid_601245, JInt, required = false, default = nil)
  if valid_601245 != nil:
    section.add "limit", valid_601245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601246 = header.getOrDefault("X-Amz-Date")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Date", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Security-Token")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Security-Token", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Content-Sha256", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Algorithm")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Algorithm", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Signature")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Signature", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-SignedHeaders", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Credential")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Credential", valid_601252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601253: Call_GetDomainNames_601241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_601253.validator(path, query, header, formData, body)
  let scheme = call_601253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601253.url(scheme.get, call_601253.host, call_601253.base,
                         call_601253.route, valid.getOrDefault("path"))
  result = hook(call_601253, url, valid)

proc call*(call_601254: Call_GetDomainNames_601241; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601255 = newJObject()
  add(query_601255, "position", newJString(position))
  add(query_601255, "limit", newJInt(limit))
  result = call_601254.call(nil, query_601255, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_601241(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_601242, base: "/",
    url: url_GetDomainNames_601243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_601287 = ref object of OpenApiRestCall_600410
proc url_CreateModel_601289(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateModel_601288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601290 = path.getOrDefault("restapi_id")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "restapi_id", valid_601290
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
  var valid_601291 = header.getOrDefault("X-Amz-Date")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Date", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Security-Token")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Security-Token", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Content-Sha256", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Algorithm")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Algorithm", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Signature")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Signature", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-SignedHeaders", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Credential")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Credential", valid_601297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601299: Call_CreateModel_601287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_601299.validator(path, query, header, formData, body)
  let scheme = call_601299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601299.url(scheme.get, call_601299.host, call_601299.base,
                         call_601299.route, valid.getOrDefault("path"))
  result = hook(call_601299, url, valid)

proc call*(call_601300: Call_CreateModel_601287; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_601301 = newJObject()
  var body_601302 = newJObject()
  if body != nil:
    body_601302 = body
  add(path_601301, "restapi_id", newJString(restapiId))
  result = call_601300.call(path_601301, nil, nil, nil, body_601302)

var createModel* = Call_CreateModel_601287(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_601288,
                                        base: "/", url: url_CreateModel_601289,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_601270 = ref object of OpenApiRestCall_600410
proc url_GetModels_601272(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModels_601271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601273 = path.getOrDefault("restapi_id")
  valid_601273 = validateParameter(valid_601273, JString, required = true,
                                 default = nil)
  if valid_601273 != nil:
    section.add "restapi_id", valid_601273
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601274 = query.getOrDefault("position")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "position", valid_601274
  var valid_601275 = query.getOrDefault("limit")
  valid_601275 = validateParameter(valid_601275, JInt, required = false, default = nil)
  if valid_601275 != nil:
    section.add "limit", valid_601275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601276 = header.getOrDefault("X-Amz-Date")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Date", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Security-Token")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Security-Token", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Content-Sha256", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Algorithm")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Algorithm", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Signature")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Signature", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-SignedHeaders", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Credential")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Credential", valid_601282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_GetModels_601270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_GetModels_601270; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601285 = newJObject()
  var query_601286 = newJObject()
  add(query_601286, "position", newJString(position))
  add(query_601286, "limit", newJInt(limit))
  add(path_601285, "restapi_id", newJString(restapiId))
  result = call_601284.call(path_601285, query_601286, nil, nil, nil)

var getModels* = Call_GetModels_601270(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_601271,
                                    base: "/", url: url_GetModels_601272,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_601320 = ref object of OpenApiRestCall_600410
proc url_CreateRequestValidator_601322(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateRequestValidator_601321(path: JsonNode; query: JsonNode;
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
  var valid_601323 = path.getOrDefault("restapi_id")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "restapi_id", valid_601323
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
  var valid_601324 = header.getOrDefault("X-Amz-Date")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Date", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Security-Token")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Security-Token", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Content-Sha256", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Algorithm")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Algorithm", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Signature")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Signature", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-SignedHeaders", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Credential")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Credential", valid_601330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_CreateRequestValidator_601320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_CreateRequestValidator_601320; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601334 = newJObject()
  var body_601335 = newJObject()
  if body != nil:
    body_601335 = body
  add(path_601334, "restapi_id", newJString(restapiId))
  result = call_601333.call(path_601334, nil, nil, nil, body_601335)

var createRequestValidator* = Call_CreateRequestValidator_601320(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_601321, base: "/",
    url: url_CreateRequestValidator_601322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_601303 = ref object of OpenApiRestCall_600410
proc url_GetRequestValidators_601305(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRequestValidators_601304(path: JsonNode; query: JsonNode;
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
  var valid_601306 = path.getOrDefault("restapi_id")
  valid_601306 = validateParameter(valid_601306, JString, required = true,
                                 default = nil)
  if valid_601306 != nil:
    section.add "restapi_id", valid_601306
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601307 = query.getOrDefault("position")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "position", valid_601307
  var valid_601308 = query.getOrDefault("limit")
  valid_601308 = validateParameter(valid_601308, JInt, required = false, default = nil)
  if valid_601308 != nil:
    section.add "limit", valid_601308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601309 = header.getOrDefault("X-Amz-Date")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Date", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Security-Token")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Security-Token", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Content-Sha256", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Algorithm")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Algorithm", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Signature")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Signature", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-SignedHeaders", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Credential")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Credential", valid_601315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601316: Call_GetRequestValidators_601303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_601316.validator(path, query, header, formData, body)
  let scheme = call_601316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601316.url(scheme.get, call_601316.host, call_601316.base,
                         call_601316.route, valid.getOrDefault("path"))
  result = hook(call_601316, url, valid)

proc call*(call_601317: Call_GetRequestValidators_601303; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601318 = newJObject()
  var query_601319 = newJObject()
  add(query_601319, "position", newJString(position))
  add(query_601319, "limit", newJInt(limit))
  add(path_601318, "restapi_id", newJString(restapiId))
  result = call_601317.call(path_601318, query_601319, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_601303(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_601304, base: "/",
    url: url_GetRequestValidators_601305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_601336 = ref object of OpenApiRestCall_600410
proc url_CreateResource_601338(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateResource_601337(path: JsonNode; query: JsonNode;
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
  var valid_601339 = path.getOrDefault("parent_id")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = nil)
  if valid_601339 != nil:
    section.add "parent_id", valid_601339
  var valid_601340 = path.getOrDefault("restapi_id")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = nil)
  if valid_601340 != nil:
    section.add "restapi_id", valid_601340
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
  var valid_601341 = header.getOrDefault("X-Amz-Date")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Date", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Security-Token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Security-Token", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_CreateResource_601336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_CreateResource_601336; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601351 = newJObject()
  var body_601352 = newJObject()
  add(path_601351, "parent_id", newJString(parentId))
  if body != nil:
    body_601352 = body
  add(path_601351, "restapi_id", newJString(restapiId))
  result = call_601350.call(path_601351, nil, nil, nil, body_601352)

var createResource* = Call_CreateResource_601336(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_601337, base: "/", url: url_CreateResource_601338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_601368 = ref object of OpenApiRestCall_600410
proc url_CreateRestApi_601370(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRestApi_601369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601371 = header.getOrDefault("X-Amz-Date")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Date", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Security-Token")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Security-Token", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_CreateRestApi_601368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_CreateRestApi_601368; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var createRestApi* = Call_CreateRestApi_601368(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_601369, base: "/", url: url_CreateRestApi_601370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_601353 = ref object of OpenApiRestCall_600410
proc url_GetRestApis_601355(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestApis_601354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601356 = query.getOrDefault("position")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "position", valid_601356
  var valid_601357 = query.getOrDefault("limit")
  valid_601357 = validateParameter(valid_601357, JInt, required = false, default = nil)
  if valid_601357 != nil:
    section.add "limit", valid_601357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601358 = header.getOrDefault("X-Amz-Date")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Date", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Security-Token")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Security-Token", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Content-Sha256", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Algorithm")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Algorithm", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Signature")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Signature", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-SignedHeaders", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Credential")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Credential", valid_601364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601365: Call_GetRestApis_601353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_601365.validator(path, query, header, formData, body)
  let scheme = call_601365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601365.url(scheme.get, call_601365.host, call_601365.base,
                         call_601365.route, valid.getOrDefault("path"))
  result = hook(call_601365, url, valid)

proc call*(call_601366: Call_GetRestApis_601353; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601367 = newJObject()
  add(query_601367, "position", newJString(position))
  add(query_601367, "limit", newJInt(limit))
  result = call_601366.call(nil, query_601367, nil, nil, nil)

var getRestApis* = Call_GetRestApis_601353(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_601354,
                                        base: "/", url: url_GetRestApis_601355,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_601398 = ref object of OpenApiRestCall_600410
proc url_CreateStage_601400(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateStage_601399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601401 = path.getOrDefault("restapi_id")
  valid_601401 = validateParameter(valid_601401, JString, required = true,
                                 default = nil)
  if valid_601401 != nil:
    section.add "restapi_id", valid_601401
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
  var valid_601402 = header.getOrDefault("X-Amz-Date")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Date", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Security-Token")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Security-Token", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Content-Sha256", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Algorithm")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Algorithm", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Signature")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Signature", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-SignedHeaders", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Credential")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Credential", valid_601408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601410: Call_CreateStage_601398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_601410.validator(path, query, header, formData, body)
  let scheme = call_601410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601410.url(scheme.get, call_601410.host, call_601410.base,
                         call_601410.route, valid.getOrDefault("path"))
  result = hook(call_601410, url, valid)

proc call*(call_601411: Call_CreateStage_601398; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601412 = newJObject()
  var body_601413 = newJObject()
  if body != nil:
    body_601413 = body
  add(path_601412, "restapi_id", newJString(restapiId))
  result = call_601411.call(path_601412, nil, nil, nil, body_601413)

var createStage* = Call_CreateStage_601398(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_601399,
                                        base: "/", url: url_CreateStage_601400,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_601382 = ref object of OpenApiRestCall_600410
proc url_GetStages_601384(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStages_601383(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601385 = path.getOrDefault("restapi_id")
  valid_601385 = validateParameter(valid_601385, JString, required = true,
                                 default = nil)
  if valid_601385 != nil:
    section.add "restapi_id", valid_601385
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_601386 = query.getOrDefault("deploymentId")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "deploymentId", valid_601386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601387 = header.getOrDefault("X-Amz-Date")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Date", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Security-Token")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Security-Token", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Content-Sha256", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Algorithm")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Algorithm", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Signature")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Signature", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-SignedHeaders", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Credential")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Credential", valid_601393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_GetStages_601382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_GetStages_601382; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601396 = newJObject()
  var query_601397 = newJObject()
  add(query_601397, "deploymentId", newJString(deploymentId))
  add(path_601396, "restapi_id", newJString(restapiId))
  result = call_601395.call(path_601396, query_601397, nil, nil, nil)

var getStages* = Call_GetStages_601382(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_601383,
                                    base: "/", url: url_GetStages_601384,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_601430 = ref object of OpenApiRestCall_600410
proc url_CreateUsagePlan_601432(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUsagePlan_601431(path: JsonNode; query: JsonNode;
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
  var valid_601433 = header.getOrDefault("X-Amz-Date")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Date", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Security-Token")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Security-Token", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Content-Sha256", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Algorithm")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Algorithm", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Signature")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Signature", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-SignedHeaders", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Credential")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Credential", valid_601439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601441: Call_CreateUsagePlan_601430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_601441.validator(path, query, header, formData, body)
  let scheme = call_601441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601441.url(scheme.get, call_601441.host, call_601441.base,
                         call_601441.route, valid.getOrDefault("path"))
  result = hook(call_601441, url, valid)

proc call*(call_601442: Call_CreateUsagePlan_601430; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_601443 = newJObject()
  if body != nil:
    body_601443 = body
  result = call_601442.call(nil, nil, nil, nil, body_601443)

var createUsagePlan* = Call_CreateUsagePlan_601430(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_601431, base: "/",
    url: url_CreateUsagePlan_601432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_601414 = ref object of OpenApiRestCall_600410
proc url_GetUsagePlans_601416(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUsagePlans_601415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601417 = query.getOrDefault("keyId")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "keyId", valid_601417
  var valid_601418 = query.getOrDefault("position")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "position", valid_601418
  var valid_601419 = query.getOrDefault("limit")
  valid_601419 = validateParameter(valid_601419, JInt, required = false, default = nil)
  if valid_601419 != nil:
    section.add "limit", valid_601419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601420 = header.getOrDefault("X-Amz-Date")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Date", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Security-Token")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Security-Token", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Content-Sha256", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Algorithm")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Algorithm", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Signature")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Signature", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-SignedHeaders", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Credential")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Credential", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_GetUsagePlans_601414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"))
  result = hook(call_601427, url, valid)

proc call*(call_601428: Call_GetUsagePlans_601414; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601429 = newJObject()
  add(query_601429, "keyId", newJString(keyId))
  add(query_601429, "position", newJString(position))
  add(query_601429, "limit", newJInt(limit))
  result = call_601428.call(nil, query_601429, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_601414(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_601415, base: "/",
    url: url_GetUsagePlans_601416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_601462 = ref object of OpenApiRestCall_600410
proc url_CreateUsagePlanKey_601464(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateUsagePlanKey_601463(path: JsonNode; query: JsonNode;
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
  var valid_601465 = path.getOrDefault("usageplanId")
  valid_601465 = validateParameter(valid_601465, JString, required = true,
                                 default = nil)
  if valid_601465 != nil:
    section.add "usageplanId", valid_601465
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
  var valid_601466 = header.getOrDefault("X-Amz-Date")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Date", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Security-Token")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Security-Token", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Content-Sha256", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Algorithm")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Algorithm", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Signature")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Signature", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-SignedHeaders", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Credential")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Credential", valid_601472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601474: Call_CreateUsagePlanKey_601462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_601474.validator(path, query, header, formData, body)
  let scheme = call_601474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601474.url(scheme.get, call_601474.host, call_601474.base,
                         call_601474.route, valid.getOrDefault("path"))
  result = hook(call_601474, url, valid)

proc call*(call_601475: Call_CreateUsagePlanKey_601462; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_601476 = newJObject()
  var body_601477 = newJObject()
  add(path_601476, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_601477 = body
  result = call_601475.call(path_601476, nil, nil, nil, body_601477)

var createUsagePlanKey* = Call_CreateUsagePlanKey_601462(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_601463, base: "/",
    url: url_CreateUsagePlanKey_601464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_601444 = ref object of OpenApiRestCall_600410
proc url_GetUsagePlanKeys_601446(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUsagePlanKeys_601445(path: JsonNode; query: JsonNode;
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
  var valid_601447 = path.getOrDefault("usageplanId")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = nil)
  if valid_601447 != nil:
    section.add "usageplanId", valid_601447
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_601448 = query.getOrDefault("name")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "name", valid_601448
  var valid_601449 = query.getOrDefault("position")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "position", valid_601449
  var valid_601450 = query.getOrDefault("limit")
  valid_601450 = validateParameter(valid_601450, JInt, required = false, default = nil)
  if valid_601450 != nil:
    section.add "limit", valid_601450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601451 = header.getOrDefault("X-Amz-Date")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Date", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Security-Token")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Security-Token", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Content-Sha256", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Algorithm")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Algorithm", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Signature")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Signature", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-SignedHeaders", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Credential")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Credential", valid_601457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_GetUsagePlanKeys_601444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_GetUsagePlanKeys_601444; usageplanId: string;
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
  var path_601460 = newJObject()
  var query_601461 = newJObject()
  add(path_601460, "usageplanId", newJString(usageplanId))
  add(query_601461, "name", newJString(name))
  add(query_601461, "position", newJString(position))
  add(query_601461, "limit", newJInt(limit))
  result = call_601459.call(path_601460, query_601461, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_601444(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_601445,
    base: "/", url: url_GetUsagePlanKeys_601446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_601493 = ref object of OpenApiRestCall_600410
proc url_CreateVpcLink_601495(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVpcLink_601494(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601496 = header.getOrDefault("X-Amz-Date")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Date", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Security-Token")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Security-Token", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Content-Sha256", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Algorithm")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Algorithm", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Signature")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Signature", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-SignedHeaders", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Credential")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Credential", valid_601502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601504: Call_CreateVpcLink_601493; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_601504.validator(path, query, header, formData, body)
  let scheme = call_601504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601504.url(scheme.get, call_601504.host, call_601504.base,
                         call_601504.route, valid.getOrDefault("path"))
  result = hook(call_601504, url, valid)

proc call*(call_601505: Call_CreateVpcLink_601493; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_601506 = newJObject()
  if body != nil:
    body_601506 = body
  result = call_601505.call(nil, nil, nil, nil, body_601506)

var createVpcLink* = Call_CreateVpcLink_601493(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_601494, base: "/", url: url_CreateVpcLink_601495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_601478 = ref object of OpenApiRestCall_600410
proc url_GetVpcLinks_601480(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetVpcLinks_601479(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601481 = query.getOrDefault("position")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "position", valid_601481
  var valid_601482 = query.getOrDefault("limit")
  valid_601482 = validateParameter(valid_601482, JInt, required = false, default = nil)
  if valid_601482 != nil:
    section.add "limit", valid_601482
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601483 = header.getOrDefault("X-Amz-Date")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Date", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Security-Token")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Security-Token", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_GetVpcLinks_601478; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"))
  result = hook(call_601490, url, valid)

proc call*(call_601491: Call_GetVpcLinks_601478; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_601492 = newJObject()
  add(query_601492, "position", newJString(position))
  add(query_601492, "limit", newJInt(limit))
  result = call_601491.call(nil, query_601492, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_601478(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_601479,
                                        base: "/", url: url_GetVpcLinks_601480,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_601507 = ref object of OpenApiRestCall_600410
proc url_GetApiKey_601509(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetApiKey_601508(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601510 = path.getOrDefault("api_Key")
  valid_601510 = validateParameter(valid_601510, JString, required = true,
                                 default = nil)
  if valid_601510 != nil:
    section.add "api_Key", valid_601510
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_601511 = query.getOrDefault("includeValue")
  valid_601511 = validateParameter(valid_601511, JBool, required = false, default = nil)
  if valid_601511 != nil:
    section.add "includeValue", valid_601511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Content-Sha256", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Algorithm")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Algorithm", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Signature")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Signature", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-SignedHeaders", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Credential")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Credential", valid_601518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601519: Call_GetApiKey_601507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_601519.validator(path, query, header, formData, body)
  let scheme = call_601519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601519.url(scheme.get, call_601519.host, call_601519.base,
                         call_601519.route, valid.getOrDefault("path"))
  result = hook(call_601519, url, valid)

proc call*(call_601520: Call_GetApiKey_601507; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_601521 = newJObject()
  var query_601522 = newJObject()
  add(query_601522, "includeValue", newJBool(includeValue))
  add(path_601521, "api_Key", newJString(apiKey))
  result = call_601520.call(path_601521, query_601522, nil, nil, nil)

var getApiKey* = Call_GetApiKey_601507(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_601508,
                                    base: "/", url: url_GetApiKey_601509,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_601537 = ref object of OpenApiRestCall_600410
proc url_UpdateApiKey_601539(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApiKey_601538(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601540 = path.getOrDefault("api_Key")
  valid_601540 = validateParameter(valid_601540, JString, required = true,
                                 default = nil)
  if valid_601540 != nil:
    section.add "api_Key", valid_601540
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
  var valid_601541 = header.getOrDefault("X-Amz-Date")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Date", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Security-Token")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Security-Token", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Content-Sha256", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Algorithm")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Algorithm", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Signature")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Signature", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-SignedHeaders", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Credential")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Credential", valid_601547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601549: Call_UpdateApiKey_601537; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_601549.validator(path, query, header, formData, body)
  let scheme = call_601549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601549.url(scheme.get, call_601549.host, call_601549.base,
                         call_601549.route, valid.getOrDefault("path"))
  result = hook(call_601549, url, valid)

proc call*(call_601550: Call_UpdateApiKey_601537; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_601551 = newJObject()
  var body_601552 = newJObject()
  add(path_601551, "api_Key", newJString(apiKey))
  if body != nil:
    body_601552 = body
  result = call_601550.call(path_601551, nil, nil, nil, body_601552)

var updateApiKey* = Call_UpdateApiKey_601537(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_601538, base: "/",
    url: url_UpdateApiKey_601539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_601523 = ref object of OpenApiRestCall_600410
proc url_DeleteApiKey_601525(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "api_Key" in path, "`api_Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "api_Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApiKey_601524(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601526 = path.getOrDefault("api_Key")
  valid_601526 = validateParameter(valid_601526, JString, required = true,
                                 default = nil)
  if valid_601526 != nil:
    section.add "api_Key", valid_601526
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
  var valid_601527 = header.getOrDefault("X-Amz-Date")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Date", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Security-Token")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Security-Token", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Content-Sha256", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Algorithm")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Algorithm", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Signature")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Signature", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-SignedHeaders", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Credential")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Credential", valid_601533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601534: Call_DeleteApiKey_601523; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_601534.validator(path, query, header, formData, body)
  let scheme = call_601534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601534.url(scheme.get, call_601534.host, call_601534.base,
                         call_601534.route, valid.getOrDefault("path"))
  result = hook(call_601534, url, valid)

proc call*(call_601535: Call_DeleteApiKey_601523; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_601536 = newJObject()
  add(path_601536, "api_Key", newJString(apiKey))
  result = call_601535.call(path_601536, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_601523(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_601524, base: "/",
    url: url_DeleteApiKey_601525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_601568 = ref object of OpenApiRestCall_600410
proc url_TestInvokeAuthorizer_601570(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TestInvokeAuthorizer_601569(path: JsonNode; query: JsonNode;
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
  var valid_601571 = path.getOrDefault("authorizer_id")
  valid_601571 = validateParameter(valid_601571, JString, required = true,
                                 default = nil)
  if valid_601571 != nil:
    section.add "authorizer_id", valid_601571
  var valid_601572 = path.getOrDefault("restapi_id")
  valid_601572 = validateParameter(valid_601572, JString, required = true,
                                 default = nil)
  if valid_601572 != nil:
    section.add "restapi_id", valid_601572
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
  var valid_601573 = header.getOrDefault("X-Amz-Date")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Date", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Security-Token")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Security-Token", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Content-Sha256", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Algorithm")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Algorithm", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Signature")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Signature", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-SignedHeaders", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Credential")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Credential", valid_601579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601581: Call_TestInvokeAuthorizer_601568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_601581.validator(path, query, header, formData, body)
  let scheme = call_601581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601581.url(scheme.get, call_601581.host, call_601581.base,
                         call_601581.route, valid.getOrDefault("path"))
  result = hook(call_601581, url, valid)

proc call*(call_601582: Call_TestInvokeAuthorizer_601568; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601583 = newJObject()
  var body_601584 = newJObject()
  add(path_601583, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_601584 = body
  add(path_601583, "restapi_id", newJString(restapiId))
  result = call_601582.call(path_601583, nil, nil, nil, body_601584)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_601568(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_601569, base: "/",
    url: url_TestInvokeAuthorizer_601570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_601553 = ref object of OpenApiRestCall_600410
proc url_GetAuthorizer_601555(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAuthorizer_601554(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601556 = path.getOrDefault("authorizer_id")
  valid_601556 = validateParameter(valid_601556, JString, required = true,
                                 default = nil)
  if valid_601556 != nil:
    section.add "authorizer_id", valid_601556
  var valid_601557 = path.getOrDefault("restapi_id")
  valid_601557 = validateParameter(valid_601557, JString, required = true,
                                 default = nil)
  if valid_601557 != nil:
    section.add "restapi_id", valid_601557
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
  var valid_601558 = header.getOrDefault("X-Amz-Date")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Date", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Security-Token")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Security-Token", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Content-Sha256", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Algorithm")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Algorithm", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Signature")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Signature", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-SignedHeaders", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Credential")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Credential", valid_601564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601565: Call_GetAuthorizer_601553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_601565.validator(path, query, header, formData, body)
  let scheme = call_601565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601565.url(scheme.get, call_601565.host, call_601565.base,
                         call_601565.route, valid.getOrDefault("path"))
  result = hook(call_601565, url, valid)

proc call*(call_601566: Call_GetAuthorizer_601553; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601567 = newJObject()
  add(path_601567, "authorizer_id", newJString(authorizerId))
  add(path_601567, "restapi_id", newJString(restapiId))
  result = call_601566.call(path_601567, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_601553(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_601554, base: "/", url: url_GetAuthorizer_601555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_601600 = ref object of OpenApiRestCall_600410
proc url_UpdateAuthorizer_601602(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateAuthorizer_601601(path: JsonNode; query: JsonNode;
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
  var valid_601603 = path.getOrDefault("authorizer_id")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = nil)
  if valid_601603 != nil:
    section.add "authorizer_id", valid_601603
  var valid_601604 = path.getOrDefault("restapi_id")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "restapi_id", valid_601604
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
  var valid_601605 = header.getOrDefault("X-Amz-Date")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Date", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Security-Token")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Security-Token", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Content-Sha256", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Algorithm")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Algorithm", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Signature")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Signature", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-SignedHeaders", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Credential")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Credential", valid_601611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601613: Call_UpdateAuthorizer_601600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_601613.validator(path, query, header, formData, body)
  let scheme = call_601613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601613.url(scheme.get, call_601613.host, call_601613.base,
                         call_601613.route, valid.getOrDefault("path"))
  result = hook(call_601613, url, valid)

proc call*(call_601614: Call_UpdateAuthorizer_601600; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601615 = newJObject()
  var body_601616 = newJObject()
  add(path_601615, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_601616 = body
  add(path_601615, "restapi_id", newJString(restapiId))
  result = call_601614.call(path_601615, nil, nil, nil, body_601616)

var updateAuthorizer* = Call_UpdateAuthorizer_601600(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_601601, base: "/",
    url: url_UpdateAuthorizer_601602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_601585 = ref object of OpenApiRestCall_600410
proc url_DeleteAuthorizer_601587(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteAuthorizer_601586(path: JsonNode; query: JsonNode;
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
  var valid_601588 = path.getOrDefault("authorizer_id")
  valid_601588 = validateParameter(valid_601588, JString, required = true,
                                 default = nil)
  if valid_601588 != nil:
    section.add "authorizer_id", valid_601588
  var valid_601589 = path.getOrDefault("restapi_id")
  valid_601589 = validateParameter(valid_601589, JString, required = true,
                                 default = nil)
  if valid_601589 != nil:
    section.add "restapi_id", valid_601589
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
  var valid_601590 = header.getOrDefault("X-Amz-Date")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Date", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Security-Token")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Security-Token", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Content-Sha256", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Algorithm")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Algorithm", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Signature")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Signature", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-SignedHeaders", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Credential")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Credential", valid_601596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601597: Call_DeleteAuthorizer_601585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_601597.validator(path, query, header, formData, body)
  let scheme = call_601597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601597.url(scheme.get, call_601597.host, call_601597.base,
                         call_601597.route, valid.getOrDefault("path"))
  result = hook(call_601597, url, valid)

proc call*(call_601598: Call_DeleteAuthorizer_601585; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601599 = newJObject()
  add(path_601599, "authorizer_id", newJString(authorizerId))
  add(path_601599, "restapi_id", newJString(restapiId))
  result = call_601598.call(path_601599, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_601585(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_601586, base: "/",
    url: url_DeleteAuthorizer_601587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_601617 = ref object of OpenApiRestCall_600410
proc url_GetBasePathMapping_601619(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBasePathMapping_601618(path: JsonNode; query: JsonNode;
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
  var valid_601620 = path.getOrDefault("base_path")
  valid_601620 = validateParameter(valid_601620, JString, required = true,
                                 default = nil)
  if valid_601620 != nil:
    section.add "base_path", valid_601620
  var valid_601621 = path.getOrDefault("domain_name")
  valid_601621 = validateParameter(valid_601621, JString, required = true,
                                 default = nil)
  if valid_601621 != nil:
    section.add "domain_name", valid_601621
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
  var valid_601622 = header.getOrDefault("X-Amz-Date")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Date", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Security-Token")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Security-Token", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Content-Sha256", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Algorithm")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Algorithm", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Signature")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Signature", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-SignedHeaders", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Credential")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Credential", valid_601628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601629: Call_GetBasePathMapping_601617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_601629.validator(path, query, header, formData, body)
  let scheme = call_601629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601629.url(scheme.get, call_601629.host, call_601629.base,
                         call_601629.route, valid.getOrDefault("path"))
  result = hook(call_601629, url, valid)

proc call*(call_601630: Call_GetBasePathMapping_601617; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_601631 = newJObject()
  add(path_601631, "base_path", newJString(basePath))
  add(path_601631, "domain_name", newJString(domainName))
  result = call_601630.call(path_601631, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_601617(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_601618, base: "/",
    url: url_GetBasePathMapping_601619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_601647 = ref object of OpenApiRestCall_600410
proc url_UpdateBasePathMapping_601649(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateBasePathMapping_601648(path: JsonNode; query: JsonNode;
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
  var valid_601650 = path.getOrDefault("base_path")
  valid_601650 = validateParameter(valid_601650, JString, required = true,
                                 default = nil)
  if valid_601650 != nil:
    section.add "base_path", valid_601650
  var valid_601651 = path.getOrDefault("domain_name")
  valid_601651 = validateParameter(valid_601651, JString, required = true,
                                 default = nil)
  if valid_601651 != nil:
    section.add "domain_name", valid_601651
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
  var valid_601652 = header.getOrDefault("X-Amz-Date")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Date", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Security-Token")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Security-Token", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Algorithm")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Algorithm", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Signature")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Signature", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-SignedHeaders", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Credential")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Credential", valid_601658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601660: Call_UpdateBasePathMapping_601647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_601660.validator(path, query, header, formData, body)
  let scheme = call_601660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601660.url(scheme.get, call_601660.host, call_601660.base,
                         call_601660.route, valid.getOrDefault("path"))
  result = hook(call_601660, url, valid)

proc call*(call_601661: Call_UpdateBasePathMapping_601647; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_601662 = newJObject()
  var body_601663 = newJObject()
  add(path_601662, "base_path", newJString(basePath))
  add(path_601662, "domain_name", newJString(domainName))
  if body != nil:
    body_601663 = body
  result = call_601661.call(path_601662, nil, nil, nil, body_601663)

var updateBasePathMapping* = Call_UpdateBasePathMapping_601647(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_601648, base: "/",
    url: url_UpdateBasePathMapping_601649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_601632 = ref object of OpenApiRestCall_600410
proc url_DeleteBasePathMapping_601634(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBasePathMapping_601633(path: JsonNode; query: JsonNode;
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
  var valid_601635 = path.getOrDefault("base_path")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = nil)
  if valid_601635 != nil:
    section.add "base_path", valid_601635
  var valid_601636 = path.getOrDefault("domain_name")
  valid_601636 = validateParameter(valid_601636, JString, required = true,
                                 default = nil)
  if valid_601636 != nil:
    section.add "domain_name", valid_601636
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
  var valid_601637 = header.getOrDefault("X-Amz-Date")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Date", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Security-Token")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Security-Token", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Content-Sha256", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Algorithm")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Algorithm", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Signature")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Signature", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-SignedHeaders", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Credential")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Credential", valid_601643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601644: Call_DeleteBasePathMapping_601632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_601644.validator(path, query, header, formData, body)
  let scheme = call_601644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601644.url(scheme.get, call_601644.host, call_601644.base,
                         call_601644.route, valid.getOrDefault("path"))
  result = hook(call_601644, url, valid)

proc call*(call_601645: Call_DeleteBasePathMapping_601632; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_601646 = newJObject()
  add(path_601646, "base_path", newJString(basePath))
  add(path_601646, "domain_name", newJString(domainName))
  result = call_601645.call(path_601646, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_601632(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_601633, base: "/",
    url: url_DeleteBasePathMapping_601634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_601664 = ref object of OpenApiRestCall_600410
proc url_GetClientCertificate_601666(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetClientCertificate_601665(path: JsonNode; query: JsonNode;
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
  var valid_601667 = path.getOrDefault("clientcertificate_id")
  valid_601667 = validateParameter(valid_601667, JString, required = true,
                                 default = nil)
  if valid_601667 != nil:
    section.add "clientcertificate_id", valid_601667
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
  var valid_601668 = header.getOrDefault("X-Amz-Date")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Date", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Security-Token")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Security-Token", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Content-Sha256", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Algorithm")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Algorithm", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Signature")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Signature", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-SignedHeaders", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Credential")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Credential", valid_601674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601675: Call_GetClientCertificate_601664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_601675.validator(path, query, header, formData, body)
  let scheme = call_601675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601675.url(scheme.get, call_601675.host, call_601675.base,
                         call_601675.route, valid.getOrDefault("path"))
  result = hook(call_601675, url, valid)

proc call*(call_601676: Call_GetClientCertificate_601664;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_601677 = newJObject()
  add(path_601677, "clientcertificate_id", newJString(clientcertificateId))
  result = call_601676.call(path_601677, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_601664(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_601665, base: "/",
    url: url_GetClientCertificate_601666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_601692 = ref object of OpenApiRestCall_600410
proc url_UpdateClientCertificate_601694(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateClientCertificate_601693(path: JsonNode; query: JsonNode;
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
  var valid_601695 = path.getOrDefault("clientcertificate_id")
  valid_601695 = validateParameter(valid_601695, JString, required = true,
                                 default = nil)
  if valid_601695 != nil:
    section.add "clientcertificate_id", valid_601695
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
  var valid_601696 = header.getOrDefault("X-Amz-Date")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Date", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Security-Token")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Security-Token", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Content-Sha256", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Algorithm")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Algorithm", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Signature")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Signature", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-SignedHeaders", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Credential")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Credential", valid_601702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601704: Call_UpdateClientCertificate_601692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_601704.validator(path, query, header, formData, body)
  let scheme = call_601704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601704.url(scheme.get, call_601704.host, call_601704.base,
                         call_601704.route, valid.getOrDefault("path"))
  result = hook(call_601704, url, valid)

proc call*(call_601705: Call_UpdateClientCertificate_601692;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_601706 = newJObject()
  var body_601707 = newJObject()
  add(path_601706, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_601707 = body
  result = call_601705.call(path_601706, nil, nil, nil, body_601707)

var updateClientCertificate* = Call_UpdateClientCertificate_601692(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_601693, base: "/",
    url: url_UpdateClientCertificate_601694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_601678 = ref object of OpenApiRestCall_600410
proc url_DeleteClientCertificate_601680(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteClientCertificate_601679(path: JsonNode; query: JsonNode;
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
  var valid_601681 = path.getOrDefault("clientcertificate_id")
  valid_601681 = validateParameter(valid_601681, JString, required = true,
                                 default = nil)
  if valid_601681 != nil:
    section.add "clientcertificate_id", valid_601681
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
  var valid_601682 = header.getOrDefault("X-Amz-Date")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Date", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Security-Token")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Security-Token", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Content-Sha256", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Algorithm")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Algorithm", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Signature")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Signature", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-SignedHeaders", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Credential")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Credential", valid_601688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601689: Call_DeleteClientCertificate_601678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_601689.validator(path, query, header, formData, body)
  let scheme = call_601689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601689.url(scheme.get, call_601689.host, call_601689.base,
                         call_601689.route, valid.getOrDefault("path"))
  result = hook(call_601689, url, valid)

proc call*(call_601690: Call_DeleteClientCertificate_601678;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_601691 = newJObject()
  add(path_601691, "clientcertificate_id", newJString(clientcertificateId))
  result = call_601690.call(path_601691, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_601678(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_601679, base: "/",
    url: url_DeleteClientCertificate_601680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_601708 = ref object of OpenApiRestCall_600410
proc url_GetDeployment_601710(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeployment_601709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601711 = path.getOrDefault("deployment_id")
  valid_601711 = validateParameter(valid_601711, JString, required = true,
                                 default = nil)
  if valid_601711 != nil:
    section.add "deployment_id", valid_601711
  var valid_601712 = path.getOrDefault("restapi_id")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = nil)
  if valid_601712 != nil:
    section.add "restapi_id", valid_601712
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_601713 = query.getOrDefault("embed")
  valid_601713 = validateParameter(valid_601713, JArray, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "embed", valid_601713
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601714 = header.getOrDefault("X-Amz-Date")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Date", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Security-Token")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Security-Token", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Content-Sha256", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Algorithm")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Algorithm", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Signature")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Signature", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-SignedHeaders", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Credential")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Credential", valid_601720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601721: Call_GetDeployment_601708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_601721.validator(path, query, header, formData, body)
  let scheme = call_601721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601721.url(scheme.get, call_601721.host, call_601721.base,
                         call_601721.route, valid.getOrDefault("path"))
  result = hook(call_601721, url, valid)

proc call*(call_601722: Call_GetDeployment_601708; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601723 = newJObject()
  var query_601724 = newJObject()
  add(path_601723, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_601724.add "embed", embed
  add(path_601723, "restapi_id", newJString(restapiId))
  result = call_601722.call(path_601723, query_601724, nil, nil, nil)

var getDeployment* = Call_GetDeployment_601708(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_601709, base: "/", url: url_GetDeployment_601710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_601740 = ref object of OpenApiRestCall_600410
proc url_UpdateDeployment_601742(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDeployment_601741(path: JsonNode; query: JsonNode;
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
  var valid_601743 = path.getOrDefault("deployment_id")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = nil)
  if valid_601743 != nil:
    section.add "deployment_id", valid_601743
  var valid_601744 = path.getOrDefault("restapi_id")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = nil)
  if valid_601744 != nil:
    section.add "restapi_id", valid_601744
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
  var valid_601745 = header.getOrDefault("X-Amz-Date")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Date", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Security-Token")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Security-Token", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Content-Sha256", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Algorithm")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Algorithm", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Signature")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Signature", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-SignedHeaders", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Credential")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Credential", valid_601751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601753: Call_UpdateDeployment_601740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_601753.validator(path, query, header, formData, body)
  let scheme = call_601753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601753.url(scheme.get, call_601753.host, call_601753.base,
                         call_601753.route, valid.getOrDefault("path"))
  result = hook(call_601753, url, valid)

proc call*(call_601754: Call_UpdateDeployment_601740; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601755 = newJObject()
  var body_601756 = newJObject()
  add(path_601755, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_601756 = body
  add(path_601755, "restapi_id", newJString(restapiId))
  result = call_601754.call(path_601755, nil, nil, nil, body_601756)

var updateDeployment* = Call_UpdateDeployment_601740(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_601741, base: "/",
    url: url_UpdateDeployment_601742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_601725 = ref object of OpenApiRestCall_600410
proc url_DeleteDeployment_601727(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDeployment_601726(path: JsonNode; query: JsonNode;
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
  var valid_601728 = path.getOrDefault("deployment_id")
  valid_601728 = validateParameter(valid_601728, JString, required = true,
                                 default = nil)
  if valid_601728 != nil:
    section.add "deployment_id", valid_601728
  var valid_601729 = path.getOrDefault("restapi_id")
  valid_601729 = validateParameter(valid_601729, JString, required = true,
                                 default = nil)
  if valid_601729 != nil:
    section.add "restapi_id", valid_601729
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
  var valid_601730 = header.getOrDefault("X-Amz-Date")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Date", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Security-Token")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Security-Token", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Content-Sha256", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Algorithm")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Algorithm", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Signature")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Signature", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-SignedHeaders", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Credential")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Credential", valid_601736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601737: Call_DeleteDeployment_601725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_601737.validator(path, query, header, formData, body)
  let scheme = call_601737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601737.url(scheme.get, call_601737.host, call_601737.base,
                         call_601737.route, valid.getOrDefault("path"))
  result = hook(call_601737, url, valid)

proc call*(call_601738: Call_DeleteDeployment_601725; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601739 = newJObject()
  add(path_601739, "deployment_id", newJString(deploymentId))
  add(path_601739, "restapi_id", newJString(restapiId))
  result = call_601738.call(path_601739, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_601725(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_601726, base: "/",
    url: url_DeleteDeployment_601727, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_601757 = ref object of OpenApiRestCall_600410
proc url_GetDocumentationPart_601759(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentationPart_601758(path: JsonNode; query: JsonNode;
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
  var valid_601760 = path.getOrDefault("part_id")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = nil)
  if valid_601760 != nil:
    section.add "part_id", valid_601760
  var valid_601761 = path.getOrDefault("restapi_id")
  valid_601761 = validateParameter(valid_601761, JString, required = true,
                                 default = nil)
  if valid_601761 != nil:
    section.add "restapi_id", valid_601761
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
  var valid_601762 = header.getOrDefault("X-Amz-Date")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Date", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Security-Token")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Security-Token", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Content-Sha256", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Algorithm")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Algorithm", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Signature")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Signature", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-SignedHeaders", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Credential")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Credential", valid_601768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601769: Call_GetDocumentationPart_601757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601769.validator(path, query, header, formData, body)
  let scheme = call_601769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601769.url(scheme.get, call_601769.host, call_601769.base,
                         call_601769.route, valid.getOrDefault("path"))
  result = hook(call_601769, url, valid)

proc call*(call_601770: Call_GetDocumentationPart_601757; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601771 = newJObject()
  add(path_601771, "part_id", newJString(partId))
  add(path_601771, "restapi_id", newJString(restapiId))
  result = call_601770.call(path_601771, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_601757(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_601758, base: "/",
    url: url_GetDocumentationPart_601759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_601787 = ref object of OpenApiRestCall_600410
proc url_UpdateDocumentationPart_601789(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDocumentationPart_601788(path: JsonNode; query: JsonNode;
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
  var valid_601790 = path.getOrDefault("part_id")
  valid_601790 = validateParameter(valid_601790, JString, required = true,
                                 default = nil)
  if valid_601790 != nil:
    section.add "part_id", valid_601790
  var valid_601791 = path.getOrDefault("restapi_id")
  valid_601791 = validateParameter(valid_601791, JString, required = true,
                                 default = nil)
  if valid_601791 != nil:
    section.add "restapi_id", valid_601791
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
  var valid_601792 = header.getOrDefault("X-Amz-Date")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Date", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Security-Token")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Security-Token", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Content-Sha256", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Algorithm")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Algorithm", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Signature")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Signature", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-SignedHeaders", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Credential")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Credential", valid_601798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601800: Call_UpdateDocumentationPart_601787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601800.validator(path, query, header, formData, body)
  let scheme = call_601800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601800.url(scheme.get, call_601800.host, call_601800.base,
                         call_601800.route, valid.getOrDefault("path"))
  result = hook(call_601800, url, valid)

proc call*(call_601801: Call_UpdateDocumentationPart_601787; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601802 = newJObject()
  var body_601803 = newJObject()
  if body != nil:
    body_601803 = body
  add(path_601802, "part_id", newJString(partId))
  add(path_601802, "restapi_id", newJString(restapiId))
  result = call_601801.call(path_601802, nil, nil, nil, body_601803)

var updateDocumentationPart* = Call_UpdateDocumentationPart_601787(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_601788, base: "/",
    url: url_UpdateDocumentationPart_601789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_601772 = ref object of OpenApiRestCall_600410
proc url_DeleteDocumentationPart_601774(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDocumentationPart_601773(path: JsonNode; query: JsonNode;
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
  var valid_601775 = path.getOrDefault("part_id")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = nil)
  if valid_601775 != nil:
    section.add "part_id", valid_601775
  var valid_601776 = path.getOrDefault("restapi_id")
  valid_601776 = validateParameter(valid_601776, JString, required = true,
                                 default = nil)
  if valid_601776 != nil:
    section.add "restapi_id", valid_601776
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
  var valid_601777 = header.getOrDefault("X-Amz-Date")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Date", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Security-Token")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Security-Token", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Content-Sha256", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Algorithm")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Algorithm", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Signature")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Signature", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-SignedHeaders", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Credential")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Credential", valid_601783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601784: Call_DeleteDocumentationPart_601772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601784.validator(path, query, header, formData, body)
  let scheme = call_601784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601784.url(scheme.get, call_601784.host, call_601784.base,
                         call_601784.route, valid.getOrDefault("path"))
  result = hook(call_601784, url, valid)

proc call*(call_601785: Call_DeleteDocumentationPart_601772; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601786 = newJObject()
  add(path_601786, "part_id", newJString(partId))
  add(path_601786, "restapi_id", newJString(restapiId))
  result = call_601785.call(path_601786, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_601772(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_601773, base: "/",
    url: url_DeleteDocumentationPart_601774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_601804 = ref object of OpenApiRestCall_600410
proc url_GetDocumentationVersion_601806(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentationVersion_601805(path: JsonNode; query: JsonNode;
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
  var valid_601807 = path.getOrDefault("doc_version")
  valid_601807 = validateParameter(valid_601807, JString, required = true,
                                 default = nil)
  if valid_601807 != nil:
    section.add "doc_version", valid_601807
  var valid_601808 = path.getOrDefault("restapi_id")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = nil)
  if valid_601808 != nil:
    section.add "restapi_id", valid_601808
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
  var valid_601809 = header.getOrDefault("X-Amz-Date")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Date", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Security-Token")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Security-Token", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Content-Sha256", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Algorithm")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Algorithm", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Signature")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Signature", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-SignedHeaders", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Credential")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Credential", valid_601815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601816: Call_GetDocumentationVersion_601804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601816.validator(path, query, header, formData, body)
  let scheme = call_601816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601816.url(scheme.get, call_601816.host, call_601816.base,
                         call_601816.route, valid.getOrDefault("path"))
  result = hook(call_601816, url, valid)

proc call*(call_601817: Call_GetDocumentationVersion_601804; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601818 = newJObject()
  add(path_601818, "doc_version", newJString(docVersion))
  add(path_601818, "restapi_id", newJString(restapiId))
  result = call_601817.call(path_601818, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_601804(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_601805, base: "/",
    url: url_GetDocumentationVersion_601806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_601834 = ref object of OpenApiRestCall_600410
proc url_UpdateDocumentationVersion_601836(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDocumentationVersion_601835(path: JsonNode; query: JsonNode;
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
  var valid_601837 = path.getOrDefault("doc_version")
  valid_601837 = validateParameter(valid_601837, JString, required = true,
                                 default = nil)
  if valid_601837 != nil:
    section.add "doc_version", valid_601837
  var valid_601838 = path.getOrDefault("restapi_id")
  valid_601838 = validateParameter(valid_601838, JString, required = true,
                                 default = nil)
  if valid_601838 != nil:
    section.add "restapi_id", valid_601838
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
  var valid_601839 = header.getOrDefault("X-Amz-Date")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Date", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Security-Token")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Security-Token", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Content-Sha256", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Algorithm")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Algorithm", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-SignedHeaders", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601847: Call_UpdateDocumentationVersion_601834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601847.validator(path, query, header, formData, body)
  let scheme = call_601847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601847.url(scheme.get, call_601847.host, call_601847.base,
                         call_601847.route, valid.getOrDefault("path"))
  result = hook(call_601847, url, valid)

proc call*(call_601848: Call_UpdateDocumentationVersion_601834; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_601849 = newJObject()
  var body_601850 = newJObject()
  add(path_601849, "doc_version", newJString(docVersion))
  if body != nil:
    body_601850 = body
  add(path_601849, "restapi_id", newJString(restapiId))
  result = call_601848.call(path_601849, nil, nil, nil, body_601850)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_601834(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_601835, base: "/",
    url: url_UpdateDocumentationVersion_601836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_601819 = ref object of OpenApiRestCall_600410
proc url_DeleteDocumentationVersion_601821(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDocumentationVersion_601820(path: JsonNode; query: JsonNode;
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
  var valid_601822 = path.getOrDefault("doc_version")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = nil)
  if valid_601822 != nil:
    section.add "doc_version", valid_601822
  var valid_601823 = path.getOrDefault("restapi_id")
  valid_601823 = validateParameter(valid_601823, JString, required = true,
                                 default = nil)
  if valid_601823 != nil:
    section.add "restapi_id", valid_601823
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
  var valid_601824 = header.getOrDefault("X-Amz-Date")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Date", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Security-Token")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Security-Token", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Content-Sha256", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Algorithm")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Algorithm", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Signature")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Signature", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-SignedHeaders", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Credential")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Credential", valid_601830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601831: Call_DeleteDocumentationVersion_601819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601831.validator(path, query, header, formData, body)
  let scheme = call_601831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601831.url(scheme.get, call_601831.host, call_601831.base,
                         call_601831.route, valid.getOrDefault("path"))
  result = hook(call_601831, url, valid)

proc call*(call_601832: Call_DeleteDocumentationVersion_601819; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_601833 = newJObject()
  add(path_601833, "doc_version", newJString(docVersion))
  add(path_601833, "restapi_id", newJString(restapiId))
  result = call_601832.call(path_601833, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_601819(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_601820, base: "/",
    url: url_DeleteDocumentationVersion_601821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_601851 = ref object of OpenApiRestCall_600410
proc url_GetDomainName_601853(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDomainName_601852(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601854 = path.getOrDefault("domain_name")
  valid_601854 = validateParameter(valid_601854, JString, required = true,
                                 default = nil)
  if valid_601854 != nil:
    section.add "domain_name", valid_601854
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
  var valid_601855 = header.getOrDefault("X-Amz-Date")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Date", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Security-Token")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Security-Token", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Algorithm")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Algorithm", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Signature")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Signature", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-SignedHeaders", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601862: Call_GetDomainName_601851; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_601862.validator(path, query, header, formData, body)
  let scheme = call_601862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601862.url(scheme.get, call_601862.host, call_601862.base,
                         call_601862.route, valid.getOrDefault("path"))
  result = hook(call_601862, url, valid)

proc call*(call_601863: Call_GetDomainName_601851; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_601864 = newJObject()
  add(path_601864, "domain_name", newJString(domainName))
  result = call_601863.call(path_601864, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_601851(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_601852,
    base: "/", url: url_GetDomainName_601853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_601879 = ref object of OpenApiRestCall_600410
proc url_UpdateDomainName_601881(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDomainName_601880(path: JsonNode; query: JsonNode;
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
  var valid_601882 = path.getOrDefault("domain_name")
  valid_601882 = validateParameter(valid_601882, JString, required = true,
                                 default = nil)
  if valid_601882 != nil:
    section.add "domain_name", valid_601882
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601891: Call_UpdateDomainName_601879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_601891.validator(path, query, header, formData, body)
  let scheme = call_601891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601891.url(scheme.get, call_601891.host, call_601891.base,
                         call_601891.route, valid.getOrDefault("path"))
  result = hook(call_601891, url, valid)

proc call*(call_601892: Call_UpdateDomainName_601879; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_601893 = newJObject()
  var body_601894 = newJObject()
  add(path_601893, "domain_name", newJString(domainName))
  if body != nil:
    body_601894 = body
  result = call_601892.call(path_601893, nil, nil, nil, body_601894)

var updateDomainName* = Call_UpdateDomainName_601879(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_601880,
    base: "/", url: url_UpdateDomainName_601881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_601865 = ref object of OpenApiRestCall_600410
proc url_DeleteDomainName_601867(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "domain_name" in path, "`domain_name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/domainnames/"),
               (kind: VariableSegment, value: "domain_name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDomainName_601866(path: JsonNode; query: JsonNode;
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
  var valid_601868 = path.getOrDefault("domain_name")
  valid_601868 = validateParameter(valid_601868, JString, required = true,
                                 default = nil)
  if valid_601868 != nil:
    section.add "domain_name", valid_601868
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
  var valid_601869 = header.getOrDefault("X-Amz-Date")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Date", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Security-Token")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Security-Token", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Content-Sha256", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Algorithm")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Algorithm", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Signature")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Signature", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-SignedHeaders", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Credential")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Credential", valid_601875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_DeleteDomainName_601865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"))
  result = hook(call_601876, url, valid)

proc call*(call_601877: Call_DeleteDomainName_601865; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_601878 = newJObject()
  add(path_601878, "domain_name", newJString(domainName))
  result = call_601877.call(path_601878, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_601865(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_601866,
    base: "/", url: url_DeleteDomainName_601867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_601910 = ref object of OpenApiRestCall_600410
proc url_PutGatewayResponse_601912(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutGatewayResponse_601911(path: JsonNode; query: JsonNode;
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
  var valid_601913 = path.getOrDefault("response_type")
  valid_601913 = validateParameter(valid_601913, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_601913 != nil:
    section.add "response_type", valid_601913
  var valid_601914 = path.getOrDefault("restapi_id")
  valid_601914 = validateParameter(valid_601914, JString, required = true,
                                 default = nil)
  if valid_601914 != nil:
    section.add "restapi_id", valid_601914
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
  var valid_601915 = header.getOrDefault("X-Amz-Date")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Date", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Security-Token")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Security-Token", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Content-Sha256", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-Algorithm")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-Algorithm", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Signature")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Signature", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-SignedHeaders", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Credential")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Credential", valid_601921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601923: Call_PutGatewayResponse_601910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_601923.validator(path, query, header, formData, body)
  let scheme = call_601923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601923.url(scheme.get, call_601923.host, call_601923.base,
                         call_601923.route, valid.getOrDefault("path"))
  result = hook(call_601923, url, valid)

proc call*(call_601924: Call_PutGatewayResponse_601910; body: JsonNode;
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
  var path_601925 = newJObject()
  var body_601926 = newJObject()
  add(path_601925, "response_type", newJString(responseType))
  if body != nil:
    body_601926 = body
  add(path_601925, "restapi_id", newJString(restapiId))
  result = call_601924.call(path_601925, nil, nil, nil, body_601926)

var putGatewayResponse* = Call_PutGatewayResponse_601910(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_601911, base: "/",
    url: url_PutGatewayResponse_601912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_601895 = ref object of OpenApiRestCall_600410
proc url_GetGatewayResponse_601897(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGatewayResponse_601896(path: JsonNode; query: JsonNode;
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
  var valid_601898 = path.getOrDefault("response_type")
  valid_601898 = validateParameter(valid_601898, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_601898 != nil:
    section.add "response_type", valid_601898
  var valid_601899 = path.getOrDefault("restapi_id")
  valid_601899 = validateParameter(valid_601899, JString, required = true,
                                 default = nil)
  if valid_601899 != nil:
    section.add "restapi_id", valid_601899
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
  var valid_601900 = header.getOrDefault("X-Amz-Date")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Date", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Security-Token")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Security-Token", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Content-Sha256", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Algorithm")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Algorithm", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Signature")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Signature", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-SignedHeaders", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Credential")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Credential", valid_601906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601907: Call_GetGatewayResponse_601895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_601907.validator(path, query, header, formData, body)
  let scheme = call_601907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601907.url(scheme.get, call_601907.host, call_601907.base,
                         call_601907.route, valid.getOrDefault("path"))
  result = hook(call_601907, url, valid)

proc call*(call_601908: Call_GetGatewayResponse_601895; restapiId: string;
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
  var path_601909 = newJObject()
  add(path_601909, "response_type", newJString(responseType))
  add(path_601909, "restapi_id", newJString(restapiId))
  result = call_601908.call(path_601909, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_601895(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_601896, base: "/",
    url: url_GetGatewayResponse_601897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_601942 = ref object of OpenApiRestCall_600410
proc url_UpdateGatewayResponse_601944(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGatewayResponse_601943(path: JsonNode; query: JsonNode;
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
  var valid_601945 = path.getOrDefault("response_type")
  valid_601945 = validateParameter(valid_601945, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_601945 != nil:
    section.add "response_type", valid_601945
  var valid_601946 = path.getOrDefault("restapi_id")
  valid_601946 = validateParameter(valid_601946, JString, required = true,
                                 default = nil)
  if valid_601946 != nil:
    section.add "restapi_id", valid_601946
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
  var valid_601947 = header.getOrDefault("X-Amz-Date")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Date", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Security-Token")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Security-Token", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Content-Sha256", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Algorithm")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Algorithm", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Signature")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Signature", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-SignedHeaders", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Credential")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Credential", valid_601953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601955: Call_UpdateGatewayResponse_601942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_601955.validator(path, query, header, formData, body)
  let scheme = call_601955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601955.url(scheme.get, call_601955.host, call_601955.base,
                         call_601955.route, valid.getOrDefault("path"))
  result = hook(call_601955, url, valid)

proc call*(call_601956: Call_UpdateGatewayResponse_601942; body: JsonNode;
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
  var path_601957 = newJObject()
  var body_601958 = newJObject()
  add(path_601957, "response_type", newJString(responseType))
  if body != nil:
    body_601958 = body
  add(path_601957, "restapi_id", newJString(restapiId))
  result = call_601956.call(path_601957, nil, nil, nil, body_601958)

var updateGatewayResponse* = Call_UpdateGatewayResponse_601942(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_601943, base: "/",
    url: url_UpdateGatewayResponse_601944, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_601927 = ref object of OpenApiRestCall_600410
proc url_DeleteGatewayResponse_601929(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteGatewayResponse_601928(path: JsonNode; query: JsonNode;
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
  var valid_601930 = path.getOrDefault("response_type")
  valid_601930 = validateParameter(valid_601930, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_601930 != nil:
    section.add "response_type", valid_601930
  var valid_601931 = path.getOrDefault("restapi_id")
  valid_601931 = validateParameter(valid_601931, JString, required = true,
                                 default = nil)
  if valid_601931 != nil:
    section.add "restapi_id", valid_601931
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
  var valid_601932 = header.getOrDefault("X-Amz-Date")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Date", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-Security-Token")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Security-Token", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Content-Sha256", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Algorithm")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Algorithm", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Signature")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Signature", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-SignedHeaders", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Credential")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Credential", valid_601938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601939: Call_DeleteGatewayResponse_601927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_601939.validator(path, query, header, formData, body)
  let scheme = call_601939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601939.url(scheme.get, call_601939.host, call_601939.base,
                         call_601939.route, valid.getOrDefault("path"))
  result = hook(call_601939, url, valid)

proc call*(call_601940: Call_DeleteGatewayResponse_601927; restapiId: string;
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
  var path_601941 = newJObject()
  add(path_601941, "response_type", newJString(responseType))
  add(path_601941, "restapi_id", newJString(restapiId))
  result = call_601940.call(path_601941, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_601927(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_601928, base: "/",
    url: url_DeleteGatewayResponse_601929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_601975 = ref object of OpenApiRestCall_600410
proc url_PutIntegration_601977(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutIntegration_601976(path: JsonNode; query: JsonNode;
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
  var valid_601978 = path.getOrDefault("http_method")
  valid_601978 = validateParameter(valid_601978, JString, required = true,
                                 default = nil)
  if valid_601978 != nil:
    section.add "http_method", valid_601978
  var valid_601979 = path.getOrDefault("restapi_id")
  valid_601979 = validateParameter(valid_601979, JString, required = true,
                                 default = nil)
  if valid_601979 != nil:
    section.add "restapi_id", valid_601979
  var valid_601980 = path.getOrDefault("resource_id")
  valid_601980 = validateParameter(valid_601980, JString, required = true,
                                 default = nil)
  if valid_601980 != nil:
    section.add "resource_id", valid_601980
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
  var valid_601981 = header.getOrDefault("X-Amz-Date")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Date", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Security-Token")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Security-Token", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Content-Sha256", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Algorithm")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Algorithm", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Signature")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Signature", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-SignedHeaders", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Credential")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Credential", valid_601987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601989: Call_PutIntegration_601975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_601989.validator(path, query, header, formData, body)
  let scheme = call_601989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601989.url(scheme.get, call_601989.host, call_601989.base,
                         call_601989.route, valid.getOrDefault("path"))
  result = hook(call_601989, url, valid)

proc call*(call_601990: Call_PutIntegration_601975; httpMethod: string;
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
  var path_601991 = newJObject()
  var body_601992 = newJObject()
  add(path_601991, "http_method", newJString(httpMethod))
  if body != nil:
    body_601992 = body
  add(path_601991, "restapi_id", newJString(restapiId))
  add(path_601991, "resource_id", newJString(resourceId))
  result = call_601990.call(path_601991, nil, nil, nil, body_601992)

var putIntegration* = Call_PutIntegration_601975(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_601976, base: "/", url: url_PutIntegration_601977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_601959 = ref object of OpenApiRestCall_600410
proc url_GetIntegration_601961(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegration_601960(path: JsonNode; query: JsonNode;
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
  var valid_601962 = path.getOrDefault("http_method")
  valid_601962 = validateParameter(valid_601962, JString, required = true,
                                 default = nil)
  if valid_601962 != nil:
    section.add "http_method", valid_601962
  var valid_601963 = path.getOrDefault("restapi_id")
  valid_601963 = validateParameter(valid_601963, JString, required = true,
                                 default = nil)
  if valid_601963 != nil:
    section.add "restapi_id", valid_601963
  var valid_601964 = path.getOrDefault("resource_id")
  valid_601964 = validateParameter(valid_601964, JString, required = true,
                                 default = nil)
  if valid_601964 != nil:
    section.add "resource_id", valid_601964
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
  var valid_601965 = header.getOrDefault("X-Amz-Date")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Date", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Security-Token")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Security-Token", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Content-Sha256", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Algorithm")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Algorithm", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Signature")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Signature", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-SignedHeaders", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Credential")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Credential", valid_601971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601972: Call_GetIntegration_601959; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_601972.validator(path, query, header, formData, body)
  let scheme = call_601972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601972.url(scheme.get, call_601972.host, call_601972.base,
                         call_601972.route, valid.getOrDefault("path"))
  result = hook(call_601972, url, valid)

proc call*(call_601973: Call_GetIntegration_601959; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_601974 = newJObject()
  add(path_601974, "http_method", newJString(httpMethod))
  add(path_601974, "restapi_id", newJString(restapiId))
  add(path_601974, "resource_id", newJString(resourceId))
  result = call_601973.call(path_601974, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_601959(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_601960, base: "/", url: url_GetIntegration_601961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_602009 = ref object of OpenApiRestCall_600410
proc url_UpdateIntegration_602011(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateIntegration_602010(path: JsonNode; query: JsonNode;
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
  var valid_602012 = path.getOrDefault("http_method")
  valid_602012 = validateParameter(valid_602012, JString, required = true,
                                 default = nil)
  if valid_602012 != nil:
    section.add "http_method", valid_602012
  var valid_602013 = path.getOrDefault("restapi_id")
  valid_602013 = validateParameter(valid_602013, JString, required = true,
                                 default = nil)
  if valid_602013 != nil:
    section.add "restapi_id", valid_602013
  var valid_602014 = path.getOrDefault("resource_id")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "resource_id", valid_602014
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
  var valid_602015 = header.getOrDefault("X-Amz-Date")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Date", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Security-Token")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Security-Token", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Algorithm")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Algorithm", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Signature")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Signature", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-SignedHeaders", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Credential")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Credential", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_UpdateIntegration_602009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"))
  result = hook(call_602023, url, valid)

proc call*(call_602024: Call_UpdateIntegration_602009; httpMethod: string;
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
  var path_602025 = newJObject()
  var body_602026 = newJObject()
  add(path_602025, "http_method", newJString(httpMethod))
  if body != nil:
    body_602026 = body
  add(path_602025, "restapi_id", newJString(restapiId))
  add(path_602025, "resource_id", newJString(resourceId))
  result = call_602024.call(path_602025, nil, nil, nil, body_602026)

var updateIntegration* = Call_UpdateIntegration_602009(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_602010, base: "/",
    url: url_UpdateIntegration_602011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_601993 = ref object of OpenApiRestCall_600410
proc url_DeleteIntegration_601995(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteIntegration_601994(path: JsonNode; query: JsonNode;
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
  var valid_601996 = path.getOrDefault("http_method")
  valid_601996 = validateParameter(valid_601996, JString, required = true,
                                 default = nil)
  if valid_601996 != nil:
    section.add "http_method", valid_601996
  var valid_601997 = path.getOrDefault("restapi_id")
  valid_601997 = validateParameter(valid_601997, JString, required = true,
                                 default = nil)
  if valid_601997 != nil:
    section.add "restapi_id", valid_601997
  var valid_601998 = path.getOrDefault("resource_id")
  valid_601998 = validateParameter(valid_601998, JString, required = true,
                                 default = nil)
  if valid_601998 != nil:
    section.add "resource_id", valid_601998
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
  var valid_601999 = header.getOrDefault("X-Amz-Date")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Date", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Security-Token")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Security-Token", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Algorithm")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Algorithm", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-SignedHeaders", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Credential")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Credential", valid_602005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602006: Call_DeleteIntegration_601993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_602006.validator(path, query, header, formData, body)
  let scheme = call_602006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602006.url(scheme.get, call_602006.host, call_602006.base,
                         call_602006.route, valid.getOrDefault("path"))
  result = hook(call_602006, url, valid)

proc call*(call_602007: Call_DeleteIntegration_601993; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_602008 = newJObject()
  add(path_602008, "http_method", newJString(httpMethod))
  add(path_602008, "restapi_id", newJString(restapiId))
  add(path_602008, "resource_id", newJString(resourceId))
  result = call_602007.call(path_602008, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_601993(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_601994, base: "/",
    url: url_DeleteIntegration_601995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_602044 = ref object of OpenApiRestCall_600410
proc url_PutIntegrationResponse_602046(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutIntegrationResponse_602045(path: JsonNode; query: JsonNode;
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
  var valid_602047 = path.getOrDefault("http_method")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = nil)
  if valid_602047 != nil:
    section.add "http_method", valid_602047
  var valid_602048 = path.getOrDefault("status_code")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "status_code", valid_602048
  var valid_602049 = path.getOrDefault("restapi_id")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "restapi_id", valid_602049
  var valid_602050 = path.getOrDefault("resource_id")
  valid_602050 = validateParameter(valid_602050, JString, required = true,
                                 default = nil)
  if valid_602050 != nil:
    section.add "resource_id", valid_602050
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
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Content-Sha256", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-SignedHeaders", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Credential")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Credential", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_PutIntegrationResponse_602044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"))
  result = hook(call_602059, url, valid)

proc call*(call_602060: Call_PutIntegrationResponse_602044; httpMethod: string;
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
  var path_602061 = newJObject()
  var body_602062 = newJObject()
  add(path_602061, "http_method", newJString(httpMethod))
  add(path_602061, "status_code", newJString(statusCode))
  if body != nil:
    body_602062 = body
  add(path_602061, "restapi_id", newJString(restapiId))
  add(path_602061, "resource_id", newJString(resourceId))
  result = call_602060.call(path_602061, nil, nil, nil, body_602062)

var putIntegrationResponse* = Call_PutIntegrationResponse_602044(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_602045, base: "/",
    url: url_PutIntegrationResponse_602046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_602027 = ref object of OpenApiRestCall_600410
proc url_GetIntegrationResponse_602029(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntegrationResponse_602028(path: JsonNode; query: JsonNode;
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
  var valid_602030 = path.getOrDefault("http_method")
  valid_602030 = validateParameter(valid_602030, JString, required = true,
                                 default = nil)
  if valid_602030 != nil:
    section.add "http_method", valid_602030
  var valid_602031 = path.getOrDefault("status_code")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "status_code", valid_602031
  var valid_602032 = path.getOrDefault("restapi_id")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "restapi_id", valid_602032
  var valid_602033 = path.getOrDefault("resource_id")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "resource_id", valid_602033
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
  var valid_602034 = header.getOrDefault("X-Amz-Date")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Date", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Content-Sha256", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Signature")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Signature", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Credential")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Credential", valid_602040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_GetIntegrationResponse_602027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"))
  result = hook(call_602041, url, valid)

proc call*(call_602042: Call_GetIntegrationResponse_602027; httpMethod: string;
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
  var path_602043 = newJObject()
  add(path_602043, "http_method", newJString(httpMethod))
  add(path_602043, "status_code", newJString(statusCode))
  add(path_602043, "restapi_id", newJString(restapiId))
  add(path_602043, "resource_id", newJString(resourceId))
  result = call_602042.call(path_602043, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_602027(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_602028, base: "/",
    url: url_GetIntegrationResponse_602029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_602080 = ref object of OpenApiRestCall_600410
proc url_UpdateIntegrationResponse_602082(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateIntegrationResponse_602081(path: JsonNode; query: JsonNode;
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
  var valid_602083 = path.getOrDefault("http_method")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "http_method", valid_602083
  var valid_602084 = path.getOrDefault("status_code")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = nil)
  if valid_602084 != nil:
    section.add "status_code", valid_602084
  var valid_602085 = path.getOrDefault("restapi_id")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = nil)
  if valid_602085 != nil:
    section.add "restapi_id", valid_602085
  var valid_602086 = path.getOrDefault("resource_id")
  valid_602086 = validateParameter(valid_602086, JString, required = true,
                                 default = nil)
  if valid_602086 != nil:
    section.add "resource_id", valid_602086
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
  var valid_602087 = header.getOrDefault("X-Amz-Date")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Date", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Security-Token")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Security-Token", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Content-Sha256", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Algorithm")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Algorithm", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-SignedHeaders", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602095: Call_UpdateIntegrationResponse_602080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_602095.validator(path, query, header, formData, body)
  let scheme = call_602095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602095.url(scheme.get, call_602095.host, call_602095.base,
                         call_602095.route, valid.getOrDefault("path"))
  result = hook(call_602095, url, valid)

proc call*(call_602096: Call_UpdateIntegrationResponse_602080; httpMethod: string;
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
  var path_602097 = newJObject()
  var body_602098 = newJObject()
  add(path_602097, "http_method", newJString(httpMethod))
  add(path_602097, "status_code", newJString(statusCode))
  if body != nil:
    body_602098 = body
  add(path_602097, "restapi_id", newJString(restapiId))
  add(path_602097, "resource_id", newJString(resourceId))
  result = call_602096.call(path_602097, nil, nil, nil, body_602098)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_602080(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_602081, base: "/",
    url: url_UpdateIntegrationResponse_602082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_602063 = ref object of OpenApiRestCall_600410
proc url_DeleteIntegrationResponse_602065(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteIntegrationResponse_602064(path: JsonNode; query: JsonNode;
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
  var valid_602066 = path.getOrDefault("http_method")
  valid_602066 = validateParameter(valid_602066, JString, required = true,
                                 default = nil)
  if valid_602066 != nil:
    section.add "http_method", valid_602066
  var valid_602067 = path.getOrDefault("status_code")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = nil)
  if valid_602067 != nil:
    section.add "status_code", valid_602067
  var valid_602068 = path.getOrDefault("restapi_id")
  valid_602068 = validateParameter(valid_602068, JString, required = true,
                                 default = nil)
  if valid_602068 != nil:
    section.add "restapi_id", valid_602068
  var valid_602069 = path.getOrDefault("resource_id")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "resource_id", valid_602069
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
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Security-Token")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Security-Token", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Content-Sha256", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Signature")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Signature", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-SignedHeaders", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Credential")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Credential", valid_602076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_DeleteIntegrationResponse_602063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"))
  result = hook(call_602077, url, valid)

proc call*(call_602078: Call_DeleteIntegrationResponse_602063; httpMethod: string;
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
  var path_602079 = newJObject()
  add(path_602079, "http_method", newJString(httpMethod))
  add(path_602079, "status_code", newJString(statusCode))
  add(path_602079, "restapi_id", newJString(restapiId))
  add(path_602079, "resource_id", newJString(resourceId))
  result = call_602078.call(path_602079, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_602063(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_602064, base: "/",
    url: url_DeleteIntegrationResponse_602065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_602115 = ref object of OpenApiRestCall_600410
proc url_PutMethod_602117(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutMethod_602116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602118 = path.getOrDefault("http_method")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = nil)
  if valid_602118 != nil:
    section.add "http_method", valid_602118
  var valid_602119 = path.getOrDefault("restapi_id")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "restapi_id", valid_602119
  var valid_602120 = path.getOrDefault("resource_id")
  valid_602120 = validateParameter(valid_602120, JString, required = true,
                                 default = nil)
  if valid_602120 != nil:
    section.add "resource_id", valid_602120
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
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Security-Token")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Security-Token", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Signature")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Signature", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Credential")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Credential", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602129: Call_PutMethod_602115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_602129.validator(path, query, header, formData, body)
  let scheme = call_602129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602129.url(scheme.get, call_602129.host, call_602129.base,
                         call_602129.route, valid.getOrDefault("path"))
  result = hook(call_602129, url, valid)

proc call*(call_602130: Call_PutMethod_602115; httpMethod: string; body: JsonNode;
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
  var path_602131 = newJObject()
  var body_602132 = newJObject()
  add(path_602131, "http_method", newJString(httpMethod))
  if body != nil:
    body_602132 = body
  add(path_602131, "restapi_id", newJString(restapiId))
  add(path_602131, "resource_id", newJString(resourceId))
  result = call_602130.call(path_602131, nil, nil, nil, body_602132)

var putMethod* = Call_PutMethod_602115(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_602116,
                                    base: "/", url: url_PutMethod_602117,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_602133 = ref object of OpenApiRestCall_600410
proc url_TestInvokeMethod_602135(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TestInvokeMethod_602134(path: JsonNode; query: JsonNode;
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
  var valid_602136 = path.getOrDefault("http_method")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = nil)
  if valid_602136 != nil:
    section.add "http_method", valid_602136
  var valid_602137 = path.getOrDefault("restapi_id")
  valid_602137 = validateParameter(valid_602137, JString, required = true,
                                 default = nil)
  if valid_602137 != nil:
    section.add "restapi_id", valid_602137
  var valid_602138 = path.getOrDefault("resource_id")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "resource_id", valid_602138
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
  var valid_602139 = header.getOrDefault("X-Amz-Date")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Date", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Security-Token")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Security-Token", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Content-Sha256", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Algorithm")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Algorithm", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-SignedHeaders", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Credential")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Credential", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_TestInvokeMethod_602133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"))
  result = hook(call_602147, url, valid)

proc call*(call_602148: Call_TestInvokeMethod_602133; httpMethod: string;
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
  var path_602149 = newJObject()
  var body_602150 = newJObject()
  add(path_602149, "http_method", newJString(httpMethod))
  if body != nil:
    body_602150 = body
  add(path_602149, "restapi_id", newJString(restapiId))
  add(path_602149, "resource_id", newJString(resourceId))
  result = call_602148.call(path_602149, nil, nil, nil, body_602150)

var testInvokeMethod* = Call_TestInvokeMethod_602133(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_602134, base: "/",
    url: url_TestInvokeMethod_602135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_602099 = ref object of OpenApiRestCall_600410
proc url_GetMethod_602101(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMethod_602100(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602102 = path.getOrDefault("http_method")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = nil)
  if valid_602102 != nil:
    section.add "http_method", valid_602102
  var valid_602103 = path.getOrDefault("restapi_id")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = nil)
  if valid_602103 != nil:
    section.add "restapi_id", valid_602103
  var valid_602104 = path.getOrDefault("resource_id")
  valid_602104 = validateParameter(valid_602104, JString, required = true,
                                 default = nil)
  if valid_602104 != nil:
    section.add "resource_id", valid_602104
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
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Security-Token")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Security-Token", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Content-Sha256", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Signature")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Signature", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-SignedHeaders", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602112: Call_GetMethod_602099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_602112.validator(path, query, header, formData, body)
  let scheme = call_602112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602112.url(scheme.get, call_602112.host, call_602112.base,
                         call_602112.route, valid.getOrDefault("path"))
  result = hook(call_602112, url, valid)

proc call*(call_602113: Call_GetMethod_602099; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_602114 = newJObject()
  add(path_602114, "http_method", newJString(httpMethod))
  add(path_602114, "restapi_id", newJString(restapiId))
  add(path_602114, "resource_id", newJString(resourceId))
  result = call_602113.call(path_602114, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_602099(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_602100,
                                    base: "/", url: url_GetMethod_602101,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_602167 = ref object of OpenApiRestCall_600410
proc url_UpdateMethod_602169(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateMethod_602168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602170 = path.getOrDefault("http_method")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "http_method", valid_602170
  var valid_602171 = path.getOrDefault("restapi_id")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = nil)
  if valid_602171 != nil:
    section.add "restapi_id", valid_602171
  var valid_602172 = path.getOrDefault("resource_id")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = nil)
  if valid_602172 != nil:
    section.add "resource_id", valid_602172
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
  var valid_602173 = header.getOrDefault("X-Amz-Date")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Date", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Security-Token")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Security-Token", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Algorithm")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Algorithm", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-SignedHeaders", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Credential")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Credential", valid_602179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_UpdateMethod_602167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"))
  result = hook(call_602181, url, valid)

proc call*(call_602182: Call_UpdateMethod_602167; httpMethod: string; body: JsonNode;
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
  var path_602183 = newJObject()
  var body_602184 = newJObject()
  add(path_602183, "http_method", newJString(httpMethod))
  if body != nil:
    body_602184 = body
  add(path_602183, "restapi_id", newJString(restapiId))
  add(path_602183, "resource_id", newJString(resourceId))
  result = call_602182.call(path_602183, nil, nil, nil, body_602184)

var updateMethod* = Call_UpdateMethod_602167(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_602168, base: "/", url: url_UpdateMethod_602169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_602151 = ref object of OpenApiRestCall_600410
proc url_DeleteMethod_602153(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMethod_602152(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602154 = path.getOrDefault("http_method")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = nil)
  if valid_602154 != nil:
    section.add "http_method", valid_602154
  var valid_602155 = path.getOrDefault("restapi_id")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = nil)
  if valid_602155 != nil:
    section.add "restapi_id", valid_602155
  var valid_602156 = path.getOrDefault("resource_id")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = nil)
  if valid_602156 != nil:
    section.add "resource_id", valid_602156
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
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Security-Token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Security-Token", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-SignedHeaders", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Credential")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Credential", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_DeleteMethod_602151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"))
  result = hook(call_602164, url, valid)

proc call*(call_602165: Call_DeleteMethod_602151; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_602166 = newJObject()
  add(path_602166, "http_method", newJString(httpMethod))
  add(path_602166, "restapi_id", newJString(restapiId))
  add(path_602166, "resource_id", newJString(resourceId))
  result = call_602165.call(path_602166, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_602151(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_602152, base: "/", url: url_DeleteMethod_602153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_602202 = ref object of OpenApiRestCall_600410
proc url_PutMethodResponse_602204(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutMethodResponse_602203(path: JsonNode; query: JsonNode;
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
  var valid_602205 = path.getOrDefault("http_method")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = nil)
  if valid_602205 != nil:
    section.add "http_method", valid_602205
  var valid_602206 = path.getOrDefault("status_code")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "status_code", valid_602206
  var valid_602207 = path.getOrDefault("restapi_id")
  valid_602207 = validateParameter(valid_602207, JString, required = true,
                                 default = nil)
  if valid_602207 != nil:
    section.add "restapi_id", valid_602207
  var valid_602208 = path.getOrDefault("resource_id")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = nil)
  if valid_602208 != nil:
    section.add "resource_id", valid_602208
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
  var valid_602209 = header.getOrDefault("X-Amz-Date")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Date", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Security-Token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Security-Token", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Algorithm")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Algorithm", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Signature")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Signature", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-SignedHeaders", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Credential")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Credential", valid_602215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602217: Call_PutMethodResponse_602202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_602217.validator(path, query, header, formData, body)
  let scheme = call_602217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602217.url(scheme.get, call_602217.host, call_602217.base,
                         call_602217.route, valid.getOrDefault("path"))
  result = hook(call_602217, url, valid)

proc call*(call_602218: Call_PutMethodResponse_602202; httpMethod: string;
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
  var path_602219 = newJObject()
  var body_602220 = newJObject()
  add(path_602219, "http_method", newJString(httpMethod))
  add(path_602219, "status_code", newJString(statusCode))
  if body != nil:
    body_602220 = body
  add(path_602219, "restapi_id", newJString(restapiId))
  add(path_602219, "resource_id", newJString(resourceId))
  result = call_602218.call(path_602219, nil, nil, nil, body_602220)

var putMethodResponse* = Call_PutMethodResponse_602202(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_602203, base: "/",
    url: url_PutMethodResponse_602204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_602185 = ref object of OpenApiRestCall_600410
proc url_GetMethodResponse_602187(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMethodResponse_602186(path: JsonNode; query: JsonNode;
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
  var valid_602188 = path.getOrDefault("http_method")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = nil)
  if valid_602188 != nil:
    section.add "http_method", valid_602188
  var valid_602189 = path.getOrDefault("status_code")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = nil)
  if valid_602189 != nil:
    section.add "status_code", valid_602189
  var valid_602190 = path.getOrDefault("restapi_id")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "restapi_id", valid_602190
  var valid_602191 = path.getOrDefault("resource_id")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "resource_id", valid_602191
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
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Content-Sha256", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Signature")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Signature", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-SignedHeaders", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602199: Call_GetMethodResponse_602185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_602199.validator(path, query, header, formData, body)
  let scheme = call_602199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602199.url(scheme.get, call_602199.host, call_602199.base,
                         call_602199.route, valid.getOrDefault("path"))
  result = hook(call_602199, url, valid)

proc call*(call_602200: Call_GetMethodResponse_602185; httpMethod: string;
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
  var path_602201 = newJObject()
  add(path_602201, "http_method", newJString(httpMethod))
  add(path_602201, "status_code", newJString(statusCode))
  add(path_602201, "restapi_id", newJString(restapiId))
  add(path_602201, "resource_id", newJString(resourceId))
  result = call_602200.call(path_602201, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_602185(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_602186, base: "/",
    url: url_GetMethodResponse_602187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_602238 = ref object of OpenApiRestCall_600410
proc url_UpdateMethodResponse_602240(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateMethodResponse_602239(path: JsonNode; query: JsonNode;
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
  var valid_602241 = path.getOrDefault("http_method")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = nil)
  if valid_602241 != nil:
    section.add "http_method", valid_602241
  var valid_602242 = path.getOrDefault("status_code")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "status_code", valid_602242
  var valid_602243 = path.getOrDefault("restapi_id")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "restapi_id", valid_602243
  var valid_602244 = path.getOrDefault("resource_id")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = nil)
  if valid_602244 != nil:
    section.add "resource_id", valid_602244
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
  var valid_602245 = header.getOrDefault("X-Amz-Date")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Date", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Security-Token")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Security-Token", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Content-Sha256", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Algorithm")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Algorithm", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Signature")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Signature", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Credential")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Credential", valid_602251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602253: Call_UpdateMethodResponse_602238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_602253.validator(path, query, header, formData, body)
  let scheme = call_602253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602253.url(scheme.get, call_602253.host, call_602253.base,
                         call_602253.route, valid.getOrDefault("path"))
  result = hook(call_602253, url, valid)

proc call*(call_602254: Call_UpdateMethodResponse_602238; httpMethod: string;
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
  var path_602255 = newJObject()
  var body_602256 = newJObject()
  add(path_602255, "http_method", newJString(httpMethod))
  add(path_602255, "status_code", newJString(statusCode))
  if body != nil:
    body_602256 = body
  add(path_602255, "restapi_id", newJString(restapiId))
  add(path_602255, "resource_id", newJString(resourceId))
  result = call_602254.call(path_602255, nil, nil, nil, body_602256)

var updateMethodResponse* = Call_UpdateMethodResponse_602238(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_602239, base: "/",
    url: url_UpdateMethodResponse_602240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_602221 = ref object of OpenApiRestCall_600410
proc url_DeleteMethodResponse_602223(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMethodResponse_602222(path: JsonNode; query: JsonNode;
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
  var valid_602224 = path.getOrDefault("http_method")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "http_method", valid_602224
  var valid_602225 = path.getOrDefault("status_code")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "status_code", valid_602225
  var valid_602226 = path.getOrDefault("restapi_id")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "restapi_id", valid_602226
  var valid_602227 = path.getOrDefault("resource_id")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "resource_id", valid_602227
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
  var valid_602228 = header.getOrDefault("X-Amz-Date")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Date", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Content-Sha256", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Signature")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Signature", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-SignedHeaders", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Credential")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Credential", valid_602234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602235: Call_DeleteMethodResponse_602221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_602235.validator(path, query, header, formData, body)
  let scheme = call_602235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602235.url(scheme.get, call_602235.host, call_602235.base,
                         call_602235.route, valid.getOrDefault("path"))
  result = hook(call_602235, url, valid)

proc call*(call_602236: Call_DeleteMethodResponse_602221; httpMethod: string;
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
  var path_602237 = newJObject()
  add(path_602237, "http_method", newJString(httpMethod))
  add(path_602237, "status_code", newJString(statusCode))
  add(path_602237, "restapi_id", newJString(restapiId))
  add(path_602237, "resource_id", newJString(resourceId))
  result = call_602236.call(path_602237, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_602221(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_602222, base: "/",
    url: url_DeleteMethodResponse_602223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_602257 = ref object of OpenApiRestCall_600410
proc url_GetModel_602259(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModel_602258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602260 = path.getOrDefault("model_name")
  valid_602260 = validateParameter(valid_602260, JString, required = true,
                                 default = nil)
  if valid_602260 != nil:
    section.add "model_name", valid_602260
  var valid_602261 = path.getOrDefault("restapi_id")
  valid_602261 = validateParameter(valid_602261, JString, required = true,
                                 default = nil)
  if valid_602261 != nil:
    section.add "restapi_id", valid_602261
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_602262 = query.getOrDefault("flatten")
  valid_602262 = validateParameter(valid_602262, JBool, required = false, default = nil)
  if valid_602262 != nil:
    section.add "flatten", valid_602262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602263 = header.getOrDefault("X-Amz-Date")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Date", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Security-Token")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Security-Token", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Content-Sha256", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Algorithm")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Algorithm", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Signature")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Signature", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-SignedHeaders", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Credential")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Credential", valid_602269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602270: Call_GetModel_602257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_602270.validator(path, query, header, formData, body)
  let scheme = call_602270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602270.url(scheme.get, call_602270.host, call_602270.base,
                         call_602270.route, valid.getOrDefault("path"))
  result = hook(call_602270, url, valid)

proc call*(call_602271: Call_GetModel_602257; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_602272 = newJObject()
  var query_602273 = newJObject()
  add(query_602273, "flatten", newJBool(flatten))
  add(path_602272, "model_name", newJString(modelName))
  add(path_602272, "restapi_id", newJString(restapiId))
  result = call_602271.call(path_602272, query_602273, nil, nil, nil)

var getModel* = Call_GetModel_602257(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_602258, base: "/",
                                  url: url_GetModel_602259,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_602289 = ref object of OpenApiRestCall_600410
proc url_UpdateModel_602291(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateModel_602290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602292 = path.getOrDefault("model_name")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = nil)
  if valid_602292 != nil:
    section.add "model_name", valid_602292
  var valid_602293 = path.getOrDefault("restapi_id")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = nil)
  if valid_602293 != nil:
    section.add "restapi_id", valid_602293
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
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Security-Token")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Security-Token", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-SignedHeaders", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Credential")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Credential", valid_602300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602302: Call_UpdateModel_602289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_602302.validator(path, query, header, formData, body)
  let scheme = call_602302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602302.url(scheme.get, call_602302.host, call_602302.base,
                         call_602302.route, valid.getOrDefault("path"))
  result = hook(call_602302, url, valid)

proc call*(call_602303: Call_UpdateModel_602289; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602304 = newJObject()
  var body_602305 = newJObject()
  add(path_602304, "model_name", newJString(modelName))
  if body != nil:
    body_602305 = body
  add(path_602304, "restapi_id", newJString(restapiId))
  result = call_602303.call(path_602304, nil, nil, nil, body_602305)

var updateModel* = Call_UpdateModel_602289(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_602290,
                                        base: "/", url: url_UpdateModel_602291,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_602274 = ref object of OpenApiRestCall_600410
proc url_DeleteModel_602276(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteModel_602275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602277 = path.getOrDefault("model_name")
  valid_602277 = validateParameter(valid_602277, JString, required = true,
                                 default = nil)
  if valid_602277 != nil:
    section.add "model_name", valid_602277
  var valid_602278 = path.getOrDefault("restapi_id")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "restapi_id", valid_602278
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
  var valid_602279 = header.getOrDefault("X-Amz-Date")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Date", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Security-Token")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Security-Token", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Content-Sha256", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Algorithm")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Algorithm", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-SignedHeaders", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Credential")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Credential", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602286: Call_DeleteModel_602274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_602286.validator(path, query, header, formData, body)
  let scheme = call_602286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602286.url(scheme.get, call_602286.host, call_602286.base,
                         call_602286.route, valid.getOrDefault("path"))
  result = hook(call_602286, url, valid)

proc call*(call_602287: Call_DeleteModel_602274; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602288 = newJObject()
  add(path_602288, "model_name", newJString(modelName))
  add(path_602288, "restapi_id", newJString(restapiId))
  result = call_602287.call(path_602288, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_602274(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_602275,
                                        base: "/", url: url_DeleteModel_602276,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_602306 = ref object of OpenApiRestCall_600410
proc url_GetRequestValidator_602308(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRequestValidator_602307(path: JsonNode; query: JsonNode;
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
  var valid_602309 = path.getOrDefault("requestvalidator_id")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = nil)
  if valid_602309 != nil:
    section.add "requestvalidator_id", valid_602309
  var valid_602310 = path.getOrDefault("restapi_id")
  valid_602310 = validateParameter(valid_602310, JString, required = true,
                                 default = nil)
  if valid_602310 != nil:
    section.add "restapi_id", valid_602310
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
  var valid_602311 = header.getOrDefault("X-Amz-Date")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Date", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Security-Token")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Security-Token", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Algorithm")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Algorithm", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602318: Call_GetRequestValidator_602306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_602318.validator(path, query, header, formData, body)
  let scheme = call_602318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602318.url(scheme.get, call_602318.host, call_602318.base,
                         call_602318.route, valid.getOrDefault("path"))
  result = hook(call_602318, url, valid)

proc call*(call_602319: Call_GetRequestValidator_602306;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602320 = newJObject()
  add(path_602320, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_602320, "restapi_id", newJString(restapiId))
  result = call_602319.call(path_602320, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_602306(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_602307, base: "/",
    url: url_GetRequestValidator_602308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_602336 = ref object of OpenApiRestCall_600410
proc url_UpdateRequestValidator_602338(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRequestValidator_602337(path: JsonNode; query: JsonNode;
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
  var valid_602339 = path.getOrDefault("requestvalidator_id")
  valid_602339 = validateParameter(valid_602339, JString, required = true,
                                 default = nil)
  if valid_602339 != nil:
    section.add "requestvalidator_id", valid_602339
  var valid_602340 = path.getOrDefault("restapi_id")
  valid_602340 = validateParameter(valid_602340, JString, required = true,
                                 default = nil)
  if valid_602340 != nil:
    section.add "restapi_id", valid_602340
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
  var valid_602341 = header.getOrDefault("X-Amz-Date")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Date", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Security-Token")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Security-Token", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Content-Sha256", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Algorithm")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Algorithm", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-SignedHeaders", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Credential")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Credential", valid_602347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602349: Call_UpdateRequestValidator_602336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_602349.validator(path, query, header, formData, body)
  let scheme = call_602349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602349.url(scheme.get, call_602349.host, call_602349.base,
                         call_602349.route, valid.getOrDefault("path"))
  result = hook(call_602349, url, valid)

proc call*(call_602350: Call_UpdateRequestValidator_602336;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602351 = newJObject()
  var body_602352 = newJObject()
  add(path_602351, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_602352 = body
  add(path_602351, "restapi_id", newJString(restapiId))
  result = call_602350.call(path_602351, nil, nil, nil, body_602352)

var updateRequestValidator* = Call_UpdateRequestValidator_602336(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_602337, base: "/",
    url: url_UpdateRequestValidator_602338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_602321 = ref object of OpenApiRestCall_600410
proc url_DeleteRequestValidator_602323(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRequestValidator_602322(path: JsonNode; query: JsonNode;
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
  var valid_602324 = path.getOrDefault("requestvalidator_id")
  valid_602324 = validateParameter(valid_602324, JString, required = true,
                                 default = nil)
  if valid_602324 != nil:
    section.add "requestvalidator_id", valid_602324
  var valid_602325 = path.getOrDefault("restapi_id")
  valid_602325 = validateParameter(valid_602325, JString, required = true,
                                 default = nil)
  if valid_602325 != nil:
    section.add "restapi_id", valid_602325
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
  var valid_602326 = header.getOrDefault("X-Amz-Date")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Date", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Security-Token")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Security-Token", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Algorithm")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Algorithm", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-SignedHeaders", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Credential")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Credential", valid_602332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602333: Call_DeleteRequestValidator_602321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_602333.validator(path, query, header, formData, body)
  let scheme = call_602333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602333.url(scheme.get, call_602333.host, call_602333.base,
                         call_602333.route, valid.getOrDefault("path"))
  result = hook(call_602333, url, valid)

proc call*(call_602334: Call_DeleteRequestValidator_602321;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602335 = newJObject()
  add(path_602335, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_602335, "restapi_id", newJString(restapiId))
  result = call_602334.call(path_602335, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_602321(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_602322, base: "/",
    url: url_DeleteRequestValidator_602323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_602353 = ref object of OpenApiRestCall_600410
proc url_GetResource_602355(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetResource_602354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602356 = path.getOrDefault("restapi_id")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = nil)
  if valid_602356 != nil:
    section.add "restapi_id", valid_602356
  var valid_602357 = path.getOrDefault("resource_id")
  valid_602357 = validateParameter(valid_602357, JString, required = true,
                                 default = nil)
  if valid_602357 != nil:
    section.add "resource_id", valid_602357
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_602358 = query.getOrDefault("embed")
  valid_602358 = validateParameter(valid_602358, JArray, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "embed", valid_602358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602359 = header.getOrDefault("X-Amz-Date")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Date", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Security-Token")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Security-Token", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Signature")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Signature", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-SignedHeaders", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602366: Call_GetResource_602353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_602366.validator(path, query, header, formData, body)
  let scheme = call_602366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602366.url(scheme.get, call_602366.host, call_602366.base,
                         call_602366.route, valid.getOrDefault("path"))
  result = hook(call_602366, url, valid)

proc call*(call_602367: Call_GetResource_602353; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_602368 = newJObject()
  var query_602369 = newJObject()
  if embed != nil:
    query_602369.add "embed", embed
  add(path_602368, "restapi_id", newJString(restapiId))
  add(path_602368, "resource_id", newJString(resourceId))
  result = call_602367.call(path_602368, query_602369, nil, nil, nil)

var getResource* = Call_GetResource_602353(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_602354,
                                        base: "/", url: url_GetResource_602355,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_602385 = ref object of OpenApiRestCall_600410
proc url_UpdateResource_602387(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateResource_602386(path: JsonNode; query: JsonNode;
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
  var valid_602388 = path.getOrDefault("restapi_id")
  valid_602388 = validateParameter(valid_602388, JString, required = true,
                                 default = nil)
  if valid_602388 != nil:
    section.add "restapi_id", valid_602388
  var valid_602389 = path.getOrDefault("resource_id")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = nil)
  if valid_602389 != nil:
    section.add "resource_id", valid_602389
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
  var valid_602390 = header.getOrDefault("X-Amz-Date")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Date", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Security-Token")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Security-Token", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Content-Sha256", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Algorithm")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Algorithm", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-SignedHeaders", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Credential")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Credential", valid_602396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602398: Call_UpdateResource_602385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_602398.validator(path, query, header, formData, body)
  let scheme = call_602398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602398.url(scheme.get, call_602398.host, call_602398.base,
                         call_602398.route, valid.getOrDefault("path"))
  result = hook(call_602398, url, valid)

proc call*(call_602399: Call_UpdateResource_602385; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_602400 = newJObject()
  var body_602401 = newJObject()
  if body != nil:
    body_602401 = body
  add(path_602400, "restapi_id", newJString(restapiId))
  add(path_602400, "resource_id", newJString(resourceId))
  result = call_602399.call(path_602400, nil, nil, nil, body_602401)

var updateResource* = Call_UpdateResource_602385(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_602386, base: "/", url: url_UpdateResource_602387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_602370 = ref object of OpenApiRestCall_600410
proc url_DeleteResource_602372(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteResource_602371(path: JsonNode; query: JsonNode;
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
  var valid_602373 = path.getOrDefault("restapi_id")
  valid_602373 = validateParameter(valid_602373, JString, required = true,
                                 default = nil)
  if valid_602373 != nil:
    section.add "restapi_id", valid_602373
  var valid_602374 = path.getOrDefault("resource_id")
  valid_602374 = validateParameter(valid_602374, JString, required = true,
                                 default = nil)
  if valid_602374 != nil:
    section.add "resource_id", valid_602374
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
  var valid_602375 = header.getOrDefault("X-Amz-Date")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Date", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Security-Token")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Security-Token", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Content-Sha256", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Algorithm")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Algorithm", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-SignedHeaders", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Credential")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Credential", valid_602381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602382: Call_DeleteResource_602370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_602382.validator(path, query, header, formData, body)
  let scheme = call_602382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602382.url(scheme.get, call_602382.host, call_602382.base,
                         call_602382.route, valid.getOrDefault("path"))
  result = hook(call_602382, url, valid)

proc call*(call_602383: Call_DeleteResource_602370; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_602384 = newJObject()
  add(path_602384, "restapi_id", newJString(restapiId))
  add(path_602384, "resource_id", newJString(resourceId))
  result = call_602383.call(path_602384, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_602370(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_602371, base: "/", url: url_DeleteResource_602372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_602416 = ref object of OpenApiRestCall_600410
proc url_PutRestApi_602418(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutRestApi_602417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602419 = path.getOrDefault("restapi_id")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = nil)
  if valid_602419 != nil:
    section.add "restapi_id", valid_602419
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
  var valid_602420 = query.getOrDefault("parameters.0.value")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "parameters.0.value", valid_602420
  var valid_602421 = query.getOrDefault("parameters.2.value")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "parameters.2.value", valid_602421
  var valid_602422 = query.getOrDefault("parameters.1.key")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "parameters.1.key", valid_602422
  var valid_602423 = query.getOrDefault("mode")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = newJString("merge"))
  if valid_602423 != nil:
    section.add "mode", valid_602423
  var valid_602424 = query.getOrDefault("parameters.0.key")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "parameters.0.key", valid_602424
  var valid_602425 = query.getOrDefault("parameters.2.key")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "parameters.2.key", valid_602425
  var valid_602426 = query.getOrDefault("failonwarnings")
  valid_602426 = validateParameter(valid_602426, JBool, required = false, default = nil)
  if valid_602426 != nil:
    section.add "failonwarnings", valid_602426
  var valid_602427 = query.getOrDefault("parameters.1.value")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "parameters.1.value", valid_602427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602428 = header.getOrDefault("X-Amz-Date")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Date", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Security-Token")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Security-Token", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Content-Sha256", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Algorithm")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Algorithm", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Signature")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Signature", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Credential")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Credential", valid_602434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602436: Call_PutRestApi_602416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_602436.validator(path, query, header, formData, body)
  let scheme = call_602436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602436.url(scheme.get, call_602436.host, call_602436.base,
                         call_602436.route, valid.getOrDefault("path"))
  result = hook(call_602436, url, valid)

proc call*(call_602437: Call_PutRestApi_602416; body: JsonNode; restapiId: string;
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
  var path_602438 = newJObject()
  var query_602439 = newJObject()
  var body_602440 = newJObject()
  add(query_602439, "parameters.0.value", newJString(parameters0Value))
  add(query_602439, "parameters.2.value", newJString(parameters2Value))
  add(query_602439, "parameters.1.key", newJString(parameters1Key))
  add(query_602439, "mode", newJString(mode))
  add(query_602439, "parameters.0.key", newJString(parameters0Key))
  add(query_602439, "parameters.2.key", newJString(parameters2Key))
  add(query_602439, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_602440 = body
  add(query_602439, "parameters.1.value", newJString(parameters1Value))
  add(path_602438, "restapi_id", newJString(restapiId))
  result = call_602437.call(path_602438, query_602439, nil, nil, body_602440)

var putRestApi* = Call_PutRestApi_602416(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_602417,
                                      base: "/", url: url_PutRestApi_602418,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_602402 = ref object of OpenApiRestCall_600410
proc url_GetRestApi_602404(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRestApi_602403(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602405 = path.getOrDefault("restapi_id")
  valid_602405 = validateParameter(valid_602405, JString, required = true,
                                 default = nil)
  if valid_602405 != nil:
    section.add "restapi_id", valid_602405
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
  var valid_602406 = header.getOrDefault("X-Amz-Date")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Date", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Security-Token")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Security-Token", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Content-Sha256", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Algorithm")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Algorithm", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Signature")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Signature", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-SignedHeaders", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Credential")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Credential", valid_602412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602413: Call_GetRestApi_602402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_602413.validator(path, query, header, formData, body)
  let scheme = call_602413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602413.url(scheme.get, call_602413.host, call_602413.base,
                         call_602413.route, valid.getOrDefault("path"))
  result = hook(call_602413, url, valid)

proc call*(call_602414: Call_GetRestApi_602402; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602415 = newJObject()
  add(path_602415, "restapi_id", newJString(restapiId))
  result = call_602414.call(path_602415, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_602402(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_602403,
                                      base: "/", url: url_GetRestApi_602404,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_602455 = ref object of OpenApiRestCall_600410
proc url_UpdateRestApi_602457(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRestApi_602456(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602458 = path.getOrDefault("restapi_id")
  valid_602458 = validateParameter(valid_602458, JString, required = true,
                                 default = nil)
  if valid_602458 != nil:
    section.add "restapi_id", valid_602458
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
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Security-Token")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Security-Token", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Content-Sha256", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Signature")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Signature", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-SignedHeaders", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602467: Call_UpdateRestApi_602455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_602467.validator(path, query, header, formData, body)
  let scheme = call_602467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602467.url(scheme.get, call_602467.host, call_602467.base,
                         call_602467.route, valid.getOrDefault("path"))
  result = hook(call_602467, url, valid)

proc call*(call_602468: Call_UpdateRestApi_602455; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602469 = newJObject()
  var body_602470 = newJObject()
  if body != nil:
    body_602470 = body
  add(path_602469, "restapi_id", newJString(restapiId))
  result = call_602468.call(path_602469, nil, nil, nil, body_602470)

var updateRestApi* = Call_UpdateRestApi_602455(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_602456,
    base: "/", url: url_UpdateRestApi_602457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_602441 = ref object of OpenApiRestCall_600410
proc url_DeleteRestApi_602443(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "restapi_id" in path, "`restapi_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restapis/"),
               (kind: VariableSegment, value: "restapi_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRestApi_602442(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602444 = path.getOrDefault("restapi_id")
  valid_602444 = validateParameter(valid_602444, JString, required = true,
                                 default = nil)
  if valid_602444 != nil:
    section.add "restapi_id", valid_602444
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
  var valid_602445 = header.getOrDefault("X-Amz-Date")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Date", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Content-Sha256", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Algorithm")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Algorithm", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Signature")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Signature", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-SignedHeaders", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Credential")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Credential", valid_602451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602452: Call_DeleteRestApi_602441; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_602452.validator(path, query, header, formData, body)
  let scheme = call_602452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602452.url(scheme.get, call_602452.host, call_602452.base,
                         call_602452.route, valid.getOrDefault("path"))
  result = hook(call_602452, url, valid)

proc call*(call_602453: Call_DeleteRestApi_602441; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602454 = newJObject()
  add(path_602454, "restapi_id", newJString(restapiId))
  result = call_602453.call(path_602454, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_602441(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_602442,
    base: "/", url: url_DeleteRestApi_602443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_602471 = ref object of OpenApiRestCall_600410
proc url_GetStage_602473(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStage_602472(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602474 = path.getOrDefault("stage_name")
  valid_602474 = validateParameter(valid_602474, JString, required = true,
                                 default = nil)
  if valid_602474 != nil:
    section.add "stage_name", valid_602474
  var valid_602475 = path.getOrDefault("restapi_id")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "restapi_id", valid_602475
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
  var valid_602476 = header.getOrDefault("X-Amz-Date")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Date", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Security-Token")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Security-Token", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Content-Sha256", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Algorithm")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Algorithm", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Signature")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Signature", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-SignedHeaders", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Credential")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Credential", valid_602482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602483: Call_GetStage_602471; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_602483.validator(path, query, header, formData, body)
  let scheme = call_602483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602483.url(scheme.get, call_602483.host, call_602483.base,
                         call_602483.route, valid.getOrDefault("path"))
  result = hook(call_602483, url, valid)

proc call*(call_602484: Call_GetStage_602471; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602485 = newJObject()
  add(path_602485, "stage_name", newJString(stageName))
  add(path_602485, "restapi_id", newJString(restapiId))
  result = call_602484.call(path_602485, nil, nil, nil, nil)

var getStage* = Call_GetStage_602471(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_602472, base: "/",
                                  url: url_GetStage_602473,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_602501 = ref object of OpenApiRestCall_600410
proc url_UpdateStage_602503(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateStage_602502(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602504 = path.getOrDefault("stage_name")
  valid_602504 = validateParameter(valid_602504, JString, required = true,
                                 default = nil)
  if valid_602504 != nil:
    section.add "stage_name", valid_602504
  var valid_602505 = path.getOrDefault("restapi_id")
  valid_602505 = validateParameter(valid_602505, JString, required = true,
                                 default = nil)
  if valid_602505 != nil:
    section.add "restapi_id", valid_602505
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
  var valid_602506 = header.getOrDefault("X-Amz-Date")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Date", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Security-Token")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Security-Token", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Content-Sha256", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Algorithm")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Algorithm", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Signature")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Signature", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-SignedHeaders", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Credential")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Credential", valid_602512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_UpdateStage_602501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"))
  result = hook(call_602514, url, valid)

proc call*(call_602515: Call_UpdateStage_602501; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602516 = newJObject()
  var body_602517 = newJObject()
  if body != nil:
    body_602517 = body
  add(path_602516, "stage_name", newJString(stageName))
  add(path_602516, "restapi_id", newJString(restapiId))
  result = call_602515.call(path_602516, nil, nil, nil, body_602517)

var updateStage* = Call_UpdateStage_602501(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_602502,
                                        base: "/", url: url_UpdateStage_602503,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_602486 = ref object of OpenApiRestCall_600410
proc url_DeleteStage_602488(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteStage_602487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602489 = path.getOrDefault("stage_name")
  valid_602489 = validateParameter(valid_602489, JString, required = true,
                                 default = nil)
  if valid_602489 != nil:
    section.add "stage_name", valid_602489
  var valid_602490 = path.getOrDefault("restapi_id")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = nil)
  if valid_602490 != nil:
    section.add "restapi_id", valid_602490
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
  var valid_602491 = header.getOrDefault("X-Amz-Date")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Date", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Security-Token")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Security-Token", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Content-Sha256", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Algorithm")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Algorithm", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Signature")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Signature", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-SignedHeaders", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Credential")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Credential", valid_602497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602498: Call_DeleteStage_602486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_602498.validator(path, query, header, formData, body)
  let scheme = call_602498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602498.url(scheme.get, call_602498.host, call_602498.base,
                         call_602498.route, valid.getOrDefault("path"))
  result = hook(call_602498, url, valid)

proc call*(call_602499: Call_DeleteStage_602486; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602500 = newJObject()
  add(path_602500, "stage_name", newJString(stageName))
  add(path_602500, "restapi_id", newJString(restapiId))
  result = call_602499.call(path_602500, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_602486(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_602487,
                                        base: "/", url: url_DeleteStage_602488,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_602518 = ref object of OpenApiRestCall_600410
proc url_GetUsagePlan_602520(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUsagePlan_602519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602521 = path.getOrDefault("usageplanId")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = nil)
  if valid_602521 != nil:
    section.add "usageplanId", valid_602521
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
  var valid_602522 = header.getOrDefault("X-Amz-Date")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Date", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Security-Token")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Security-Token", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Content-Sha256", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Signature")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Signature", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-SignedHeaders", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Credential")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Credential", valid_602528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602529: Call_GetUsagePlan_602518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_602529.validator(path, query, header, formData, body)
  let scheme = call_602529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602529.url(scheme.get, call_602529.host, call_602529.base,
                         call_602529.route, valid.getOrDefault("path"))
  result = hook(call_602529, url, valid)

proc call*(call_602530: Call_GetUsagePlan_602518; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_602531 = newJObject()
  add(path_602531, "usageplanId", newJString(usageplanId))
  result = call_602530.call(path_602531, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_602518(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_602519,
    base: "/", url: url_GetUsagePlan_602520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_602546 = ref object of OpenApiRestCall_600410
proc url_UpdateUsagePlan_602548(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUsagePlan_602547(path: JsonNode; query: JsonNode;
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
  var valid_602549 = path.getOrDefault("usageplanId")
  valid_602549 = validateParameter(valid_602549, JString, required = true,
                                 default = nil)
  if valid_602549 != nil:
    section.add "usageplanId", valid_602549
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
  var valid_602550 = header.getOrDefault("X-Amz-Date")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Date", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Security-Token")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Security-Token", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Content-Sha256", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Algorithm")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Algorithm", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Signature")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Signature", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-SignedHeaders", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Credential")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Credential", valid_602556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602558: Call_UpdateUsagePlan_602546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_602558.validator(path, query, header, formData, body)
  let scheme = call_602558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602558.url(scheme.get, call_602558.host, call_602558.base,
                         call_602558.route, valid.getOrDefault("path"))
  result = hook(call_602558, url, valid)

proc call*(call_602559: Call_UpdateUsagePlan_602546; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_602560 = newJObject()
  var body_602561 = newJObject()
  add(path_602560, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_602561 = body
  result = call_602559.call(path_602560, nil, nil, nil, body_602561)

var updateUsagePlan* = Call_UpdateUsagePlan_602546(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_602547,
    base: "/", url: url_UpdateUsagePlan_602548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_602532 = ref object of OpenApiRestCall_600410
proc url_DeleteUsagePlan_602534(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "usageplanId" in path, "`usageplanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/usageplans/"),
               (kind: VariableSegment, value: "usageplanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUsagePlan_602533(path: JsonNode; query: JsonNode;
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
  var valid_602535 = path.getOrDefault("usageplanId")
  valid_602535 = validateParameter(valid_602535, JString, required = true,
                                 default = nil)
  if valid_602535 != nil:
    section.add "usageplanId", valid_602535
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
  var valid_602536 = header.getOrDefault("X-Amz-Date")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Date", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Security-Token")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Security-Token", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Content-Sha256", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Algorithm")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Algorithm", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Signature")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Signature", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-SignedHeaders", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Credential")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Credential", valid_602542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602543: Call_DeleteUsagePlan_602532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_602543.validator(path, query, header, formData, body)
  let scheme = call_602543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602543.url(scheme.get, call_602543.host, call_602543.base,
                         call_602543.route, valid.getOrDefault("path"))
  result = hook(call_602543, url, valid)

proc call*(call_602544: Call_DeleteUsagePlan_602532; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_602545 = newJObject()
  add(path_602545, "usageplanId", newJString(usageplanId))
  result = call_602544.call(path_602545, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_602532(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_602533,
    base: "/", url: url_DeleteUsagePlan_602534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_602562 = ref object of OpenApiRestCall_600410
proc url_GetUsagePlanKey_602564(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUsagePlanKey_602563(path: JsonNode; query: JsonNode;
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
  var valid_602565 = path.getOrDefault("keyId")
  valid_602565 = validateParameter(valid_602565, JString, required = true,
                                 default = nil)
  if valid_602565 != nil:
    section.add "keyId", valid_602565
  var valid_602566 = path.getOrDefault("usageplanId")
  valid_602566 = validateParameter(valid_602566, JString, required = true,
                                 default = nil)
  if valid_602566 != nil:
    section.add "usageplanId", valid_602566
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
  var valid_602567 = header.getOrDefault("X-Amz-Date")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Date", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Security-Token")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Security-Token", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Content-Sha256", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Algorithm")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Algorithm", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Signature")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Signature", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-SignedHeaders", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Credential")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Credential", valid_602573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602574: Call_GetUsagePlanKey_602562; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_602574.validator(path, query, header, formData, body)
  let scheme = call_602574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602574.url(scheme.get, call_602574.host, call_602574.base,
                         call_602574.route, valid.getOrDefault("path"))
  result = hook(call_602574, url, valid)

proc call*(call_602575: Call_GetUsagePlanKey_602562; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_602576 = newJObject()
  add(path_602576, "keyId", newJString(keyId))
  add(path_602576, "usageplanId", newJString(usageplanId))
  result = call_602575.call(path_602576, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_602562(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_602563, base: "/", url: url_GetUsagePlanKey_602564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_602577 = ref object of OpenApiRestCall_600410
proc url_DeleteUsagePlanKey_602579(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUsagePlanKey_602578(path: JsonNode; query: JsonNode;
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
  var valid_602580 = path.getOrDefault("keyId")
  valid_602580 = validateParameter(valid_602580, JString, required = true,
                                 default = nil)
  if valid_602580 != nil:
    section.add "keyId", valid_602580
  var valid_602581 = path.getOrDefault("usageplanId")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = nil)
  if valid_602581 != nil:
    section.add "usageplanId", valid_602581
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
  var valid_602582 = header.getOrDefault("X-Amz-Date")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Date", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Security-Token")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Security-Token", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Content-Sha256", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Algorithm")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Algorithm", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Signature")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Signature", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-SignedHeaders", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Credential")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Credential", valid_602588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602589: Call_DeleteUsagePlanKey_602577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_602589.validator(path, query, header, formData, body)
  let scheme = call_602589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602589.url(scheme.get, call_602589.host, call_602589.base,
                         call_602589.route, valid.getOrDefault("path"))
  result = hook(call_602589, url, valid)

proc call*(call_602590: Call_DeleteUsagePlanKey_602577; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_602591 = newJObject()
  add(path_602591, "keyId", newJString(keyId))
  add(path_602591, "usageplanId", newJString(usageplanId))
  result = call_602590.call(path_602591, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_602577(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_602578, base: "/",
    url: url_DeleteUsagePlanKey_602579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_602592 = ref object of OpenApiRestCall_600410
proc url_GetVpcLink_602594(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVpcLink_602593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602595 = path.getOrDefault("vpclink_id")
  valid_602595 = validateParameter(valid_602595, JString, required = true,
                                 default = nil)
  if valid_602595 != nil:
    section.add "vpclink_id", valid_602595
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
  var valid_602596 = header.getOrDefault("X-Amz-Date")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Date", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Security-Token")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Security-Token", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Content-Sha256", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Algorithm")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Algorithm", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Signature")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Signature", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-SignedHeaders", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Credential")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Credential", valid_602602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602603: Call_GetVpcLink_602592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_602603.validator(path, query, header, formData, body)
  let scheme = call_602603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602603.url(scheme.get, call_602603.host, call_602603.base,
                         call_602603.route, valid.getOrDefault("path"))
  result = hook(call_602603, url, valid)

proc call*(call_602604: Call_GetVpcLink_602592; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_602605 = newJObject()
  add(path_602605, "vpclink_id", newJString(vpclinkId))
  result = call_602604.call(path_602605, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_602592(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_602593,
                                      base: "/", url: url_GetVpcLink_602594,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_602620 = ref object of OpenApiRestCall_600410
proc url_UpdateVpcLink_602622(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVpcLink_602621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602623 = path.getOrDefault("vpclink_id")
  valid_602623 = validateParameter(valid_602623, JString, required = true,
                                 default = nil)
  if valid_602623 != nil:
    section.add "vpclink_id", valid_602623
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
  var valid_602624 = header.getOrDefault("X-Amz-Date")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Date", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Security-Token")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Security-Token", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Content-Sha256", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Algorithm")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Algorithm", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Signature")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Signature", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-SignedHeaders", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Credential")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Credential", valid_602630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602632: Call_UpdateVpcLink_602620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_602632.validator(path, query, header, formData, body)
  let scheme = call_602632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602632.url(scheme.get, call_602632.host, call_602632.base,
                         call_602632.route, valid.getOrDefault("path"))
  result = hook(call_602632, url, valid)

proc call*(call_602633: Call_UpdateVpcLink_602620; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_602634 = newJObject()
  var body_602635 = newJObject()
  if body != nil:
    body_602635 = body
  add(path_602634, "vpclink_id", newJString(vpclinkId))
  result = call_602633.call(path_602634, nil, nil, nil, body_602635)

var updateVpcLink* = Call_UpdateVpcLink_602620(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_602621,
    base: "/", url: url_UpdateVpcLink_602622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_602606 = ref object of OpenApiRestCall_600410
proc url_DeleteVpcLink_602608(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "vpclink_id" in path, "`vpclink_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/vpclinks/"),
               (kind: VariableSegment, value: "vpclink_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVpcLink_602607(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602609 = path.getOrDefault("vpclink_id")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = nil)
  if valid_602609 != nil:
    section.add "vpclink_id", valid_602609
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
  var valid_602610 = header.getOrDefault("X-Amz-Date")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Date", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Security-Token")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Security-Token", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Content-Sha256", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Algorithm")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Algorithm", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Signature")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Signature", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Credential")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Credential", valid_602616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602617: Call_DeleteVpcLink_602606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_602617.validator(path, query, header, formData, body)
  let scheme = call_602617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602617.url(scheme.get, call_602617.host, call_602617.base,
                         call_602617.route, valid.getOrDefault("path"))
  result = hook(call_602617, url, valid)

proc call*(call_602618: Call_DeleteVpcLink_602606; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_602619 = newJObject()
  add(path_602619, "vpclink_id", newJString(vpclinkId))
  result = call_602618.call(path_602619, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_602606(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_602607,
    base: "/", url: url_DeleteVpcLink_602608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_602636 = ref object of OpenApiRestCall_600410
proc url_FlushStageAuthorizersCache_602638(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_FlushStageAuthorizersCache_602637(path: JsonNode; query: JsonNode;
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
  var valid_602639 = path.getOrDefault("stage_name")
  valid_602639 = validateParameter(valid_602639, JString, required = true,
                                 default = nil)
  if valid_602639 != nil:
    section.add "stage_name", valid_602639
  var valid_602640 = path.getOrDefault("restapi_id")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = nil)
  if valid_602640 != nil:
    section.add "restapi_id", valid_602640
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
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Security-Token")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Security-Token", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Content-Sha256", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-SignedHeaders", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Credential")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Credential", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_FlushStageAuthorizersCache_602636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"))
  result = hook(call_602648, url, valid)

proc call*(call_602649: Call_FlushStageAuthorizersCache_602636; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_602650 = newJObject()
  add(path_602650, "stage_name", newJString(stageName))
  add(path_602650, "restapi_id", newJString(restapiId))
  result = call_602649.call(path_602650, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_602636(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_602637, base: "/",
    url: url_FlushStageAuthorizersCache_602638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_602651 = ref object of OpenApiRestCall_600410
proc url_FlushStageCache_602653(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_FlushStageCache_602652(path: JsonNode; query: JsonNode;
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
  var valid_602654 = path.getOrDefault("stage_name")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = nil)
  if valid_602654 != nil:
    section.add "stage_name", valid_602654
  var valid_602655 = path.getOrDefault("restapi_id")
  valid_602655 = validateParameter(valid_602655, JString, required = true,
                                 default = nil)
  if valid_602655 != nil:
    section.add "restapi_id", valid_602655
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
  var valid_602656 = header.getOrDefault("X-Amz-Date")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Date", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Security-Token")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Security-Token", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Content-Sha256", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Algorithm")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Algorithm", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-SignedHeaders", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Credential")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Credential", valid_602662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602663: Call_FlushStageCache_602651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_602663.validator(path, query, header, formData, body)
  let scheme = call_602663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602663.url(scheme.get, call_602663.host, call_602663.base,
                         call_602663.route, valid.getOrDefault("path"))
  result = hook(call_602663, url, valid)

proc call*(call_602664: Call_FlushStageCache_602651; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602665 = newJObject()
  add(path_602665, "stage_name", newJString(stageName))
  add(path_602665, "restapi_id", newJString(restapiId))
  result = call_602664.call(path_602665, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_602651(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_602652, base: "/", url: url_FlushStageCache_602653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_602681 = ref object of OpenApiRestCall_600410
proc url_GenerateClientCertificate_602683(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateClientCertificate_602682(path: JsonNode; query: JsonNode;
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
  var valid_602684 = header.getOrDefault("X-Amz-Date")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Date", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Content-Sha256", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Algorithm")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Algorithm", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Signature")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Signature", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-SignedHeaders", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Credential")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Credential", valid_602690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602692: Call_GenerateClientCertificate_602681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_602692.validator(path, query, header, formData, body)
  let scheme = call_602692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602692.url(scheme.get, call_602692.host, call_602692.base,
                         call_602692.route, valid.getOrDefault("path"))
  result = hook(call_602692, url, valid)

proc call*(call_602693: Call_GenerateClientCertificate_602681; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_602694 = newJObject()
  if body != nil:
    body_602694 = body
  result = call_602693.call(nil, nil, nil, nil, body_602694)

var generateClientCertificate* = Call_GenerateClientCertificate_602681(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_602682, base: "/",
    url: url_GenerateClientCertificate_602683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_602666 = ref object of OpenApiRestCall_600410
proc url_GetClientCertificates_602668(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetClientCertificates_602667(path: JsonNode; query: JsonNode;
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
  var valid_602669 = query.getOrDefault("position")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "position", valid_602669
  var valid_602670 = query.getOrDefault("limit")
  valid_602670 = validateParameter(valid_602670, JInt, required = false, default = nil)
  if valid_602670 != nil:
    section.add "limit", valid_602670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602671 = header.getOrDefault("X-Amz-Date")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Date", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Security-Token")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Security-Token", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Content-Sha256", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Algorithm")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Algorithm", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Signature")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Signature", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-SignedHeaders", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602678: Call_GetClientCertificates_602666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_602678.validator(path, query, header, formData, body)
  let scheme = call_602678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602678.url(scheme.get, call_602678.host, call_602678.base,
                         call_602678.route, valid.getOrDefault("path"))
  result = hook(call_602678, url, valid)

proc call*(call_602679: Call_GetClientCertificates_602666; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_602680 = newJObject()
  add(query_602680, "position", newJString(position))
  add(query_602680, "limit", newJInt(limit))
  result = call_602679.call(nil, query_602680, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_602666(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_602667, base: "/",
    url: url_GetClientCertificates_602668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_602695 = ref object of OpenApiRestCall_600410
proc url_GetAccount_602697(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccount_602696(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602698 = header.getOrDefault("X-Amz-Date")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Date", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Security-Token")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Security-Token", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Content-Sha256", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Algorithm")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Algorithm", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Signature")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Signature", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-SignedHeaders", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Credential")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Credential", valid_602704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_GetAccount_602695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"))
  result = hook(call_602705, url, valid)

proc call*(call_602706: Call_GetAccount_602695): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_602706.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_602695(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_602696,
                                      base: "/", url: url_GetAccount_602697,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_602707 = ref object of OpenApiRestCall_600410
proc url_UpdateAccount_602709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAccount_602708(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602710 = header.getOrDefault("X-Amz-Date")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Date", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Security-Token")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Security-Token", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Content-Sha256", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Algorithm")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Algorithm", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Signature")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Signature", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Credential")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Credential", valid_602716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602718: Call_UpdateAccount_602707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_602718.validator(path, query, header, formData, body)
  let scheme = call_602718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602718.url(scheme.get, call_602718.host, call_602718.base,
                         call_602718.route, valid.getOrDefault("path"))
  result = hook(call_602718, url, valid)

proc call*(call_602719: Call_UpdateAccount_602707; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_602720 = newJObject()
  if body != nil:
    body_602720 = body
  result = call_602719.call(nil, nil, nil, nil, body_602720)

var updateAccount* = Call_UpdateAccount_602707(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_602708, base: "/", url: url_UpdateAccount_602709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_602721 = ref object of OpenApiRestCall_600410
proc url_GetExport_602723(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetExport_602722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602724 = path.getOrDefault("export_type")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = nil)
  if valid_602724 != nil:
    section.add "export_type", valid_602724
  var valid_602725 = path.getOrDefault("stage_name")
  valid_602725 = validateParameter(valid_602725, JString, required = true,
                                 default = nil)
  if valid_602725 != nil:
    section.add "stage_name", valid_602725
  var valid_602726 = path.getOrDefault("restapi_id")
  valid_602726 = validateParameter(valid_602726, JString, required = true,
                                 default = nil)
  if valid_602726 != nil:
    section.add "restapi_id", valid_602726
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_602727 = query.getOrDefault("parameters.0.value")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "parameters.0.value", valid_602727
  var valid_602728 = query.getOrDefault("parameters.2.value")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "parameters.2.value", valid_602728
  var valid_602729 = query.getOrDefault("parameters.1.key")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "parameters.1.key", valid_602729
  var valid_602730 = query.getOrDefault("parameters.0.key")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "parameters.0.key", valid_602730
  var valid_602731 = query.getOrDefault("parameters.2.key")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "parameters.2.key", valid_602731
  var valid_602732 = query.getOrDefault("parameters.1.value")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "parameters.1.value", valid_602732
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
  var valid_602733 = header.getOrDefault("X-Amz-Date")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Date", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Security-Token")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Security-Token", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Content-Sha256", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Algorithm")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Algorithm", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Signature")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Signature", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-SignedHeaders", valid_602738
  var valid_602739 = header.getOrDefault("Accept")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "Accept", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Credential")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Credential", valid_602740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602741: Call_GetExport_602721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_602741.validator(path, query, header, formData, body)
  let scheme = call_602741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602741.url(scheme.get, call_602741.host, call_602741.base,
                         call_602741.route, valid.getOrDefault("path"))
  result = hook(call_602741, url, valid)

proc call*(call_602742: Call_GetExport_602721; exportType: string; stageName: string;
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
  var path_602743 = newJObject()
  var query_602744 = newJObject()
  add(query_602744, "parameters.0.value", newJString(parameters0Value))
  add(query_602744, "parameters.2.value", newJString(parameters2Value))
  add(query_602744, "parameters.1.key", newJString(parameters1Key))
  add(query_602744, "parameters.0.key", newJString(parameters0Key))
  add(path_602743, "export_type", newJString(exportType))
  add(query_602744, "parameters.2.key", newJString(parameters2Key))
  add(path_602743, "stage_name", newJString(stageName))
  add(query_602744, "parameters.1.value", newJString(parameters1Value))
  add(path_602743, "restapi_id", newJString(restapiId))
  result = call_602742.call(path_602743, query_602744, nil, nil, nil)

var getExport* = Call_GetExport_602721(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_602722,
                                    base: "/", url: url_GetExport_602723,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_602745 = ref object of OpenApiRestCall_600410
proc url_GetGatewayResponses_602747(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGatewayResponses_602746(path: JsonNode; query: JsonNode;
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
  var valid_602748 = path.getOrDefault("restapi_id")
  valid_602748 = validateParameter(valid_602748, JString, required = true,
                                 default = nil)
  if valid_602748 != nil:
    section.add "restapi_id", valid_602748
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_602749 = query.getOrDefault("position")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "position", valid_602749
  var valid_602750 = query.getOrDefault("limit")
  valid_602750 = validateParameter(valid_602750, JInt, required = false, default = nil)
  if valid_602750 != nil:
    section.add "limit", valid_602750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602751 = header.getOrDefault("X-Amz-Date")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Date", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Security-Token")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Security-Token", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Content-Sha256", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Algorithm")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Algorithm", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Signature")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Signature", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-SignedHeaders", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Credential")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Credential", valid_602757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602758: Call_GetGatewayResponses_602745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_602758.validator(path, query, header, formData, body)
  let scheme = call_602758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602758.url(scheme.get, call_602758.host, call_602758.base,
                         call_602758.route, valid.getOrDefault("path"))
  result = hook(call_602758, url, valid)

proc call*(call_602759: Call_GetGatewayResponses_602745; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602760 = newJObject()
  var query_602761 = newJObject()
  add(query_602761, "position", newJString(position))
  add(query_602761, "limit", newJInt(limit))
  add(path_602760, "restapi_id", newJString(restapiId))
  result = call_602759.call(path_602760, query_602761, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_602745(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_602746, base: "/",
    url: url_GetGatewayResponses_602747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_602762 = ref object of OpenApiRestCall_600410
proc url_GetModelTemplate_602764(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetModelTemplate_602763(path: JsonNode; query: JsonNode;
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
  var valid_602765 = path.getOrDefault("model_name")
  valid_602765 = validateParameter(valid_602765, JString, required = true,
                                 default = nil)
  if valid_602765 != nil:
    section.add "model_name", valid_602765
  var valid_602766 = path.getOrDefault("restapi_id")
  valid_602766 = validateParameter(valid_602766, JString, required = true,
                                 default = nil)
  if valid_602766 != nil:
    section.add "restapi_id", valid_602766
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
  var valid_602767 = header.getOrDefault("X-Amz-Date")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Date", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Security-Token")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Security-Token", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Content-Sha256", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Algorithm")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Algorithm", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Signature")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Signature", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-SignedHeaders", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Credential")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Credential", valid_602773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602774: Call_GetModelTemplate_602762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_602774.validator(path, query, header, formData, body)
  let scheme = call_602774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602774.url(scheme.get, call_602774.host, call_602774.base,
                         call_602774.route, valid.getOrDefault("path"))
  result = hook(call_602774, url, valid)

proc call*(call_602775: Call_GetModelTemplate_602762; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_602776 = newJObject()
  add(path_602776, "model_name", newJString(modelName))
  add(path_602776, "restapi_id", newJString(restapiId))
  result = call_602775.call(path_602776, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_602762(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_602763, base: "/",
    url: url_GetModelTemplate_602764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_602777 = ref object of OpenApiRestCall_600410
proc url_GetResources_602779(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetResources_602778(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602780 = path.getOrDefault("restapi_id")
  valid_602780 = validateParameter(valid_602780, JString, required = true,
                                 default = nil)
  if valid_602780 != nil:
    section.add "restapi_id", valid_602780
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_602781 = query.getOrDefault("embed")
  valid_602781 = validateParameter(valid_602781, JArray, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "embed", valid_602781
  var valid_602782 = query.getOrDefault("position")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "position", valid_602782
  var valid_602783 = query.getOrDefault("limit")
  valid_602783 = validateParameter(valid_602783, JInt, required = false, default = nil)
  if valid_602783 != nil:
    section.add "limit", valid_602783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602784 = header.getOrDefault("X-Amz-Date")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Date", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Security-Token")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Security-Token", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Content-Sha256", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Algorithm")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Algorithm", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Signature")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Signature", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-SignedHeaders", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Credential")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Credential", valid_602790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602791: Call_GetResources_602777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_602791.validator(path, query, header, formData, body)
  let scheme = call_602791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602791.url(scheme.get, call_602791.host, call_602791.base,
                         call_602791.route, valid.getOrDefault("path"))
  result = hook(call_602791, url, valid)

proc call*(call_602792: Call_GetResources_602777; restapiId: string;
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
  var path_602793 = newJObject()
  var query_602794 = newJObject()
  if embed != nil:
    query_602794.add "embed", embed
  add(query_602794, "position", newJString(position))
  add(query_602794, "limit", newJInt(limit))
  add(path_602793, "restapi_id", newJString(restapiId))
  result = call_602792.call(path_602793, query_602794, nil, nil, nil)

var getResources* = Call_GetResources_602777(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_602778,
    base: "/", url: url_GetResources_602779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_602795 = ref object of OpenApiRestCall_600410
proc url_GetSdk_602797(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSdk_602796(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602798 = path.getOrDefault("sdk_type")
  valid_602798 = validateParameter(valid_602798, JString, required = true,
                                 default = nil)
  if valid_602798 != nil:
    section.add "sdk_type", valid_602798
  var valid_602799 = path.getOrDefault("stage_name")
  valid_602799 = validateParameter(valid_602799, JString, required = true,
                                 default = nil)
  if valid_602799 != nil:
    section.add "stage_name", valid_602799
  var valid_602800 = path.getOrDefault("restapi_id")
  valid_602800 = validateParameter(valid_602800, JString, required = true,
                                 default = nil)
  if valid_602800 != nil:
    section.add "restapi_id", valid_602800
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_602801 = query.getOrDefault("parameters.0.value")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "parameters.0.value", valid_602801
  var valid_602802 = query.getOrDefault("parameters.2.value")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "parameters.2.value", valid_602802
  var valid_602803 = query.getOrDefault("parameters.1.key")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "parameters.1.key", valid_602803
  var valid_602804 = query.getOrDefault("parameters.0.key")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "parameters.0.key", valid_602804
  var valid_602805 = query.getOrDefault("parameters.2.key")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "parameters.2.key", valid_602805
  var valid_602806 = query.getOrDefault("parameters.1.value")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "parameters.1.value", valid_602806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602807 = header.getOrDefault("X-Amz-Date")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Date", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Security-Token")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Security-Token", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Content-Sha256", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Algorithm")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Algorithm", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Signature")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Signature", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-SignedHeaders", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Credential")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Credential", valid_602813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602814: Call_GetSdk_602795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_602814.validator(path, query, header, formData, body)
  let scheme = call_602814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602814.url(scheme.get, call_602814.host, call_602814.base,
                         call_602814.route, valid.getOrDefault("path"))
  result = hook(call_602814, url, valid)

proc call*(call_602815: Call_GetSdk_602795; sdkType: string; stageName: string;
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
  var path_602816 = newJObject()
  var query_602817 = newJObject()
  add(path_602816, "sdk_type", newJString(sdkType))
  add(query_602817, "parameters.0.value", newJString(parameters0Value))
  add(query_602817, "parameters.2.value", newJString(parameters2Value))
  add(query_602817, "parameters.1.key", newJString(parameters1Key))
  add(query_602817, "parameters.0.key", newJString(parameters0Key))
  add(query_602817, "parameters.2.key", newJString(parameters2Key))
  add(path_602816, "stage_name", newJString(stageName))
  add(query_602817, "parameters.1.value", newJString(parameters1Value))
  add(path_602816, "restapi_id", newJString(restapiId))
  result = call_602815.call(path_602816, query_602817, nil, nil, nil)

var getSdk* = Call_GetSdk_602795(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_602796, base: "/",
                              url: url_GetSdk_602797,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_602818 = ref object of OpenApiRestCall_600410
proc url_GetSdkType_602820(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "sdktype_id" in path, "`sdktype_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/sdktypes/"),
               (kind: VariableSegment, value: "sdktype_id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSdkType_602819(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_602821 = path.getOrDefault("sdktype_id")
  valid_602821 = validateParameter(valid_602821, JString, required = true,
                                 default = nil)
  if valid_602821 != nil:
    section.add "sdktype_id", valid_602821
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
  var valid_602822 = header.getOrDefault("X-Amz-Date")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Date", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Security-Token")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Security-Token", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Content-Sha256", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Algorithm")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Algorithm", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Signature")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Signature", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-SignedHeaders", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Credential")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Credential", valid_602828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602829: Call_GetSdkType_602818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602829.validator(path, query, header, formData, body)
  let scheme = call_602829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602829.url(scheme.get, call_602829.host, call_602829.base,
                         call_602829.route, valid.getOrDefault("path"))
  result = hook(call_602829, url, valid)

proc call*(call_602830: Call_GetSdkType_602818; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_602831 = newJObject()
  add(path_602831, "sdktype_id", newJString(sdktypeId))
  result = call_602830.call(path_602831, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_602818(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_602819,
                                      base: "/", url: url_GetSdkType_602820,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_602832 = ref object of OpenApiRestCall_600410
proc url_GetSdkTypes_602834(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSdkTypes_602833(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602835 = query.getOrDefault("position")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "position", valid_602835
  var valid_602836 = query.getOrDefault("limit")
  valid_602836 = validateParameter(valid_602836, JInt, required = false, default = nil)
  if valid_602836 != nil:
    section.add "limit", valid_602836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602837 = header.getOrDefault("X-Amz-Date")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Date", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Security-Token")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Security-Token", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Content-Sha256", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-Algorithm")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Algorithm", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-Signature")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Signature", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-SignedHeaders", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Credential")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Credential", valid_602843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602844: Call_GetSdkTypes_602832; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602844.validator(path, query, header, formData, body)
  let scheme = call_602844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602844.url(scheme.get, call_602844.host, call_602844.base,
                         call_602844.route, valid.getOrDefault("path"))
  result = hook(call_602844, url, valid)

proc call*(call_602845: Call_GetSdkTypes_602832; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_602846 = newJObject()
  add(query_602846, "position", newJString(position))
  add(query_602846, "limit", newJInt(limit))
  result = call_602845.call(nil, query_602846, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_602832(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_602833,
                                        base: "/", url: url_GetSdkTypes_602834,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602864 = ref object of OpenApiRestCall_600410
proc url_TagResource_602866(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_602865(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602867 = path.getOrDefault("resource_arn")
  valid_602867 = validateParameter(valid_602867, JString, required = true,
                                 default = nil)
  if valid_602867 != nil:
    section.add "resource_arn", valid_602867
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
  var valid_602868 = header.getOrDefault("X-Amz-Date")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Date", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Security-Token")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Security-Token", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Content-Sha256", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Algorithm")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Algorithm", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-SignedHeaders", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Credential")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Credential", valid_602874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602876: Call_TagResource_602864; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_602876.validator(path, query, header, formData, body)
  let scheme = call_602876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602876.url(scheme.get, call_602876.host, call_602876.base,
                         call_602876.route, valid.getOrDefault("path"))
  result = hook(call_602876, url, valid)

proc call*(call_602877: Call_TagResource_602864; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_602878 = newJObject()
  var body_602879 = newJObject()
  add(path_602878, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_602879 = body
  result = call_602877.call(path_602878, nil, nil, nil, body_602879)

var tagResource* = Call_TagResource_602864(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_602865,
                                        base: "/", url: url_TagResource_602866,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_602847 = ref object of OpenApiRestCall_600410
proc url_GetTags_602849(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource_arn" in path, "`resource_arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource_arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetTags_602848(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602850 = path.getOrDefault("resource_arn")
  valid_602850 = validateParameter(valid_602850, JString, required = true,
                                 default = nil)
  if valid_602850 != nil:
    section.add "resource_arn", valid_602850
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_602851 = query.getOrDefault("position")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "position", valid_602851
  var valid_602852 = query.getOrDefault("limit")
  valid_602852 = validateParameter(valid_602852, JInt, required = false, default = nil)
  if valid_602852 != nil:
    section.add "limit", valid_602852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602853 = header.getOrDefault("X-Amz-Date")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-Date", valid_602853
  var valid_602854 = header.getOrDefault("X-Amz-Security-Token")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "X-Amz-Security-Token", valid_602854
  var valid_602855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-Content-Sha256", valid_602855
  var valid_602856 = header.getOrDefault("X-Amz-Algorithm")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Algorithm", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Signature")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Signature", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-SignedHeaders", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Credential")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Credential", valid_602859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602860: Call_GetTags_602847; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_602860.validator(path, query, header, formData, body)
  let scheme = call_602860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602860.url(scheme.get, call_602860.host, call_602860.base,
                         call_602860.route, valid.getOrDefault("path"))
  result = hook(call_602860, url, valid)

proc call*(call_602861: Call_GetTags_602847; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_602862 = newJObject()
  var query_602863 = newJObject()
  add(path_602862, "resource_arn", newJString(resourceArn))
  add(query_602863, "position", newJString(position))
  add(query_602863, "limit", newJInt(limit))
  result = call_602861.call(path_602862, query_602863, nil, nil, nil)

var getTags* = Call_GetTags_602847(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_602848, base: "/",
                                url: url_GetTags_602849,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_602880 = ref object of OpenApiRestCall_600410
proc url_GetUsage_602882(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUsage_602881(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602883 = path.getOrDefault("usageplanId")
  valid_602883 = validateParameter(valid_602883, JString, required = true,
                                 default = nil)
  if valid_602883 != nil:
    section.add "usageplanId", valid_602883
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
  var valid_602884 = query.getOrDefault("endDate")
  valid_602884 = validateParameter(valid_602884, JString, required = true,
                                 default = nil)
  if valid_602884 != nil:
    section.add "endDate", valid_602884
  var valid_602885 = query.getOrDefault("startDate")
  valid_602885 = validateParameter(valid_602885, JString, required = true,
                                 default = nil)
  if valid_602885 != nil:
    section.add "startDate", valid_602885
  var valid_602886 = query.getOrDefault("keyId")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "keyId", valid_602886
  var valid_602887 = query.getOrDefault("position")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "position", valid_602887
  var valid_602888 = query.getOrDefault("limit")
  valid_602888 = validateParameter(valid_602888, JInt, required = false, default = nil)
  if valid_602888 != nil:
    section.add "limit", valid_602888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602889 = header.getOrDefault("X-Amz-Date")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Date", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Security-Token")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Security-Token", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Content-Sha256", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Algorithm")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Algorithm", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Signature")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Signature", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-SignedHeaders", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Credential")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Credential", valid_602895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602896: Call_GetUsage_602880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_602896.validator(path, query, header, formData, body)
  let scheme = call_602896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602896.url(scheme.get, call_602896.host, call_602896.base,
                         call_602896.route, valid.getOrDefault("path"))
  result = hook(call_602896, url, valid)

proc call*(call_602897: Call_GetUsage_602880; endDate: string; startDate: string;
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
  var path_602898 = newJObject()
  var query_602899 = newJObject()
  add(query_602899, "endDate", newJString(endDate))
  add(query_602899, "startDate", newJString(startDate))
  add(path_602898, "usageplanId", newJString(usageplanId))
  add(query_602899, "keyId", newJString(keyId))
  add(query_602899, "position", newJString(position))
  add(query_602899, "limit", newJInt(limit))
  result = call_602897.call(path_602898, query_602899, nil, nil, nil)

var getUsage* = Call_GetUsage_602880(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_602881, base: "/",
                                  url: url_GetUsage_602882,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_602900 = ref object of OpenApiRestCall_600410
proc url_ImportApiKeys_602902(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportApiKeys_602901(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602903 = query.getOrDefault("mode")
  valid_602903 = validateParameter(valid_602903, JString, required = true,
                                 default = newJString("import"))
  if valid_602903 != nil:
    section.add "mode", valid_602903
  var valid_602904 = query.getOrDefault("failonwarnings")
  valid_602904 = validateParameter(valid_602904, JBool, required = false, default = nil)
  if valid_602904 != nil:
    section.add "failonwarnings", valid_602904
  var valid_602905 = query.getOrDefault("format")
  valid_602905 = validateParameter(valid_602905, JString, required = true,
                                 default = newJString("csv"))
  if valid_602905 != nil:
    section.add "format", valid_602905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602906 = header.getOrDefault("X-Amz-Date")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Date", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Security-Token")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Security-Token", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Content-Sha256", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Algorithm")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Algorithm", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Signature")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Signature", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-SignedHeaders", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Credential")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Credential", valid_602912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_ImportApiKeys_602900; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602915: Call_ImportApiKeys_602900; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_602916 = newJObject()
  var body_602917 = newJObject()
  add(query_602916, "mode", newJString(mode))
  add(query_602916, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_602917 = body
  add(query_602916, "format", newJString(format))
  result = call_602915.call(nil, query_602916, nil, nil, body_602917)

var importApiKeys* = Call_ImportApiKeys_602900(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_602901,
    base: "/", url: url_ImportApiKeys_602902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_602918 = ref object of OpenApiRestCall_600410
proc url_ImportRestApi_602920(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportRestApi_602919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602921 = query.getOrDefault("parameters.0.value")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "parameters.0.value", valid_602921
  var valid_602922 = query.getOrDefault("parameters.2.value")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "parameters.2.value", valid_602922
  var valid_602923 = query.getOrDefault("parameters.1.key")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "parameters.1.key", valid_602923
  var valid_602924 = query.getOrDefault("parameters.0.key")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "parameters.0.key", valid_602924
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_602925 = query.getOrDefault("mode")
  valid_602925 = validateParameter(valid_602925, JString, required = true,
                                 default = newJString("import"))
  if valid_602925 != nil:
    section.add "mode", valid_602925
  var valid_602926 = query.getOrDefault("parameters.2.key")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "parameters.2.key", valid_602926
  var valid_602927 = query.getOrDefault("failonwarnings")
  valid_602927 = validateParameter(valid_602927, JBool, required = false, default = nil)
  if valid_602927 != nil:
    section.add "failonwarnings", valid_602927
  var valid_602928 = query.getOrDefault("parameters.1.value")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "parameters.1.value", valid_602928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602929 = header.getOrDefault("X-Amz-Date")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Date", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Security-Token")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Security-Token", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Content-Sha256", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Algorithm")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Algorithm", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Signature")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Signature", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-SignedHeaders", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Credential")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Credential", valid_602935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602937: Call_ImportRestApi_602918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_602937.validator(path, query, header, formData, body)
  let scheme = call_602937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602937.url(scheme.get, call_602937.host, call_602937.base,
                         call_602937.route, valid.getOrDefault("path"))
  result = hook(call_602937, url, valid)

proc call*(call_602938: Call_ImportRestApi_602918; body: JsonNode;
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
  var query_602939 = newJObject()
  var body_602940 = newJObject()
  add(query_602939, "parameters.0.value", newJString(parameters0Value))
  add(query_602939, "parameters.2.value", newJString(parameters2Value))
  add(query_602939, "parameters.1.key", newJString(parameters1Key))
  add(query_602939, "parameters.0.key", newJString(parameters0Key))
  add(query_602939, "mode", newJString(mode))
  add(query_602939, "parameters.2.key", newJString(parameters2Key))
  add(query_602939, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_602940 = body
  add(query_602939, "parameters.1.value", newJString(parameters1Value))
  result = call_602938.call(nil, query_602939, nil, nil, body_602940)

var importRestApi* = Call_ImportRestApi_602918(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_602919,
    base: "/", url: url_ImportRestApi_602920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602941 = ref object of OpenApiRestCall_600410
proc url_UntagResource_602943(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_602942(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602944 = path.getOrDefault("resource_arn")
  valid_602944 = validateParameter(valid_602944, JString, required = true,
                                 default = nil)
  if valid_602944 != nil:
    section.add "resource_arn", valid_602944
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602945 = query.getOrDefault("tagKeys")
  valid_602945 = validateParameter(valid_602945, JArray, required = true, default = nil)
  if valid_602945 != nil:
    section.add "tagKeys", valid_602945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602946 = header.getOrDefault("X-Amz-Date")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Date", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Security-Token")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Security-Token", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Content-Sha256", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Algorithm")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Algorithm", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Signature")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Signature", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-SignedHeaders", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Credential")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Credential", valid_602952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602953: Call_UntagResource_602941; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_602953.validator(path, query, header, formData, body)
  let scheme = call_602953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602953.url(scheme.get, call_602953.host, call_602953.base,
                         call_602953.route, valid.getOrDefault("path"))
  result = hook(call_602953, url, valid)

proc call*(call_602954: Call_UntagResource_602941; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_602955 = newJObject()
  var query_602956 = newJObject()
  add(path_602955, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602956.add "tagKeys", tagKeys
  result = call_602954.call(path_602955, query_602956, nil, nil, nil)

var untagResource* = Call_UntagResource_602941(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_602942,
    base: "/", url: url_UntagResource_602943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_602957 = ref object of OpenApiRestCall_600410
proc url_UpdateUsage_602959(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUsage_602958(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602960 = path.getOrDefault("keyId")
  valid_602960 = validateParameter(valid_602960, JString, required = true,
                                 default = nil)
  if valid_602960 != nil:
    section.add "keyId", valid_602960
  var valid_602961 = path.getOrDefault("usageplanId")
  valid_602961 = validateParameter(valid_602961, JString, required = true,
                                 default = nil)
  if valid_602961 != nil:
    section.add "usageplanId", valid_602961
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
  var valid_602962 = header.getOrDefault("X-Amz-Date")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Date", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Security-Token")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Security-Token", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Content-Sha256", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Algorithm")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Algorithm", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Signature")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Signature", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-SignedHeaders", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Credential")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Credential", valid_602968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602970: Call_UpdateUsage_602957; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_602970.validator(path, query, header, formData, body)
  let scheme = call_602970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602970.url(scheme.get, call_602970.host, call_602970.base,
                         call_602970.route, valid.getOrDefault("path"))
  result = hook(call_602970, url, valid)

proc call*(call_602971: Call_UpdateUsage_602957; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_602972 = newJObject()
  var body_602973 = newJObject()
  add(path_602972, "keyId", newJString(keyId))
  add(path_602972, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_602973 = body
  result = call_602971.call(path_602972, nil, nil, nil, body_602973)

var updateUsage* = Call_UpdateUsage_602957(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_602958,
                                        base: "/", url: url_UpdateUsage_602959,
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
