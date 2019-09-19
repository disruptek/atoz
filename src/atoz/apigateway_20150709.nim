
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

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_773177 = ref object of OpenApiRestCall_772581
proc url_CreateApiKey_773179(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApiKey_773178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773180 = header.getOrDefault("X-Amz-Date")
  valid_773180 = validateParameter(valid_773180, JString, required = false,
                                 default = nil)
  if valid_773180 != nil:
    section.add "X-Amz-Date", valid_773180
  var valid_773181 = header.getOrDefault("X-Amz-Security-Token")
  valid_773181 = validateParameter(valid_773181, JString, required = false,
                                 default = nil)
  if valid_773181 != nil:
    section.add "X-Amz-Security-Token", valid_773181
  var valid_773182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773182 = validateParameter(valid_773182, JString, required = false,
                                 default = nil)
  if valid_773182 != nil:
    section.add "X-Amz-Content-Sha256", valid_773182
  var valid_773183 = header.getOrDefault("X-Amz-Algorithm")
  valid_773183 = validateParameter(valid_773183, JString, required = false,
                                 default = nil)
  if valid_773183 != nil:
    section.add "X-Amz-Algorithm", valid_773183
  var valid_773184 = header.getOrDefault("X-Amz-Signature")
  valid_773184 = validateParameter(valid_773184, JString, required = false,
                                 default = nil)
  if valid_773184 != nil:
    section.add "X-Amz-Signature", valid_773184
  var valid_773185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773185 = validateParameter(valid_773185, JString, required = false,
                                 default = nil)
  if valid_773185 != nil:
    section.add "X-Amz-SignedHeaders", valid_773185
  var valid_773186 = header.getOrDefault("X-Amz-Credential")
  valid_773186 = validateParameter(valid_773186, JString, required = false,
                                 default = nil)
  if valid_773186 != nil:
    section.add "X-Amz-Credential", valid_773186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773188: Call_CreateApiKey_773177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_773188.validator(path, query, header, formData, body)
  let scheme = call_773188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773188.url(scheme.get, call_773188.host, call_773188.base,
                         call_773188.route, valid.getOrDefault("path"))
  result = hook(call_773188, url, valid)

proc call*(call_773189: Call_CreateApiKey_773177; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_773190 = newJObject()
  if body != nil:
    body_773190 = body
  result = call_773189.call(nil, nil, nil, nil, body_773190)

var createApiKey* = Call_CreateApiKey_773177(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_773178, base: "/", url: url_CreateApiKey_773179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_772917 = ref object of OpenApiRestCall_772581
proc url_GetApiKeys_772919(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApiKeys_772918(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773031 = query.getOrDefault("customerId")
  valid_773031 = validateParameter(valid_773031, JString, required = false,
                                 default = nil)
  if valid_773031 != nil:
    section.add "customerId", valid_773031
  var valid_773032 = query.getOrDefault("includeValues")
  valid_773032 = validateParameter(valid_773032, JBool, required = false, default = nil)
  if valid_773032 != nil:
    section.add "includeValues", valid_773032
  var valid_773033 = query.getOrDefault("name")
  valid_773033 = validateParameter(valid_773033, JString, required = false,
                                 default = nil)
  if valid_773033 != nil:
    section.add "name", valid_773033
  var valid_773034 = query.getOrDefault("position")
  valid_773034 = validateParameter(valid_773034, JString, required = false,
                                 default = nil)
  if valid_773034 != nil:
    section.add "position", valid_773034
  var valid_773035 = query.getOrDefault("limit")
  valid_773035 = validateParameter(valid_773035, JInt, required = false, default = nil)
  if valid_773035 != nil:
    section.add "limit", valid_773035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773036 = header.getOrDefault("X-Amz-Date")
  valid_773036 = validateParameter(valid_773036, JString, required = false,
                                 default = nil)
  if valid_773036 != nil:
    section.add "X-Amz-Date", valid_773036
  var valid_773037 = header.getOrDefault("X-Amz-Security-Token")
  valid_773037 = validateParameter(valid_773037, JString, required = false,
                                 default = nil)
  if valid_773037 != nil:
    section.add "X-Amz-Security-Token", valid_773037
  var valid_773038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-Content-Sha256", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Algorithm")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Algorithm", valid_773039
  var valid_773040 = header.getOrDefault("X-Amz-Signature")
  valid_773040 = validateParameter(valid_773040, JString, required = false,
                                 default = nil)
  if valid_773040 != nil:
    section.add "X-Amz-Signature", valid_773040
  var valid_773041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773041 = validateParameter(valid_773041, JString, required = false,
                                 default = nil)
  if valid_773041 != nil:
    section.add "X-Amz-SignedHeaders", valid_773041
  var valid_773042 = header.getOrDefault("X-Amz-Credential")
  valid_773042 = validateParameter(valid_773042, JString, required = false,
                                 default = nil)
  if valid_773042 != nil:
    section.add "X-Amz-Credential", valid_773042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773065: Call_GetApiKeys_772917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_773065.validator(path, query, header, formData, body)
  let scheme = call_773065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773065.url(scheme.get, call_773065.host, call_773065.base,
                         call_773065.route, valid.getOrDefault("path"))
  result = hook(call_773065, url, valid)

proc call*(call_773136: Call_GetApiKeys_772917; customerId: string = "";
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
  var query_773137 = newJObject()
  add(query_773137, "customerId", newJString(customerId))
  add(query_773137, "includeValues", newJBool(includeValues))
  add(query_773137, "name", newJString(name))
  add(query_773137, "position", newJString(position))
  add(query_773137, "limit", newJInt(limit))
  result = call_773136.call(nil, query_773137, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_772917(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_772918,
                                      base: "/", url: url_GetApiKeys_772919,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_773222 = ref object of OpenApiRestCall_772581
proc url_CreateAuthorizer_773224(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_773223(path: JsonNode; query: JsonNode;
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
  var valid_773225 = path.getOrDefault("restapi_id")
  valid_773225 = validateParameter(valid_773225, JString, required = true,
                                 default = nil)
  if valid_773225 != nil:
    section.add "restapi_id", valid_773225
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773226 = header.getOrDefault("X-Amz-Date")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Date", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Security-Token")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Security-Token", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Content-Sha256", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Algorithm")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Algorithm", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Signature")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Signature", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-SignedHeaders", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Credential")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Credential", valid_773232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773234: Call_CreateAuthorizer_773222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_773234.validator(path, query, header, formData, body)
  let scheme = call_773234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773234.url(scheme.get, call_773234.host, call_773234.base,
                         call_773234.route, valid.getOrDefault("path"))
  result = hook(call_773234, url, valid)

proc call*(call_773235: Call_CreateAuthorizer_773222; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773236 = newJObject()
  var body_773237 = newJObject()
  if body != nil:
    body_773237 = body
  add(path_773236, "restapi_id", newJString(restapiId))
  result = call_773235.call(path_773236, nil, nil, nil, body_773237)

var createAuthorizer* = Call_CreateAuthorizer_773222(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_773223, base: "/",
    url: url_CreateAuthorizer_773224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_773191 = ref object of OpenApiRestCall_772581
proc url_GetAuthorizers_773193(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_773192(path: JsonNode; query: JsonNode;
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
  var valid_773208 = path.getOrDefault("restapi_id")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = nil)
  if valid_773208 != nil:
    section.add "restapi_id", valid_773208
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773209 = query.getOrDefault("position")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "position", valid_773209
  var valid_773210 = query.getOrDefault("limit")
  valid_773210 = validateParameter(valid_773210, JInt, required = false, default = nil)
  if valid_773210 != nil:
    section.add "limit", valid_773210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773211 = header.getOrDefault("X-Amz-Date")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Date", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Security-Token")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Security-Token", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Content-Sha256", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Algorithm")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Algorithm", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Signature")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Signature", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-SignedHeaders", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Credential")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Credential", valid_773217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773218: Call_GetAuthorizers_773191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_773218.validator(path, query, header, formData, body)
  let scheme = call_773218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773218.url(scheme.get, call_773218.host, call_773218.base,
                         call_773218.route, valid.getOrDefault("path"))
  result = hook(call_773218, url, valid)

proc call*(call_773219: Call_GetAuthorizers_773191; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773220 = newJObject()
  var query_773221 = newJObject()
  add(query_773221, "position", newJString(position))
  add(query_773221, "limit", newJInt(limit))
  add(path_773220, "restapi_id", newJString(restapiId))
  result = call_773219.call(path_773220, query_773221, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_773191(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_773192, base: "/", url: url_GetAuthorizers_773193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_773255 = ref object of OpenApiRestCall_772581
proc url_CreateBasePathMapping_773257(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_773256(path: JsonNode; query: JsonNode;
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
  var valid_773258 = path.getOrDefault("domain_name")
  valid_773258 = validateParameter(valid_773258, JString, required = true,
                                 default = nil)
  if valid_773258 != nil:
    section.add "domain_name", valid_773258
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773259 = header.getOrDefault("X-Amz-Date")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Date", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Security-Token")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Security-Token", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Content-Sha256", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Algorithm")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Algorithm", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Signature")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Signature", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-SignedHeaders", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Credential")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Credential", valid_773265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773267: Call_CreateBasePathMapping_773255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_773267.validator(path, query, header, formData, body)
  let scheme = call_773267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773267.url(scheme.get, call_773267.host, call_773267.base,
                         call_773267.route, valid.getOrDefault("path"))
  result = hook(call_773267, url, valid)

proc call*(call_773268: Call_CreateBasePathMapping_773255; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_773269 = newJObject()
  var body_773270 = newJObject()
  add(path_773269, "domain_name", newJString(domainName))
  if body != nil:
    body_773270 = body
  result = call_773268.call(path_773269, nil, nil, nil, body_773270)

var createBasePathMapping* = Call_CreateBasePathMapping_773255(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_773256, base: "/",
    url: url_CreateBasePathMapping_773257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_773238 = ref object of OpenApiRestCall_772581
proc url_GetBasePathMappings_773240(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_773239(path: JsonNode; query: JsonNode;
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
  var valid_773241 = path.getOrDefault("domain_name")
  valid_773241 = validateParameter(valid_773241, JString, required = true,
                                 default = nil)
  if valid_773241 != nil:
    section.add "domain_name", valid_773241
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773242 = query.getOrDefault("position")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "position", valid_773242
  var valid_773243 = query.getOrDefault("limit")
  valid_773243 = validateParameter(valid_773243, JInt, required = false, default = nil)
  if valid_773243 != nil:
    section.add "limit", valid_773243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773244 = header.getOrDefault("X-Amz-Date")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Date", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Security-Token")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Security-Token", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Content-Sha256", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Algorithm")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Algorithm", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Signature")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Signature", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-SignedHeaders", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Credential")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Credential", valid_773250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773251: Call_GetBasePathMappings_773238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_773251.validator(path, query, header, formData, body)
  let scheme = call_773251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773251.url(scheme.get, call_773251.host, call_773251.base,
                         call_773251.route, valid.getOrDefault("path"))
  result = hook(call_773251, url, valid)

proc call*(call_773252: Call_GetBasePathMappings_773238; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_773253 = newJObject()
  var query_773254 = newJObject()
  add(path_773253, "domain_name", newJString(domainName))
  add(query_773254, "position", newJString(position))
  add(query_773254, "limit", newJInt(limit))
  result = call_773252.call(path_773253, query_773254, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_773238(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_773239, base: "/",
    url: url_GetBasePathMappings_773240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_773288 = ref object of OpenApiRestCall_772581
proc url_CreateDeployment_773290(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_773289(path: JsonNode; query: JsonNode;
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
  var valid_773291 = path.getOrDefault("restapi_id")
  valid_773291 = validateParameter(valid_773291, JString, required = true,
                                 default = nil)
  if valid_773291 != nil:
    section.add "restapi_id", valid_773291
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773292 = header.getOrDefault("X-Amz-Date")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Date", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Security-Token")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Security-Token", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Content-Sha256", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Algorithm")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Algorithm", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Signature")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Signature", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-SignedHeaders", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Credential")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Credential", valid_773298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773300: Call_CreateDeployment_773288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_773300.validator(path, query, header, formData, body)
  let scheme = call_773300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773300.url(scheme.get, call_773300.host, call_773300.base,
                         call_773300.route, valid.getOrDefault("path"))
  result = hook(call_773300, url, valid)

proc call*(call_773301: Call_CreateDeployment_773288; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773302 = newJObject()
  var body_773303 = newJObject()
  if body != nil:
    body_773303 = body
  add(path_773302, "restapi_id", newJString(restapiId))
  result = call_773301.call(path_773302, nil, nil, nil, body_773303)

var createDeployment* = Call_CreateDeployment_773288(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_773289, base: "/",
    url: url_CreateDeployment_773290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_773271 = ref object of OpenApiRestCall_772581
proc url_GetDeployments_773273(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_773272(path: JsonNode; query: JsonNode;
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
  var valid_773274 = path.getOrDefault("restapi_id")
  valid_773274 = validateParameter(valid_773274, JString, required = true,
                                 default = nil)
  if valid_773274 != nil:
    section.add "restapi_id", valid_773274
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773275 = query.getOrDefault("position")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "position", valid_773275
  var valid_773276 = query.getOrDefault("limit")
  valid_773276 = validateParameter(valid_773276, JInt, required = false, default = nil)
  if valid_773276 != nil:
    section.add "limit", valid_773276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773277 = header.getOrDefault("X-Amz-Date")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Date", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Security-Token")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Security-Token", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Content-Sha256", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Algorithm")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Algorithm", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Signature")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Signature", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-SignedHeaders", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Credential")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Credential", valid_773283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773284: Call_GetDeployments_773271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_773284.validator(path, query, header, formData, body)
  let scheme = call_773284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773284.url(scheme.get, call_773284.host, call_773284.base,
                         call_773284.route, valid.getOrDefault("path"))
  result = hook(call_773284, url, valid)

proc call*(call_773285: Call_GetDeployments_773271; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773286 = newJObject()
  var query_773287 = newJObject()
  add(query_773287, "position", newJString(position))
  add(query_773287, "limit", newJInt(limit))
  add(path_773286, "restapi_id", newJString(restapiId))
  result = call_773285.call(path_773286, query_773287, nil, nil, nil)

var getDeployments* = Call_GetDeployments_773271(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_773272, base: "/", url: url_GetDeployments_773273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_773338 = ref object of OpenApiRestCall_772581
proc url_ImportDocumentationParts_773340(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_773339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_773341 = path.getOrDefault("restapi_id")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = nil)
  if valid_773341 != nil:
    section.add "restapi_id", valid_773341
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_773342 = query.getOrDefault("mode")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = newJString("merge"))
  if valid_773342 != nil:
    section.add "mode", valid_773342
  var valid_773343 = query.getOrDefault("failonwarnings")
  valid_773343 = validateParameter(valid_773343, JBool, required = false, default = nil)
  if valid_773343 != nil:
    section.add "failonwarnings", valid_773343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773344 = header.getOrDefault("X-Amz-Date")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Date", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Security-Token")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Security-Token", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Content-Sha256", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Algorithm")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Algorithm", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Signature")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Signature", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-SignedHeaders", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Credential")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Credential", valid_773350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773352: Call_ImportDocumentationParts_773338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773352.validator(path, query, header, formData, body)
  let scheme = call_773352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773352.url(scheme.get, call_773352.host, call_773352.base,
                         call_773352.route, valid.getOrDefault("path"))
  result = hook(call_773352, url, valid)

proc call*(call_773353: Call_ImportDocumentationParts_773338; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773354 = newJObject()
  var query_773355 = newJObject()
  var body_773356 = newJObject()
  add(query_773355, "mode", newJString(mode))
  add(query_773355, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_773356 = body
  add(path_773354, "restapi_id", newJString(restapiId))
  result = call_773353.call(path_773354, query_773355, nil, nil, body_773356)

var importDocumentationParts* = Call_ImportDocumentationParts_773338(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_773339, base: "/",
    url: url_ImportDocumentationParts_773340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_773357 = ref object of OpenApiRestCall_772581
proc url_CreateDocumentationPart_773359(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_773358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_773360 = path.getOrDefault("restapi_id")
  valid_773360 = validateParameter(valid_773360, JString, required = true,
                                 default = nil)
  if valid_773360 != nil:
    section.add "restapi_id", valid_773360
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773361 = header.getOrDefault("X-Amz-Date")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Date", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Security-Token")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Security-Token", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Content-Sha256", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Algorithm")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Algorithm", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Signature")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Signature", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-SignedHeaders", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Credential")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Credential", valid_773367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773369: Call_CreateDocumentationPart_773357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773369.validator(path, query, header, formData, body)
  let scheme = call_773369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773369.url(scheme.get, call_773369.host, call_773369.base,
                         call_773369.route, valid.getOrDefault("path"))
  result = hook(call_773369, url, valid)

proc call*(call_773370: Call_CreateDocumentationPart_773357; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773371 = newJObject()
  var body_773372 = newJObject()
  if body != nil:
    body_773372 = body
  add(path_773371, "restapi_id", newJString(restapiId))
  result = call_773370.call(path_773371, nil, nil, nil, body_773372)

var createDocumentationPart* = Call_CreateDocumentationPart_773357(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_773358, base: "/",
    url: url_CreateDocumentationPart_773359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_773304 = ref object of OpenApiRestCall_772581
proc url_GetDocumentationParts_773306(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_773305(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_773307 = path.getOrDefault("restapi_id")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = nil)
  if valid_773307 != nil:
    section.add "restapi_id", valid_773307
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
  var valid_773321 = query.getOrDefault("type")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = newJString("API"))
  if valid_773321 != nil:
    section.add "type", valid_773321
  var valid_773322 = query.getOrDefault("path")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "path", valid_773322
  var valid_773323 = query.getOrDefault("locationStatus")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_773323 != nil:
    section.add "locationStatus", valid_773323
  var valid_773324 = query.getOrDefault("name")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "name", valid_773324
  var valid_773325 = query.getOrDefault("position")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "position", valid_773325
  var valid_773326 = query.getOrDefault("limit")
  valid_773326 = validateParameter(valid_773326, JInt, required = false, default = nil)
  if valid_773326 != nil:
    section.add "limit", valid_773326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773327 = header.getOrDefault("X-Amz-Date")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Date", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Security-Token")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Security-Token", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Content-Sha256", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Algorithm")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Algorithm", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Signature")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Signature", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-SignedHeaders", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Credential")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Credential", valid_773333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_GetDocumentationParts_773304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_GetDocumentationParts_773304; restapiId: string;
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
  var path_773336 = newJObject()
  var query_773337 = newJObject()
  add(query_773337, "type", newJString(`type`))
  add(query_773337, "path", newJString(path))
  add(query_773337, "locationStatus", newJString(locationStatus))
  add(query_773337, "name", newJString(name))
  add(query_773337, "position", newJString(position))
  add(query_773337, "limit", newJInt(limit))
  add(path_773336, "restapi_id", newJString(restapiId))
  result = call_773335.call(path_773336, query_773337, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_773304(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_773305, base: "/",
    url: url_GetDocumentationParts_773306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_773390 = ref object of OpenApiRestCall_772581
proc url_CreateDocumentationVersion_773392(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_773391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_773393 = path.getOrDefault("restapi_id")
  valid_773393 = validateParameter(valid_773393, JString, required = true,
                                 default = nil)
  if valid_773393 != nil:
    section.add "restapi_id", valid_773393
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773394 = header.getOrDefault("X-Amz-Date")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Date", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Security-Token")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Security-Token", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Content-Sha256", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Algorithm")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Algorithm", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Signature")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Signature", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-SignedHeaders", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Credential")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Credential", valid_773400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773402: Call_CreateDocumentationVersion_773390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773402.validator(path, query, header, formData, body)
  let scheme = call_773402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773402.url(scheme.get, call_773402.host, call_773402.base,
                         call_773402.route, valid.getOrDefault("path"))
  result = hook(call_773402, url, valid)

proc call*(call_773403: Call_CreateDocumentationVersion_773390; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773404 = newJObject()
  var body_773405 = newJObject()
  if body != nil:
    body_773405 = body
  add(path_773404, "restapi_id", newJString(restapiId))
  result = call_773403.call(path_773404, nil, nil, nil, body_773405)

var createDocumentationVersion* = Call_CreateDocumentationVersion_773390(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_773391, base: "/",
    url: url_CreateDocumentationVersion_773392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_773373 = ref object of OpenApiRestCall_772581
proc url_GetDocumentationVersions_773375(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_773374(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_773376 = path.getOrDefault("restapi_id")
  valid_773376 = validateParameter(valid_773376, JString, required = true,
                                 default = nil)
  if valid_773376 != nil:
    section.add "restapi_id", valid_773376
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773377 = query.getOrDefault("position")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "position", valid_773377
  var valid_773378 = query.getOrDefault("limit")
  valid_773378 = validateParameter(valid_773378, JInt, required = false, default = nil)
  if valid_773378 != nil:
    section.add "limit", valid_773378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773379 = header.getOrDefault("X-Amz-Date")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Date", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Security-Token")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Security-Token", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Content-Sha256", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Algorithm")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Algorithm", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Signature")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Signature", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-SignedHeaders", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Credential")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Credential", valid_773385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773386: Call_GetDocumentationVersions_773373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773386.validator(path, query, header, formData, body)
  let scheme = call_773386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773386.url(scheme.get, call_773386.host, call_773386.base,
                         call_773386.route, valid.getOrDefault("path"))
  result = hook(call_773386, url, valid)

proc call*(call_773387: Call_GetDocumentationVersions_773373; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773388 = newJObject()
  var query_773389 = newJObject()
  add(query_773389, "position", newJString(position))
  add(query_773389, "limit", newJInt(limit))
  add(path_773388, "restapi_id", newJString(restapiId))
  result = call_773387.call(path_773388, query_773389, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_773373(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_773374, base: "/",
    url: url_GetDocumentationVersions_773375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_773421 = ref object of OpenApiRestCall_772581
proc url_CreateDomainName_773423(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDomainName_773422(path: JsonNode; query: JsonNode;
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
  var valid_773424 = header.getOrDefault("X-Amz-Date")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Date", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Security-Token")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Security-Token", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Content-Sha256", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Algorithm")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Algorithm", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Signature")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Signature", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-SignedHeaders", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Credential")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Credential", valid_773430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773432: Call_CreateDomainName_773421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_773432.validator(path, query, header, formData, body)
  let scheme = call_773432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773432.url(scheme.get, call_773432.host, call_773432.base,
                         call_773432.route, valid.getOrDefault("path"))
  result = hook(call_773432, url, valid)

proc call*(call_773433: Call_CreateDomainName_773421; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_773434 = newJObject()
  if body != nil:
    body_773434 = body
  result = call_773433.call(nil, nil, nil, nil, body_773434)

var createDomainName* = Call_CreateDomainName_773421(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_773422, base: "/",
    url: url_CreateDomainName_773423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_773406 = ref object of OpenApiRestCall_772581
proc url_GetDomainNames_773408(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainNames_773407(path: JsonNode; query: JsonNode;
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
  var valid_773409 = query.getOrDefault("position")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "position", valid_773409
  var valid_773410 = query.getOrDefault("limit")
  valid_773410 = validateParameter(valid_773410, JInt, required = false, default = nil)
  if valid_773410 != nil:
    section.add "limit", valid_773410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773411 = header.getOrDefault("X-Amz-Date")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Date", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Security-Token")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Security-Token", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Content-Sha256", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Algorithm")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Algorithm", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Signature")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Signature", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-SignedHeaders", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Credential")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Credential", valid_773417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773418: Call_GetDomainNames_773406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_773418.validator(path, query, header, formData, body)
  let scheme = call_773418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773418.url(scheme.get, call_773418.host, call_773418.base,
                         call_773418.route, valid.getOrDefault("path"))
  result = hook(call_773418, url, valid)

proc call*(call_773419: Call_GetDomainNames_773406; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_773420 = newJObject()
  add(query_773420, "position", newJString(position))
  add(query_773420, "limit", newJInt(limit))
  result = call_773419.call(nil, query_773420, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_773406(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_773407, base: "/",
    url: url_GetDomainNames_773408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_773452 = ref object of OpenApiRestCall_772581
proc url_CreateModel_773454(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_773453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773455 = path.getOrDefault("restapi_id")
  valid_773455 = validateParameter(valid_773455, JString, required = true,
                                 default = nil)
  if valid_773455 != nil:
    section.add "restapi_id", valid_773455
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773456 = header.getOrDefault("X-Amz-Date")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Date", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Security-Token")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Security-Token", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Content-Sha256", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Algorithm")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Algorithm", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Signature")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Signature", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-SignedHeaders", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Credential")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Credential", valid_773462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773464: Call_CreateModel_773452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_773464.validator(path, query, header, formData, body)
  let scheme = call_773464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773464.url(scheme.get, call_773464.host, call_773464.base,
                         call_773464.route, valid.getOrDefault("path"))
  result = hook(call_773464, url, valid)

proc call*(call_773465: Call_CreateModel_773452; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_773466 = newJObject()
  var body_773467 = newJObject()
  if body != nil:
    body_773467 = body
  add(path_773466, "restapi_id", newJString(restapiId))
  result = call_773465.call(path_773466, nil, nil, nil, body_773467)

var createModel* = Call_CreateModel_773452(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_773453,
                                        base: "/", url: url_CreateModel_773454,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_773435 = ref object of OpenApiRestCall_772581
proc url_GetModels_773437(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_773436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773438 = path.getOrDefault("restapi_id")
  valid_773438 = validateParameter(valid_773438, JString, required = true,
                                 default = nil)
  if valid_773438 != nil:
    section.add "restapi_id", valid_773438
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773439 = query.getOrDefault("position")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "position", valid_773439
  var valid_773440 = query.getOrDefault("limit")
  valid_773440 = validateParameter(valid_773440, JInt, required = false, default = nil)
  if valid_773440 != nil:
    section.add "limit", valid_773440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773441 = header.getOrDefault("X-Amz-Date")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Date", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Security-Token")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Security-Token", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Content-Sha256", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Algorithm")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Algorithm", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Signature")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Signature", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-SignedHeaders", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Credential")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Credential", valid_773447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773448: Call_GetModels_773435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_773448.validator(path, query, header, formData, body)
  let scheme = call_773448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773448.url(scheme.get, call_773448.host, call_773448.base,
                         call_773448.route, valid.getOrDefault("path"))
  result = hook(call_773448, url, valid)

proc call*(call_773449: Call_GetModels_773435; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773450 = newJObject()
  var query_773451 = newJObject()
  add(query_773451, "position", newJString(position))
  add(query_773451, "limit", newJInt(limit))
  add(path_773450, "restapi_id", newJString(restapiId))
  result = call_773449.call(path_773450, query_773451, nil, nil, nil)

var getModels* = Call_GetModels_773435(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_773436,
                                    base: "/", url: url_GetModels_773437,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_773485 = ref object of OpenApiRestCall_772581
proc url_CreateRequestValidator_773487(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_773486(path: JsonNode; query: JsonNode;
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
  var valid_773488 = path.getOrDefault("restapi_id")
  valid_773488 = validateParameter(valid_773488, JString, required = true,
                                 default = nil)
  if valid_773488 != nil:
    section.add "restapi_id", valid_773488
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773489 = header.getOrDefault("X-Amz-Date")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Date", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Security-Token")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Security-Token", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Content-Sha256", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Algorithm")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Algorithm", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Signature")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Signature", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-SignedHeaders", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Credential")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Credential", valid_773495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773497: Call_CreateRequestValidator_773485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_773497.validator(path, query, header, formData, body)
  let scheme = call_773497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773497.url(scheme.get, call_773497.host, call_773497.base,
                         call_773497.route, valid.getOrDefault("path"))
  result = hook(call_773497, url, valid)

proc call*(call_773498: Call_CreateRequestValidator_773485; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773499 = newJObject()
  var body_773500 = newJObject()
  if body != nil:
    body_773500 = body
  add(path_773499, "restapi_id", newJString(restapiId))
  result = call_773498.call(path_773499, nil, nil, nil, body_773500)

var createRequestValidator* = Call_CreateRequestValidator_773485(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_773486, base: "/",
    url: url_CreateRequestValidator_773487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_773468 = ref object of OpenApiRestCall_772581
proc url_GetRequestValidators_773470(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_773469(path: JsonNode; query: JsonNode;
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
  var valid_773471 = path.getOrDefault("restapi_id")
  valid_773471 = validateParameter(valid_773471, JString, required = true,
                                 default = nil)
  if valid_773471 != nil:
    section.add "restapi_id", valid_773471
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773472 = query.getOrDefault("position")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "position", valid_773472
  var valid_773473 = query.getOrDefault("limit")
  valid_773473 = validateParameter(valid_773473, JInt, required = false, default = nil)
  if valid_773473 != nil:
    section.add "limit", valid_773473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773474 = header.getOrDefault("X-Amz-Date")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Date", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Security-Token")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Security-Token", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Content-Sha256", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Algorithm")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Algorithm", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Signature")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Signature", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-SignedHeaders", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Credential")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Credential", valid_773480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773481: Call_GetRequestValidators_773468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_773481.validator(path, query, header, formData, body)
  let scheme = call_773481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773481.url(scheme.get, call_773481.host, call_773481.base,
                         call_773481.route, valid.getOrDefault("path"))
  result = hook(call_773481, url, valid)

proc call*(call_773482: Call_GetRequestValidators_773468; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773483 = newJObject()
  var query_773484 = newJObject()
  add(query_773484, "position", newJString(position))
  add(query_773484, "limit", newJInt(limit))
  add(path_773483, "restapi_id", newJString(restapiId))
  result = call_773482.call(path_773483, query_773484, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_773468(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_773469, base: "/",
    url: url_GetRequestValidators_773470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_773501 = ref object of OpenApiRestCall_772581
proc url_CreateResource_773503(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_773502(path: JsonNode; query: JsonNode;
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
  var valid_773504 = path.getOrDefault("parent_id")
  valid_773504 = validateParameter(valid_773504, JString, required = true,
                                 default = nil)
  if valid_773504 != nil:
    section.add "parent_id", valid_773504
  var valid_773505 = path.getOrDefault("restapi_id")
  valid_773505 = validateParameter(valid_773505, JString, required = true,
                                 default = nil)
  if valid_773505 != nil:
    section.add "restapi_id", valid_773505
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_CreateResource_773501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_CreateResource_773501; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773516 = newJObject()
  var body_773517 = newJObject()
  add(path_773516, "parent_id", newJString(parentId))
  if body != nil:
    body_773517 = body
  add(path_773516, "restapi_id", newJString(restapiId))
  result = call_773515.call(path_773516, nil, nil, nil, body_773517)

var createResource* = Call_CreateResource_773501(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_773502, base: "/", url: url_CreateResource_773503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_773533 = ref object of OpenApiRestCall_772581
proc url_CreateRestApi_773535(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRestApi_773534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773536 = header.getOrDefault("X-Amz-Date")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Date", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Security-Token")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Security-Token", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_CreateRestApi_773533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_CreateRestApi_773533; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_773546 = newJObject()
  if body != nil:
    body_773546 = body
  result = call_773545.call(nil, nil, nil, nil, body_773546)

var createRestApi* = Call_CreateRestApi_773533(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_773534, base: "/", url: url_CreateRestApi_773535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_773518 = ref object of OpenApiRestCall_772581
proc url_GetRestApis_773520(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestApis_773519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773521 = query.getOrDefault("position")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "position", valid_773521
  var valid_773522 = query.getOrDefault("limit")
  valid_773522 = validateParameter(valid_773522, JInt, required = false, default = nil)
  if valid_773522 != nil:
    section.add "limit", valid_773522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773523 = header.getOrDefault("X-Amz-Date")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Date", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Security-Token")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Security-Token", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Content-Sha256", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Algorithm")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Algorithm", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Signature")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Signature", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-SignedHeaders", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Credential")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Credential", valid_773529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773530: Call_GetRestApis_773518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_773530.validator(path, query, header, formData, body)
  let scheme = call_773530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773530.url(scheme.get, call_773530.host, call_773530.base,
                         call_773530.route, valid.getOrDefault("path"))
  result = hook(call_773530, url, valid)

proc call*(call_773531: Call_GetRestApis_773518; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_773532 = newJObject()
  add(query_773532, "position", newJString(position))
  add(query_773532, "limit", newJInt(limit))
  result = call_773531.call(nil, query_773532, nil, nil, nil)

var getRestApis* = Call_GetRestApis_773518(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_773519,
                                        base: "/", url: url_GetRestApis_773520,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_773563 = ref object of OpenApiRestCall_772581
proc url_CreateStage_773565(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_773564(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773566 = path.getOrDefault("restapi_id")
  valid_773566 = validateParameter(valid_773566, JString, required = true,
                                 default = nil)
  if valid_773566 != nil:
    section.add "restapi_id", valid_773566
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773567 = header.getOrDefault("X-Amz-Date")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Date", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Security-Token")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Security-Token", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Content-Sha256", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Algorithm")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Algorithm", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-Signature")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Signature", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-SignedHeaders", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Credential")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Credential", valid_773573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773575: Call_CreateStage_773563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_773575.validator(path, query, header, formData, body)
  let scheme = call_773575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773575.url(scheme.get, call_773575.host, call_773575.base,
                         call_773575.route, valid.getOrDefault("path"))
  result = hook(call_773575, url, valid)

proc call*(call_773576: Call_CreateStage_773563; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773577 = newJObject()
  var body_773578 = newJObject()
  if body != nil:
    body_773578 = body
  add(path_773577, "restapi_id", newJString(restapiId))
  result = call_773576.call(path_773577, nil, nil, nil, body_773578)

var createStage* = Call_CreateStage_773563(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_773564,
                                        base: "/", url: url_CreateStage_773565,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_773547 = ref object of OpenApiRestCall_772581
proc url_GetStages_773549(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_773548(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773550 = path.getOrDefault("restapi_id")
  valid_773550 = validateParameter(valid_773550, JString, required = true,
                                 default = nil)
  if valid_773550 != nil:
    section.add "restapi_id", valid_773550
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_773551 = query.getOrDefault("deploymentId")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "deploymentId", valid_773551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773552 = header.getOrDefault("X-Amz-Date")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Date", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Security-Token")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Security-Token", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Content-Sha256", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Algorithm")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Algorithm", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Signature")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Signature", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-SignedHeaders", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Credential")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Credential", valid_773558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773559: Call_GetStages_773547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_773559.validator(path, query, header, formData, body)
  let scheme = call_773559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773559.url(scheme.get, call_773559.host, call_773559.base,
                         call_773559.route, valid.getOrDefault("path"))
  result = hook(call_773559, url, valid)

proc call*(call_773560: Call_GetStages_773547; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773561 = newJObject()
  var query_773562 = newJObject()
  add(query_773562, "deploymentId", newJString(deploymentId))
  add(path_773561, "restapi_id", newJString(restapiId))
  result = call_773560.call(path_773561, query_773562, nil, nil, nil)

var getStages* = Call_GetStages_773547(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_773548,
                                    base: "/", url: url_GetStages_773549,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_773595 = ref object of OpenApiRestCall_772581
proc url_CreateUsagePlan_773597(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUsagePlan_773596(path: JsonNode; query: JsonNode;
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
  var valid_773598 = header.getOrDefault("X-Amz-Date")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Date", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Security-Token")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Security-Token", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Content-Sha256", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Algorithm")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Algorithm", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Signature")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Signature", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-SignedHeaders", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Credential")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Credential", valid_773604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773606: Call_CreateUsagePlan_773595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_773606.validator(path, query, header, formData, body)
  let scheme = call_773606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773606.url(scheme.get, call_773606.host, call_773606.base,
                         call_773606.route, valid.getOrDefault("path"))
  result = hook(call_773606, url, valid)

proc call*(call_773607: Call_CreateUsagePlan_773595; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_773608 = newJObject()
  if body != nil:
    body_773608 = body
  result = call_773607.call(nil, nil, nil, nil, body_773608)

var createUsagePlan* = Call_CreateUsagePlan_773595(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_773596, base: "/",
    url: url_CreateUsagePlan_773597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_773579 = ref object of OpenApiRestCall_772581
proc url_GetUsagePlans_773581(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUsagePlans_773580(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773582 = query.getOrDefault("keyId")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "keyId", valid_773582
  var valid_773583 = query.getOrDefault("position")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "position", valid_773583
  var valid_773584 = query.getOrDefault("limit")
  valid_773584 = validateParameter(valid_773584, JInt, required = false, default = nil)
  if valid_773584 != nil:
    section.add "limit", valid_773584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773585 = header.getOrDefault("X-Amz-Date")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Date", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Security-Token")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Security-Token", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Content-Sha256", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Algorithm")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Algorithm", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Signature")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Signature", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-SignedHeaders", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Credential")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Credential", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773592: Call_GetUsagePlans_773579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_773592.validator(path, query, header, formData, body)
  let scheme = call_773592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773592.url(scheme.get, call_773592.host, call_773592.base,
                         call_773592.route, valid.getOrDefault("path"))
  result = hook(call_773592, url, valid)

proc call*(call_773593: Call_GetUsagePlans_773579; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_773594 = newJObject()
  add(query_773594, "keyId", newJString(keyId))
  add(query_773594, "position", newJString(position))
  add(query_773594, "limit", newJInt(limit))
  result = call_773593.call(nil, query_773594, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_773579(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_773580, base: "/",
    url: url_GetUsagePlans_773581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_773627 = ref object of OpenApiRestCall_772581
proc url_CreateUsagePlanKey_773629(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_773628(path: JsonNode; query: JsonNode;
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
  var valid_773630 = path.getOrDefault("usageplanId")
  valid_773630 = validateParameter(valid_773630, JString, required = true,
                                 default = nil)
  if valid_773630 != nil:
    section.add "usageplanId", valid_773630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773631 = header.getOrDefault("X-Amz-Date")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Date", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Security-Token")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Security-Token", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Content-Sha256", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Algorithm")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Algorithm", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Signature")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Signature", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-SignedHeaders", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-Credential")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Credential", valid_773637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773639: Call_CreateUsagePlanKey_773627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_773639.validator(path, query, header, formData, body)
  let scheme = call_773639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773639.url(scheme.get, call_773639.host, call_773639.base,
                         call_773639.route, valid.getOrDefault("path"))
  result = hook(call_773639, url, valid)

proc call*(call_773640: Call_CreateUsagePlanKey_773627; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_773641 = newJObject()
  var body_773642 = newJObject()
  add(path_773641, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_773642 = body
  result = call_773640.call(path_773641, nil, nil, nil, body_773642)

var createUsagePlanKey* = Call_CreateUsagePlanKey_773627(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_773628, base: "/",
    url: url_CreateUsagePlanKey_773629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_773609 = ref object of OpenApiRestCall_772581
proc url_GetUsagePlanKeys_773611(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_773610(path: JsonNode; query: JsonNode;
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
  var valid_773612 = path.getOrDefault("usageplanId")
  valid_773612 = validateParameter(valid_773612, JString, required = true,
                                 default = nil)
  if valid_773612 != nil:
    section.add "usageplanId", valid_773612
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_773613 = query.getOrDefault("name")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "name", valid_773613
  var valid_773614 = query.getOrDefault("position")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "position", valid_773614
  var valid_773615 = query.getOrDefault("limit")
  valid_773615 = validateParameter(valid_773615, JInt, required = false, default = nil)
  if valid_773615 != nil:
    section.add "limit", valid_773615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773616 = header.getOrDefault("X-Amz-Date")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Date", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Security-Token")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Security-Token", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Content-Sha256", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Algorithm")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Algorithm", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Signature")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Signature", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-SignedHeaders", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Credential")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Credential", valid_773622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_GetUsagePlanKeys_773609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_GetUsagePlanKeys_773609; usageplanId: string;
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
  var path_773625 = newJObject()
  var query_773626 = newJObject()
  add(path_773625, "usageplanId", newJString(usageplanId))
  add(query_773626, "name", newJString(name))
  add(query_773626, "position", newJString(position))
  add(query_773626, "limit", newJInt(limit))
  result = call_773624.call(path_773625, query_773626, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_773609(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_773610,
    base: "/", url: url_GetUsagePlanKeys_773611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_773658 = ref object of OpenApiRestCall_772581
proc url_CreateVpcLink_773660(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVpcLink_773659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773661 = header.getOrDefault("X-Amz-Date")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Date", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Security-Token")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Security-Token", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Content-Sha256", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Algorithm")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Algorithm", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Signature")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Signature", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-SignedHeaders", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Credential")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Credential", valid_773667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773669: Call_CreateVpcLink_773658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_773669.validator(path, query, header, formData, body)
  let scheme = call_773669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773669.url(scheme.get, call_773669.host, call_773669.base,
                         call_773669.route, valid.getOrDefault("path"))
  result = hook(call_773669, url, valid)

proc call*(call_773670: Call_CreateVpcLink_773658; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_773671 = newJObject()
  if body != nil:
    body_773671 = body
  result = call_773670.call(nil, nil, nil, nil, body_773671)

var createVpcLink* = Call_CreateVpcLink_773658(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_773659, base: "/", url: url_CreateVpcLink_773660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_773643 = ref object of OpenApiRestCall_772581
proc url_GetVpcLinks_773645(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetVpcLinks_773644(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773646 = query.getOrDefault("position")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "position", valid_773646
  var valid_773647 = query.getOrDefault("limit")
  valid_773647 = validateParameter(valid_773647, JInt, required = false, default = nil)
  if valid_773647 != nil:
    section.add "limit", valid_773647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773648 = header.getOrDefault("X-Amz-Date")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Date", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Security-Token")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Security-Token", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Content-Sha256", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Algorithm")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Algorithm", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Signature")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Signature", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-SignedHeaders", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Credential")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Credential", valid_773654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773655: Call_GetVpcLinks_773643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_773655.validator(path, query, header, formData, body)
  let scheme = call_773655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773655.url(scheme.get, call_773655.host, call_773655.base,
                         call_773655.route, valid.getOrDefault("path"))
  result = hook(call_773655, url, valid)

proc call*(call_773656: Call_GetVpcLinks_773643; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_773657 = newJObject()
  add(query_773657, "position", newJString(position))
  add(query_773657, "limit", newJInt(limit))
  result = call_773656.call(nil, query_773657, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_773643(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_773644,
                                        base: "/", url: url_GetVpcLinks_773645,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_773672 = ref object of OpenApiRestCall_772581
proc url_GetApiKey_773674(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_773673(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773675 = path.getOrDefault("api_Key")
  valid_773675 = validateParameter(valid_773675, JString, required = true,
                                 default = nil)
  if valid_773675 != nil:
    section.add "api_Key", valid_773675
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_773676 = query.getOrDefault("includeValue")
  valid_773676 = validateParameter(valid_773676, JBool, required = false, default = nil)
  if valid_773676 != nil:
    section.add "includeValue", valid_773676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Content-Sha256", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Algorithm")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Algorithm", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Signature")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Signature", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-SignedHeaders", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Credential")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Credential", valid_773683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_GetApiKey_773672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_GetApiKey_773672; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_773686 = newJObject()
  var query_773687 = newJObject()
  add(query_773687, "includeValue", newJBool(includeValue))
  add(path_773686, "api_Key", newJString(apiKey))
  result = call_773685.call(path_773686, query_773687, nil, nil, nil)

var getApiKey* = Call_GetApiKey_773672(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_773673,
                                    base: "/", url: url_GetApiKey_773674,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_773702 = ref object of OpenApiRestCall_772581
proc url_UpdateApiKey_773704(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_773703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773705 = path.getOrDefault("api_Key")
  valid_773705 = validateParameter(valid_773705, JString, required = true,
                                 default = nil)
  if valid_773705 != nil:
    section.add "api_Key", valid_773705
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773706 = header.getOrDefault("X-Amz-Date")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Date", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Security-Token")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Security-Token", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Content-Sha256", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Algorithm")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Algorithm", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Signature")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Signature", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-SignedHeaders", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Credential")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Credential", valid_773712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773714: Call_UpdateApiKey_773702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_773714.validator(path, query, header, formData, body)
  let scheme = call_773714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773714.url(scheme.get, call_773714.host, call_773714.base,
                         call_773714.route, valid.getOrDefault("path"))
  result = hook(call_773714, url, valid)

proc call*(call_773715: Call_UpdateApiKey_773702; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_773716 = newJObject()
  var body_773717 = newJObject()
  add(path_773716, "api_Key", newJString(apiKey))
  if body != nil:
    body_773717 = body
  result = call_773715.call(path_773716, nil, nil, nil, body_773717)

var updateApiKey* = Call_UpdateApiKey_773702(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_773703, base: "/",
    url: url_UpdateApiKey_773704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_773688 = ref object of OpenApiRestCall_772581
proc url_DeleteApiKey_773690(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_773689(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773691 = path.getOrDefault("api_Key")
  valid_773691 = validateParameter(valid_773691, JString, required = true,
                                 default = nil)
  if valid_773691 != nil:
    section.add "api_Key", valid_773691
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773692 = header.getOrDefault("X-Amz-Date")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Date", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Security-Token")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Security-Token", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Content-Sha256", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Algorithm")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Algorithm", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Signature")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Signature", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-SignedHeaders", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Credential")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Credential", valid_773698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773699: Call_DeleteApiKey_773688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_773699.validator(path, query, header, formData, body)
  let scheme = call_773699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773699.url(scheme.get, call_773699.host, call_773699.base,
                         call_773699.route, valid.getOrDefault("path"))
  result = hook(call_773699, url, valid)

proc call*(call_773700: Call_DeleteApiKey_773688; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_773701 = newJObject()
  add(path_773701, "api_Key", newJString(apiKey))
  result = call_773700.call(path_773701, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_773688(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_773689, base: "/",
    url: url_DeleteApiKey_773690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_773733 = ref object of OpenApiRestCall_772581
proc url_TestInvokeAuthorizer_773735(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_773734(path: JsonNode; query: JsonNode;
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
  var valid_773736 = path.getOrDefault("authorizer_id")
  valid_773736 = validateParameter(valid_773736, JString, required = true,
                                 default = nil)
  if valid_773736 != nil:
    section.add "authorizer_id", valid_773736
  var valid_773737 = path.getOrDefault("restapi_id")
  valid_773737 = validateParameter(valid_773737, JString, required = true,
                                 default = nil)
  if valid_773737 != nil:
    section.add "restapi_id", valid_773737
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773738 = header.getOrDefault("X-Amz-Date")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Date", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Security-Token")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Security-Token", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Content-Sha256", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Algorithm")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Algorithm", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-Signature")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-Signature", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-SignedHeaders", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Credential")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Credential", valid_773744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773746: Call_TestInvokeAuthorizer_773733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_773746.validator(path, query, header, formData, body)
  let scheme = call_773746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773746.url(scheme.get, call_773746.host, call_773746.base,
                         call_773746.route, valid.getOrDefault("path"))
  result = hook(call_773746, url, valid)

proc call*(call_773747: Call_TestInvokeAuthorizer_773733; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773748 = newJObject()
  var body_773749 = newJObject()
  add(path_773748, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_773749 = body
  add(path_773748, "restapi_id", newJString(restapiId))
  result = call_773747.call(path_773748, nil, nil, nil, body_773749)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_773733(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_773734, base: "/",
    url: url_TestInvokeAuthorizer_773735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_773718 = ref object of OpenApiRestCall_772581
proc url_GetAuthorizer_773720(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_773719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773721 = path.getOrDefault("authorizer_id")
  valid_773721 = validateParameter(valid_773721, JString, required = true,
                                 default = nil)
  if valid_773721 != nil:
    section.add "authorizer_id", valid_773721
  var valid_773722 = path.getOrDefault("restapi_id")
  valid_773722 = validateParameter(valid_773722, JString, required = true,
                                 default = nil)
  if valid_773722 != nil:
    section.add "restapi_id", valid_773722
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773723 = header.getOrDefault("X-Amz-Date")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Date", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-Security-Token")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Security-Token", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Content-Sha256", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Algorithm")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Algorithm", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Signature")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Signature", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-SignedHeaders", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Credential")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Credential", valid_773729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773730: Call_GetAuthorizer_773718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_773730.validator(path, query, header, formData, body)
  let scheme = call_773730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773730.url(scheme.get, call_773730.host, call_773730.base,
                         call_773730.route, valid.getOrDefault("path"))
  result = hook(call_773730, url, valid)

proc call*(call_773731: Call_GetAuthorizer_773718; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773732 = newJObject()
  add(path_773732, "authorizer_id", newJString(authorizerId))
  add(path_773732, "restapi_id", newJString(restapiId))
  result = call_773731.call(path_773732, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_773718(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_773719, base: "/", url: url_GetAuthorizer_773720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_773765 = ref object of OpenApiRestCall_772581
proc url_UpdateAuthorizer_773767(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_773766(path: JsonNode; query: JsonNode;
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
  var valid_773768 = path.getOrDefault("authorizer_id")
  valid_773768 = validateParameter(valid_773768, JString, required = true,
                                 default = nil)
  if valid_773768 != nil:
    section.add "authorizer_id", valid_773768
  var valid_773769 = path.getOrDefault("restapi_id")
  valid_773769 = validateParameter(valid_773769, JString, required = true,
                                 default = nil)
  if valid_773769 != nil:
    section.add "restapi_id", valid_773769
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773770 = header.getOrDefault("X-Amz-Date")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Date", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Security-Token")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Security-Token", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Content-Sha256", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-Algorithm")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-Algorithm", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Signature")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Signature", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-SignedHeaders", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Credential")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Credential", valid_773776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773778: Call_UpdateAuthorizer_773765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_773778.validator(path, query, header, formData, body)
  let scheme = call_773778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773778.url(scheme.get, call_773778.host, call_773778.base,
                         call_773778.route, valid.getOrDefault("path"))
  result = hook(call_773778, url, valid)

proc call*(call_773779: Call_UpdateAuthorizer_773765; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773780 = newJObject()
  var body_773781 = newJObject()
  add(path_773780, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_773781 = body
  add(path_773780, "restapi_id", newJString(restapiId))
  result = call_773779.call(path_773780, nil, nil, nil, body_773781)

var updateAuthorizer* = Call_UpdateAuthorizer_773765(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_773766, base: "/",
    url: url_UpdateAuthorizer_773767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_773750 = ref object of OpenApiRestCall_772581
proc url_DeleteAuthorizer_773752(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_773751(path: JsonNode; query: JsonNode;
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
  var valid_773753 = path.getOrDefault("authorizer_id")
  valid_773753 = validateParameter(valid_773753, JString, required = true,
                                 default = nil)
  if valid_773753 != nil:
    section.add "authorizer_id", valid_773753
  var valid_773754 = path.getOrDefault("restapi_id")
  valid_773754 = validateParameter(valid_773754, JString, required = true,
                                 default = nil)
  if valid_773754 != nil:
    section.add "restapi_id", valid_773754
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773755 = header.getOrDefault("X-Amz-Date")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Date", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Security-Token")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Security-Token", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Content-Sha256", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-Algorithm")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Algorithm", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Signature")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Signature", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-SignedHeaders", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Credential")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Credential", valid_773761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773762: Call_DeleteAuthorizer_773750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_773762.validator(path, query, header, formData, body)
  let scheme = call_773762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773762.url(scheme.get, call_773762.host, call_773762.base,
                         call_773762.route, valid.getOrDefault("path"))
  result = hook(call_773762, url, valid)

proc call*(call_773763: Call_DeleteAuthorizer_773750; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773764 = newJObject()
  add(path_773764, "authorizer_id", newJString(authorizerId))
  add(path_773764, "restapi_id", newJString(restapiId))
  result = call_773763.call(path_773764, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_773750(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_773751, base: "/",
    url: url_DeleteAuthorizer_773752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_773782 = ref object of OpenApiRestCall_772581
proc url_GetBasePathMapping_773784(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_773783(path: JsonNode; query: JsonNode;
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
  var valid_773785 = path.getOrDefault("base_path")
  valid_773785 = validateParameter(valid_773785, JString, required = true,
                                 default = nil)
  if valid_773785 != nil:
    section.add "base_path", valid_773785
  var valid_773786 = path.getOrDefault("domain_name")
  valid_773786 = validateParameter(valid_773786, JString, required = true,
                                 default = nil)
  if valid_773786 != nil:
    section.add "domain_name", valid_773786
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773787 = header.getOrDefault("X-Amz-Date")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Date", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Security-Token")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Security-Token", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Content-Sha256", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Algorithm")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Algorithm", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Signature")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Signature", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-SignedHeaders", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Credential")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Credential", valid_773793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773794: Call_GetBasePathMapping_773782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_773794.validator(path, query, header, formData, body)
  let scheme = call_773794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773794.url(scheme.get, call_773794.host, call_773794.base,
                         call_773794.route, valid.getOrDefault("path"))
  result = hook(call_773794, url, valid)

proc call*(call_773795: Call_GetBasePathMapping_773782; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_773796 = newJObject()
  add(path_773796, "base_path", newJString(basePath))
  add(path_773796, "domain_name", newJString(domainName))
  result = call_773795.call(path_773796, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_773782(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_773783, base: "/",
    url: url_GetBasePathMapping_773784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_773812 = ref object of OpenApiRestCall_772581
proc url_UpdateBasePathMapping_773814(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_773813(path: JsonNode; query: JsonNode;
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
  var valid_773815 = path.getOrDefault("base_path")
  valid_773815 = validateParameter(valid_773815, JString, required = true,
                                 default = nil)
  if valid_773815 != nil:
    section.add "base_path", valid_773815
  var valid_773816 = path.getOrDefault("domain_name")
  valid_773816 = validateParameter(valid_773816, JString, required = true,
                                 default = nil)
  if valid_773816 != nil:
    section.add "domain_name", valid_773816
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773817 = header.getOrDefault("X-Amz-Date")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Date", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Security-Token")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Security-Token", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Content-Sha256", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Algorithm")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Algorithm", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Signature")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Signature", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-SignedHeaders", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Credential")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Credential", valid_773823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773825: Call_UpdateBasePathMapping_773812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_773825.validator(path, query, header, formData, body)
  let scheme = call_773825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773825.url(scheme.get, call_773825.host, call_773825.base,
                         call_773825.route, valid.getOrDefault("path"))
  result = hook(call_773825, url, valid)

proc call*(call_773826: Call_UpdateBasePathMapping_773812; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_773827 = newJObject()
  var body_773828 = newJObject()
  add(path_773827, "base_path", newJString(basePath))
  add(path_773827, "domain_name", newJString(domainName))
  if body != nil:
    body_773828 = body
  result = call_773826.call(path_773827, nil, nil, nil, body_773828)

var updateBasePathMapping* = Call_UpdateBasePathMapping_773812(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_773813, base: "/",
    url: url_UpdateBasePathMapping_773814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_773797 = ref object of OpenApiRestCall_772581
proc url_DeleteBasePathMapping_773799(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_773798(path: JsonNode; query: JsonNode;
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
  var valid_773800 = path.getOrDefault("base_path")
  valid_773800 = validateParameter(valid_773800, JString, required = true,
                                 default = nil)
  if valid_773800 != nil:
    section.add "base_path", valid_773800
  var valid_773801 = path.getOrDefault("domain_name")
  valid_773801 = validateParameter(valid_773801, JString, required = true,
                                 default = nil)
  if valid_773801 != nil:
    section.add "domain_name", valid_773801
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773802 = header.getOrDefault("X-Amz-Date")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Date", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Security-Token")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Security-Token", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Content-Sha256", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-Algorithm")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Algorithm", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Signature")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Signature", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-SignedHeaders", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Credential")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Credential", valid_773808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773809: Call_DeleteBasePathMapping_773797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_773809.validator(path, query, header, formData, body)
  let scheme = call_773809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773809.url(scheme.get, call_773809.host, call_773809.base,
                         call_773809.route, valid.getOrDefault("path"))
  result = hook(call_773809, url, valid)

proc call*(call_773810: Call_DeleteBasePathMapping_773797; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_773811 = newJObject()
  add(path_773811, "base_path", newJString(basePath))
  add(path_773811, "domain_name", newJString(domainName))
  result = call_773810.call(path_773811, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_773797(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_773798, base: "/",
    url: url_DeleteBasePathMapping_773799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_773829 = ref object of OpenApiRestCall_772581
proc url_GetClientCertificate_773831(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_773830(path: JsonNode; query: JsonNode;
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
  var valid_773832 = path.getOrDefault("clientcertificate_id")
  valid_773832 = validateParameter(valid_773832, JString, required = true,
                                 default = nil)
  if valid_773832 != nil:
    section.add "clientcertificate_id", valid_773832
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773833 = header.getOrDefault("X-Amz-Date")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Date", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Security-Token")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Security-Token", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Content-Sha256", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Algorithm")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Algorithm", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Signature")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Signature", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-SignedHeaders", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Credential")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Credential", valid_773839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773840: Call_GetClientCertificate_773829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_773840.validator(path, query, header, formData, body)
  let scheme = call_773840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773840.url(scheme.get, call_773840.host, call_773840.base,
                         call_773840.route, valid.getOrDefault("path"))
  result = hook(call_773840, url, valid)

proc call*(call_773841: Call_GetClientCertificate_773829;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_773842 = newJObject()
  add(path_773842, "clientcertificate_id", newJString(clientcertificateId))
  result = call_773841.call(path_773842, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_773829(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_773830, base: "/",
    url: url_GetClientCertificate_773831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_773857 = ref object of OpenApiRestCall_772581
proc url_UpdateClientCertificate_773859(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_773858(path: JsonNode; query: JsonNode;
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
  var valid_773860 = path.getOrDefault("clientcertificate_id")
  valid_773860 = validateParameter(valid_773860, JString, required = true,
                                 default = nil)
  if valid_773860 != nil:
    section.add "clientcertificate_id", valid_773860
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773861 = header.getOrDefault("X-Amz-Date")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Date", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Security-Token")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Security-Token", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Content-Sha256", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Algorithm")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Algorithm", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-Signature")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Signature", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-SignedHeaders", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-Credential")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Credential", valid_773867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773869: Call_UpdateClientCertificate_773857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_773869.validator(path, query, header, formData, body)
  let scheme = call_773869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773869.url(scheme.get, call_773869.host, call_773869.base,
                         call_773869.route, valid.getOrDefault("path"))
  result = hook(call_773869, url, valid)

proc call*(call_773870: Call_UpdateClientCertificate_773857;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_773871 = newJObject()
  var body_773872 = newJObject()
  add(path_773871, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_773872 = body
  result = call_773870.call(path_773871, nil, nil, nil, body_773872)

var updateClientCertificate* = Call_UpdateClientCertificate_773857(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_773858, base: "/",
    url: url_UpdateClientCertificate_773859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_773843 = ref object of OpenApiRestCall_772581
proc url_DeleteClientCertificate_773845(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_773844(path: JsonNode; query: JsonNode;
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
  var valid_773846 = path.getOrDefault("clientcertificate_id")
  valid_773846 = validateParameter(valid_773846, JString, required = true,
                                 default = nil)
  if valid_773846 != nil:
    section.add "clientcertificate_id", valid_773846
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773847 = header.getOrDefault("X-Amz-Date")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Date", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Security-Token")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Security-Token", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Content-Sha256", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Algorithm")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Algorithm", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Signature")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Signature", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-SignedHeaders", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Credential")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Credential", valid_773853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773854: Call_DeleteClientCertificate_773843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_773854.validator(path, query, header, formData, body)
  let scheme = call_773854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773854.url(scheme.get, call_773854.host, call_773854.base,
                         call_773854.route, valid.getOrDefault("path"))
  result = hook(call_773854, url, valid)

proc call*(call_773855: Call_DeleteClientCertificate_773843;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_773856 = newJObject()
  add(path_773856, "clientcertificate_id", newJString(clientcertificateId))
  result = call_773855.call(path_773856, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_773843(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_773844, base: "/",
    url: url_DeleteClientCertificate_773845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_773873 = ref object of OpenApiRestCall_772581
proc url_GetDeployment_773875(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_773874(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773876 = path.getOrDefault("deployment_id")
  valid_773876 = validateParameter(valid_773876, JString, required = true,
                                 default = nil)
  if valid_773876 != nil:
    section.add "deployment_id", valid_773876
  var valid_773877 = path.getOrDefault("restapi_id")
  valid_773877 = validateParameter(valid_773877, JString, required = true,
                                 default = nil)
  if valid_773877 != nil:
    section.add "restapi_id", valid_773877
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_773878 = query.getOrDefault("embed")
  valid_773878 = validateParameter(valid_773878, JArray, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "embed", valid_773878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773879 = header.getOrDefault("X-Amz-Date")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Date", valid_773879
  var valid_773880 = header.getOrDefault("X-Amz-Security-Token")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Security-Token", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Content-Sha256", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Algorithm")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Algorithm", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Signature")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Signature", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-SignedHeaders", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Credential")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Credential", valid_773885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773886: Call_GetDeployment_773873; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_773886.validator(path, query, header, formData, body)
  let scheme = call_773886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773886.url(scheme.get, call_773886.host, call_773886.base,
                         call_773886.route, valid.getOrDefault("path"))
  result = hook(call_773886, url, valid)

proc call*(call_773887: Call_GetDeployment_773873; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773888 = newJObject()
  var query_773889 = newJObject()
  add(path_773888, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_773889.add "embed", embed
  add(path_773888, "restapi_id", newJString(restapiId))
  result = call_773887.call(path_773888, query_773889, nil, nil, nil)

var getDeployment* = Call_GetDeployment_773873(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_773874, base: "/", url: url_GetDeployment_773875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_773905 = ref object of OpenApiRestCall_772581
proc url_UpdateDeployment_773907(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_773906(path: JsonNode; query: JsonNode;
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
  var valid_773908 = path.getOrDefault("deployment_id")
  valid_773908 = validateParameter(valid_773908, JString, required = true,
                                 default = nil)
  if valid_773908 != nil:
    section.add "deployment_id", valid_773908
  var valid_773909 = path.getOrDefault("restapi_id")
  valid_773909 = validateParameter(valid_773909, JString, required = true,
                                 default = nil)
  if valid_773909 != nil:
    section.add "restapi_id", valid_773909
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773910 = header.getOrDefault("X-Amz-Date")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Date", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Security-Token")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Security-Token", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Content-Sha256", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Algorithm")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Algorithm", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Signature")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Signature", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-SignedHeaders", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Credential")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Credential", valid_773916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773918: Call_UpdateDeployment_773905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_773918.validator(path, query, header, formData, body)
  let scheme = call_773918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773918.url(scheme.get, call_773918.host, call_773918.base,
                         call_773918.route, valid.getOrDefault("path"))
  result = hook(call_773918, url, valid)

proc call*(call_773919: Call_UpdateDeployment_773905; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773920 = newJObject()
  var body_773921 = newJObject()
  add(path_773920, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_773921 = body
  add(path_773920, "restapi_id", newJString(restapiId))
  result = call_773919.call(path_773920, nil, nil, nil, body_773921)

var updateDeployment* = Call_UpdateDeployment_773905(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_773906, base: "/",
    url: url_UpdateDeployment_773907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_773890 = ref object of OpenApiRestCall_772581
proc url_DeleteDeployment_773892(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_773891(path: JsonNode; query: JsonNode;
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
  var valid_773893 = path.getOrDefault("deployment_id")
  valid_773893 = validateParameter(valid_773893, JString, required = true,
                                 default = nil)
  if valid_773893 != nil:
    section.add "deployment_id", valid_773893
  var valid_773894 = path.getOrDefault("restapi_id")
  valid_773894 = validateParameter(valid_773894, JString, required = true,
                                 default = nil)
  if valid_773894 != nil:
    section.add "restapi_id", valid_773894
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773895 = header.getOrDefault("X-Amz-Date")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Date", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Security-Token")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Security-Token", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Content-Sha256", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Algorithm")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Algorithm", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Signature")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Signature", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-SignedHeaders", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-Credential")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-Credential", valid_773901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773902: Call_DeleteDeployment_773890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_773902.validator(path, query, header, formData, body)
  let scheme = call_773902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773902.url(scheme.get, call_773902.host, call_773902.base,
                         call_773902.route, valid.getOrDefault("path"))
  result = hook(call_773902, url, valid)

proc call*(call_773903: Call_DeleteDeployment_773890; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773904 = newJObject()
  add(path_773904, "deployment_id", newJString(deploymentId))
  add(path_773904, "restapi_id", newJString(restapiId))
  result = call_773903.call(path_773904, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_773890(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_773891, base: "/",
    url: url_DeleteDeployment_773892, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_773922 = ref object of OpenApiRestCall_772581
proc url_GetDocumentationPart_773924(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_773923(path: JsonNode; query: JsonNode;
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
  var valid_773925 = path.getOrDefault("part_id")
  valid_773925 = validateParameter(valid_773925, JString, required = true,
                                 default = nil)
  if valid_773925 != nil:
    section.add "part_id", valid_773925
  var valid_773926 = path.getOrDefault("restapi_id")
  valid_773926 = validateParameter(valid_773926, JString, required = true,
                                 default = nil)
  if valid_773926 != nil:
    section.add "restapi_id", valid_773926
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773927 = header.getOrDefault("X-Amz-Date")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Date", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Security-Token")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Security-Token", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Content-Sha256", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Algorithm")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Algorithm", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-Signature")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-Signature", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-SignedHeaders", valid_773932
  var valid_773933 = header.getOrDefault("X-Amz-Credential")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Credential", valid_773933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773934: Call_GetDocumentationPart_773922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773934.validator(path, query, header, formData, body)
  let scheme = call_773934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773934.url(scheme.get, call_773934.host, call_773934.base,
                         call_773934.route, valid.getOrDefault("path"))
  result = hook(call_773934, url, valid)

proc call*(call_773935: Call_GetDocumentationPart_773922; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773936 = newJObject()
  add(path_773936, "part_id", newJString(partId))
  add(path_773936, "restapi_id", newJString(restapiId))
  result = call_773935.call(path_773936, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_773922(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_773923, base: "/",
    url: url_GetDocumentationPart_773924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_773952 = ref object of OpenApiRestCall_772581
proc url_UpdateDocumentationPart_773954(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_773953(path: JsonNode; query: JsonNode;
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
  var valid_773955 = path.getOrDefault("part_id")
  valid_773955 = validateParameter(valid_773955, JString, required = true,
                                 default = nil)
  if valid_773955 != nil:
    section.add "part_id", valid_773955
  var valid_773956 = path.getOrDefault("restapi_id")
  valid_773956 = validateParameter(valid_773956, JString, required = true,
                                 default = nil)
  if valid_773956 != nil:
    section.add "restapi_id", valid_773956
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773957 = header.getOrDefault("X-Amz-Date")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Date", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Security-Token")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Security-Token", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Content-Sha256", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-Algorithm")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Algorithm", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-Signature")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Signature", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-SignedHeaders", valid_773962
  var valid_773963 = header.getOrDefault("X-Amz-Credential")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Credential", valid_773963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773965: Call_UpdateDocumentationPart_773952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773965.validator(path, query, header, formData, body)
  let scheme = call_773965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773965.url(scheme.get, call_773965.host, call_773965.base,
                         call_773965.route, valid.getOrDefault("path"))
  result = hook(call_773965, url, valid)

proc call*(call_773966: Call_UpdateDocumentationPart_773952; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773967 = newJObject()
  var body_773968 = newJObject()
  if body != nil:
    body_773968 = body
  add(path_773967, "part_id", newJString(partId))
  add(path_773967, "restapi_id", newJString(restapiId))
  result = call_773966.call(path_773967, nil, nil, nil, body_773968)

var updateDocumentationPart* = Call_UpdateDocumentationPart_773952(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_773953, base: "/",
    url: url_UpdateDocumentationPart_773954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_773937 = ref object of OpenApiRestCall_772581
proc url_DeleteDocumentationPart_773939(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_773938(path: JsonNode; query: JsonNode;
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
  var valid_773940 = path.getOrDefault("part_id")
  valid_773940 = validateParameter(valid_773940, JString, required = true,
                                 default = nil)
  if valid_773940 != nil:
    section.add "part_id", valid_773940
  var valid_773941 = path.getOrDefault("restapi_id")
  valid_773941 = validateParameter(valid_773941, JString, required = true,
                                 default = nil)
  if valid_773941 != nil:
    section.add "restapi_id", valid_773941
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773942 = header.getOrDefault("X-Amz-Date")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Date", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Security-Token")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Security-Token", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-Content-Sha256", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Algorithm")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Algorithm", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-Signature")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-Signature", valid_773946
  var valid_773947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-SignedHeaders", valid_773947
  var valid_773948 = header.getOrDefault("X-Amz-Credential")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-Credential", valid_773948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773949: Call_DeleteDocumentationPart_773937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773949.validator(path, query, header, formData, body)
  let scheme = call_773949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773949.url(scheme.get, call_773949.host, call_773949.base,
                         call_773949.route, valid.getOrDefault("path"))
  result = hook(call_773949, url, valid)

proc call*(call_773950: Call_DeleteDocumentationPart_773937; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773951 = newJObject()
  add(path_773951, "part_id", newJString(partId))
  add(path_773951, "restapi_id", newJString(restapiId))
  result = call_773950.call(path_773951, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_773937(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_773938, base: "/",
    url: url_DeleteDocumentationPart_773939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_773969 = ref object of OpenApiRestCall_772581
proc url_GetDocumentationVersion_773971(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_773970(path: JsonNode; query: JsonNode;
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
  var valid_773972 = path.getOrDefault("doc_version")
  valid_773972 = validateParameter(valid_773972, JString, required = true,
                                 default = nil)
  if valid_773972 != nil:
    section.add "doc_version", valid_773972
  var valid_773973 = path.getOrDefault("restapi_id")
  valid_773973 = validateParameter(valid_773973, JString, required = true,
                                 default = nil)
  if valid_773973 != nil:
    section.add "restapi_id", valid_773973
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773974 = header.getOrDefault("X-Amz-Date")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-Date", valid_773974
  var valid_773975 = header.getOrDefault("X-Amz-Security-Token")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-Security-Token", valid_773975
  var valid_773976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "X-Amz-Content-Sha256", valid_773976
  var valid_773977 = header.getOrDefault("X-Amz-Algorithm")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Algorithm", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Signature")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Signature", valid_773978
  var valid_773979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-SignedHeaders", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Credential")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Credential", valid_773980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773981: Call_GetDocumentationVersion_773969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773981.validator(path, query, header, formData, body)
  let scheme = call_773981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773981.url(scheme.get, call_773981.host, call_773981.base,
                         call_773981.route, valid.getOrDefault("path"))
  result = hook(call_773981, url, valid)

proc call*(call_773982: Call_GetDocumentationVersion_773969; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773983 = newJObject()
  add(path_773983, "doc_version", newJString(docVersion))
  add(path_773983, "restapi_id", newJString(restapiId))
  result = call_773982.call(path_773983, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_773969(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_773970, base: "/",
    url: url_GetDocumentationVersion_773971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_773999 = ref object of OpenApiRestCall_772581
proc url_UpdateDocumentationVersion_774001(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_774000(path: JsonNode; query: JsonNode;
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
  var valid_774002 = path.getOrDefault("doc_version")
  valid_774002 = validateParameter(valid_774002, JString, required = true,
                                 default = nil)
  if valid_774002 != nil:
    section.add "doc_version", valid_774002
  var valid_774003 = path.getOrDefault("restapi_id")
  valid_774003 = validateParameter(valid_774003, JString, required = true,
                                 default = nil)
  if valid_774003 != nil:
    section.add "restapi_id", valid_774003
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774004 = header.getOrDefault("X-Amz-Date")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Date", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Security-Token")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Security-Token", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Content-Sha256", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Algorithm")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Algorithm", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Signature")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Signature", valid_774008
  var valid_774009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-SignedHeaders", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Credential")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Credential", valid_774010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774012: Call_UpdateDocumentationVersion_773999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774012.validator(path, query, header, formData, body)
  let scheme = call_774012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774012.url(scheme.get, call_774012.host, call_774012.base,
                         call_774012.route, valid.getOrDefault("path"))
  result = hook(call_774012, url, valid)

proc call*(call_774013: Call_UpdateDocumentationVersion_773999; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_774014 = newJObject()
  var body_774015 = newJObject()
  add(path_774014, "doc_version", newJString(docVersion))
  if body != nil:
    body_774015 = body
  add(path_774014, "restapi_id", newJString(restapiId))
  result = call_774013.call(path_774014, nil, nil, nil, body_774015)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_773999(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_774000, base: "/",
    url: url_UpdateDocumentationVersion_774001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_773984 = ref object of OpenApiRestCall_772581
proc url_DeleteDocumentationVersion_773986(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_773985(path: JsonNode; query: JsonNode;
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
  var valid_773987 = path.getOrDefault("doc_version")
  valid_773987 = validateParameter(valid_773987, JString, required = true,
                                 default = nil)
  if valid_773987 != nil:
    section.add "doc_version", valid_773987
  var valid_773988 = path.getOrDefault("restapi_id")
  valid_773988 = validateParameter(valid_773988, JString, required = true,
                                 default = nil)
  if valid_773988 != nil:
    section.add "restapi_id", valid_773988
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773989 = header.getOrDefault("X-Amz-Date")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Date", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Security-Token")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Security-Token", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Content-Sha256", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Algorithm")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Algorithm", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Signature")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Signature", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-SignedHeaders", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-Credential")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Credential", valid_773995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773996: Call_DeleteDocumentationVersion_773984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773996.validator(path, query, header, formData, body)
  let scheme = call_773996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773996.url(scheme.get, call_773996.host, call_773996.base,
                         call_773996.route, valid.getOrDefault("path"))
  result = hook(call_773996, url, valid)

proc call*(call_773997: Call_DeleteDocumentationVersion_773984; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_773998 = newJObject()
  add(path_773998, "doc_version", newJString(docVersion))
  add(path_773998, "restapi_id", newJString(restapiId))
  result = call_773997.call(path_773998, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_773984(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_773985, base: "/",
    url: url_DeleteDocumentationVersion_773986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_774016 = ref object of OpenApiRestCall_772581
proc url_GetDomainName_774018(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_774017(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774019 = path.getOrDefault("domain_name")
  valid_774019 = validateParameter(valid_774019, JString, required = true,
                                 default = nil)
  if valid_774019 != nil:
    section.add "domain_name", valid_774019
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774020 = header.getOrDefault("X-Amz-Date")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-Date", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-Security-Token")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-Security-Token", valid_774021
  var valid_774022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Content-Sha256", valid_774022
  var valid_774023 = header.getOrDefault("X-Amz-Algorithm")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "X-Amz-Algorithm", valid_774023
  var valid_774024 = header.getOrDefault("X-Amz-Signature")
  valid_774024 = validateParameter(valid_774024, JString, required = false,
                                 default = nil)
  if valid_774024 != nil:
    section.add "X-Amz-Signature", valid_774024
  var valid_774025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-SignedHeaders", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Credential")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Credential", valid_774026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774027: Call_GetDomainName_774016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_774027.validator(path, query, header, formData, body)
  let scheme = call_774027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774027.url(scheme.get, call_774027.host, call_774027.base,
                         call_774027.route, valid.getOrDefault("path"))
  result = hook(call_774027, url, valid)

proc call*(call_774028: Call_GetDomainName_774016; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_774029 = newJObject()
  add(path_774029, "domain_name", newJString(domainName))
  result = call_774028.call(path_774029, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_774016(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_774017,
    base: "/", url: url_GetDomainName_774018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_774044 = ref object of OpenApiRestCall_772581
proc url_UpdateDomainName_774046(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_774045(path: JsonNode; query: JsonNode;
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
  var valid_774047 = path.getOrDefault("domain_name")
  valid_774047 = validateParameter(valid_774047, JString, required = true,
                                 default = nil)
  if valid_774047 != nil:
    section.add "domain_name", valid_774047
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774048 = header.getOrDefault("X-Amz-Date")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "X-Amz-Date", valid_774048
  var valid_774049 = header.getOrDefault("X-Amz-Security-Token")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Security-Token", valid_774049
  var valid_774050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-Content-Sha256", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-Algorithm")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Algorithm", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Signature")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Signature", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-SignedHeaders", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-Credential")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-Credential", valid_774054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774056: Call_UpdateDomainName_774044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_774056.validator(path, query, header, formData, body)
  let scheme = call_774056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774056.url(scheme.get, call_774056.host, call_774056.base,
                         call_774056.route, valid.getOrDefault("path"))
  result = hook(call_774056, url, valid)

proc call*(call_774057: Call_UpdateDomainName_774044; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_774058 = newJObject()
  var body_774059 = newJObject()
  add(path_774058, "domain_name", newJString(domainName))
  if body != nil:
    body_774059 = body
  result = call_774057.call(path_774058, nil, nil, nil, body_774059)

var updateDomainName* = Call_UpdateDomainName_774044(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_774045,
    base: "/", url: url_UpdateDomainName_774046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_774030 = ref object of OpenApiRestCall_772581
proc url_DeleteDomainName_774032(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_774031(path: JsonNode; query: JsonNode;
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
  var valid_774033 = path.getOrDefault("domain_name")
  valid_774033 = validateParameter(valid_774033, JString, required = true,
                                 default = nil)
  if valid_774033 != nil:
    section.add "domain_name", valid_774033
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774034 = header.getOrDefault("X-Amz-Date")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Date", valid_774034
  var valid_774035 = header.getOrDefault("X-Amz-Security-Token")
  valid_774035 = validateParameter(valid_774035, JString, required = false,
                                 default = nil)
  if valid_774035 != nil:
    section.add "X-Amz-Security-Token", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Content-Sha256", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Algorithm")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Algorithm", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Signature")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Signature", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-SignedHeaders", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Credential")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Credential", valid_774040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774041: Call_DeleteDomainName_774030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_774041.validator(path, query, header, formData, body)
  let scheme = call_774041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774041.url(scheme.get, call_774041.host, call_774041.base,
                         call_774041.route, valid.getOrDefault("path"))
  result = hook(call_774041, url, valid)

proc call*(call_774042: Call_DeleteDomainName_774030; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_774043 = newJObject()
  add(path_774043, "domain_name", newJString(domainName))
  result = call_774042.call(path_774043, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_774030(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_774031,
    base: "/", url: url_DeleteDomainName_774032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_774075 = ref object of OpenApiRestCall_772581
proc url_PutGatewayResponse_774077(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_774076(path: JsonNode; query: JsonNode;
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
  var valid_774078 = path.getOrDefault("response_type")
  valid_774078 = validateParameter(valid_774078, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_774078 != nil:
    section.add "response_type", valid_774078
  var valid_774079 = path.getOrDefault("restapi_id")
  valid_774079 = validateParameter(valid_774079, JString, required = true,
                                 default = nil)
  if valid_774079 != nil:
    section.add "restapi_id", valid_774079
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774080 = header.getOrDefault("X-Amz-Date")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Date", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-Security-Token")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-Security-Token", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Content-Sha256", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-Algorithm")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Algorithm", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Signature")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Signature", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-SignedHeaders", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Credential")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Credential", valid_774086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774088: Call_PutGatewayResponse_774075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_774088.validator(path, query, header, formData, body)
  let scheme = call_774088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774088.url(scheme.get, call_774088.host, call_774088.base,
                         call_774088.route, valid.getOrDefault("path"))
  result = hook(call_774088, url, valid)

proc call*(call_774089: Call_PutGatewayResponse_774075; body: JsonNode;
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
  var path_774090 = newJObject()
  var body_774091 = newJObject()
  add(path_774090, "response_type", newJString(responseType))
  if body != nil:
    body_774091 = body
  add(path_774090, "restapi_id", newJString(restapiId))
  result = call_774089.call(path_774090, nil, nil, nil, body_774091)

var putGatewayResponse* = Call_PutGatewayResponse_774075(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_774076, base: "/",
    url: url_PutGatewayResponse_774077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_774060 = ref object of OpenApiRestCall_772581
proc url_GetGatewayResponse_774062(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_774061(path: JsonNode; query: JsonNode;
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
  var valid_774063 = path.getOrDefault("response_type")
  valid_774063 = validateParameter(valid_774063, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_774063 != nil:
    section.add "response_type", valid_774063
  var valid_774064 = path.getOrDefault("restapi_id")
  valid_774064 = validateParameter(valid_774064, JString, required = true,
                                 default = nil)
  if valid_774064 != nil:
    section.add "restapi_id", valid_774064
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774065 = header.getOrDefault("X-Amz-Date")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Date", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-Security-Token")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-Security-Token", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Content-Sha256", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-Algorithm")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-Algorithm", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Signature")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Signature", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-SignedHeaders", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Credential")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Credential", valid_774071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774072: Call_GetGatewayResponse_774060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_774072.validator(path, query, header, formData, body)
  let scheme = call_774072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774072.url(scheme.get, call_774072.host, call_774072.base,
                         call_774072.route, valid.getOrDefault("path"))
  result = hook(call_774072, url, valid)

proc call*(call_774073: Call_GetGatewayResponse_774060; restapiId: string;
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
  var path_774074 = newJObject()
  add(path_774074, "response_type", newJString(responseType))
  add(path_774074, "restapi_id", newJString(restapiId))
  result = call_774073.call(path_774074, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_774060(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_774061, base: "/",
    url: url_GetGatewayResponse_774062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_774107 = ref object of OpenApiRestCall_772581
proc url_UpdateGatewayResponse_774109(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_774108(path: JsonNode; query: JsonNode;
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
  var valid_774110 = path.getOrDefault("response_type")
  valid_774110 = validateParameter(valid_774110, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_774110 != nil:
    section.add "response_type", valid_774110
  var valid_774111 = path.getOrDefault("restapi_id")
  valid_774111 = validateParameter(valid_774111, JString, required = true,
                                 default = nil)
  if valid_774111 != nil:
    section.add "restapi_id", valid_774111
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774112 = header.getOrDefault("X-Amz-Date")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Date", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Security-Token")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Security-Token", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Content-Sha256", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Algorithm")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Algorithm", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Signature")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Signature", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-SignedHeaders", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Credential")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Credential", valid_774118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774120: Call_UpdateGatewayResponse_774107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_774120.validator(path, query, header, formData, body)
  let scheme = call_774120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774120.url(scheme.get, call_774120.host, call_774120.base,
                         call_774120.route, valid.getOrDefault("path"))
  result = hook(call_774120, url, valid)

proc call*(call_774121: Call_UpdateGatewayResponse_774107; body: JsonNode;
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
  var path_774122 = newJObject()
  var body_774123 = newJObject()
  add(path_774122, "response_type", newJString(responseType))
  if body != nil:
    body_774123 = body
  add(path_774122, "restapi_id", newJString(restapiId))
  result = call_774121.call(path_774122, nil, nil, nil, body_774123)

var updateGatewayResponse* = Call_UpdateGatewayResponse_774107(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_774108, base: "/",
    url: url_UpdateGatewayResponse_774109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_774092 = ref object of OpenApiRestCall_772581
proc url_DeleteGatewayResponse_774094(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_774093(path: JsonNode; query: JsonNode;
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
  var valid_774095 = path.getOrDefault("response_type")
  valid_774095 = validateParameter(valid_774095, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_774095 != nil:
    section.add "response_type", valid_774095
  var valid_774096 = path.getOrDefault("restapi_id")
  valid_774096 = validateParameter(valid_774096, JString, required = true,
                                 default = nil)
  if valid_774096 != nil:
    section.add "restapi_id", valid_774096
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774097 = header.getOrDefault("X-Amz-Date")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Date", valid_774097
  var valid_774098 = header.getOrDefault("X-Amz-Security-Token")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Security-Token", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Content-Sha256", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Algorithm")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Algorithm", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Signature")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Signature", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-SignedHeaders", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Credential")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Credential", valid_774103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774104: Call_DeleteGatewayResponse_774092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_774104.validator(path, query, header, formData, body)
  let scheme = call_774104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774104.url(scheme.get, call_774104.host, call_774104.base,
                         call_774104.route, valid.getOrDefault("path"))
  result = hook(call_774104, url, valid)

proc call*(call_774105: Call_DeleteGatewayResponse_774092; restapiId: string;
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
  var path_774106 = newJObject()
  add(path_774106, "response_type", newJString(responseType))
  add(path_774106, "restapi_id", newJString(restapiId))
  result = call_774105.call(path_774106, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_774092(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_774093, base: "/",
    url: url_DeleteGatewayResponse_774094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_774140 = ref object of OpenApiRestCall_772581
proc url_PutIntegration_774142(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_774141(path: JsonNode; query: JsonNode;
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
  var valid_774143 = path.getOrDefault("http_method")
  valid_774143 = validateParameter(valid_774143, JString, required = true,
                                 default = nil)
  if valid_774143 != nil:
    section.add "http_method", valid_774143
  var valid_774144 = path.getOrDefault("restapi_id")
  valid_774144 = validateParameter(valid_774144, JString, required = true,
                                 default = nil)
  if valid_774144 != nil:
    section.add "restapi_id", valid_774144
  var valid_774145 = path.getOrDefault("resource_id")
  valid_774145 = validateParameter(valid_774145, JString, required = true,
                                 default = nil)
  if valid_774145 != nil:
    section.add "resource_id", valid_774145
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774146 = header.getOrDefault("X-Amz-Date")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Date", valid_774146
  var valid_774147 = header.getOrDefault("X-Amz-Security-Token")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Security-Token", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Content-Sha256", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Algorithm")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Algorithm", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Signature")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Signature", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-SignedHeaders", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Credential")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Credential", valid_774152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774154: Call_PutIntegration_774140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_774154.validator(path, query, header, formData, body)
  let scheme = call_774154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774154.url(scheme.get, call_774154.host, call_774154.base,
                         call_774154.route, valid.getOrDefault("path"))
  result = hook(call_774154, url, valid)

proc call*(call_774155: Call_PutIntegration_774140; httpMethod: string;
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
  var path_774156 = newJObject()
  var body_774157 = newJObject()
  add(path_774156, "http_method", newJString(httpMethod))
  if body != nil:
    body_774157 = body
  add(path_774156, "restapi_id", newJString(restapiId))
  add(path_774156, "resource_id", newJString(resourceId))
  result = call_774155.call(path_774156, nil, nil, nil, body_774157)

var putIntegration* = Call_PutIntegration_774140(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_774141, base: "/", url: url_PutIntegration_774142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_774124 = ref object of OpenApiRestCall_772581
proc url_GetIntegration_774126(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_774125(path: JsonNode; query: JsonNode;
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
  var valid_774127 = path.getOrDefault("http_method")
  valid_774127 = validateParameter(valid_774127, JString, required = true,
                                 default = nil)
  if valid_774127 != nil:
    section.add "http_method", valid_774127
  var valid_774128 = path.getOrDefault("restapi_id")
  valid_774128 = validateParameter(valid_774128, JString, required = true,
                                 default = nil)
  if valid_774128 != nil:
    section.add "restapi_id", valid_774128
  var valid_774129 = path.getOrDefault("resource_id")
  valid_774129 = validateParameter(valid_774129, JString, required = true,
                                 default = nil)
  if valid_774129 != nil:
    section.add "resource_id", valid_774129
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774130 = header.getOrDefault("X-Amz-Date")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Date", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Security-Token")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Security-Token", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Content-Sha256", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Algorithm")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Algorithm", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-Signature")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Signature", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-SignedHeaders", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Credential")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Credential", valid_774136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774137: Call_GetIntegration_774124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_774137.validator(path, query, header, formData, body)
  let scheme = call_774137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774137.url(scheme.get, call_774137.host, call_774137.base,
                         call_774137.route, valid.getOrDefault("path"))
  result = hook(call_774137, url, valid)

proc call*(call_774138: Call_GetIntegration_774124; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_774139 = newJObject()
  add(path_774139, "http_method", newJString(httpMethod))
  add(path_774139, "restapi_id", newJString(restapiId))
  add(path_774139, "resource_id", newJString(resourceId))
  result = call_774138.call(path_774139, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_774124(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_774125, base: "/", url: url_GetIntegration_774126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_774174 = ref object of OpenApiRestCall_772581
proc url_UpdateIntegration_774176(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_774175(path: JsonNode; query: JsonNode;
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
  var valid_774177 = path.getOrDefault("http_method")
  valid_774177 = validateParameter(valid_774177, JString, required = true,
                                 default = nil)
  if valid_774177 != nil:
    section.add "http_method", valid_774177
  var valid_774178 = path.getOrDefault("restapi_id")
  valid_774178 = validateParameter(valid_774178, JString, required = true,
                                 default = nil)
  if valid_774178 != nil:
    section.add "restapi_id", valid_774178
  var valid_774179 = path.getOrDefault("resource_id")
  valid_774179 = validateParameter(valid_774179, JString, required = true,
                                 default = nil)
  if valid_774179 != nil:
    section.add "resource_id", valid_774179
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774180 = header.getOrDefault("X-Amz-Date")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Date", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-Security-Token")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Security-Token", valid_774181
  var valid_774182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "X-Amz-Content-Sha256", valid_774182
  var valid_774183 = header.getOrDefault("X-Amz-Algorithm")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-Algorithm", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Signature")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Signature", valid_774184
  var valid_774185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "X-Amz-SignedHeaders", valid_774185
  var valid_774186 = header.getOrDefault("X-Amz-Credential")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-Credential", valid_774186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774188: Call_UpdateIntegration_774174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_774188.validator(path, query, header, formData, body)
  let scheme = call_774188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774188.url(scheme.get, call_774188.host, call_774188.base,
                         call_774188.route, valid.getOrDefault("path"))
  result = hook(call_774188, url, valid)

proc call*(call_774189: Call_UpdateIntegration_774174; httpMethod: string;
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
  var path_774190 = newJObject()
  var body_774191 = newJObject()
  add(path_774190, "http_method", newJString(httpMethod))
  if body != nil:
    body_774191 = body
  add(path_774190, "restapi_id", newJString(restapiId))
  add(path_774190, "resource_id", newJString(resourceId))
  result = call_774189.call(path_774190, nil, nil, nil, body_774191)

var updateIntegration* = Call_UpdateIntegration_774174(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_774175, base: "/",
    url: url_UpdateIntegration_774176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_774158 = ref object of OpenApiRestCall_772581
proc url_DeleteIntegration_774160(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_774159(path: JsonNode; query: JsonNode;
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
  var valid_774161 = path.getOrDefault("http_method")
  valid_774161 = validateParameter(valid_774161, JString, required = true,
                                 default = nil)
  if valid_774161 != nil:
    section.add "http_method", valid_774161
  var valid_774162 = path.getOrDefault("restapi_id")
  valid_774162 = validateParameter(valid_774162, JString, required = true,
                                 default = nil)
  if valid_774162 != nil:
    section.add "restapi_id", valid_774162
  var valid_774163 = path.getOrDefault("resource_id")
  valid_774163 = validateParameter(valid_774163, JString, required = true,
                                 default = nil)
  if valid_774163 != nil:
    section.add "resource_id", valid_774163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774164 = header.getOrDefault("X-Amz-Date")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Date", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Security-Token")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Security-Token", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Content-Sha256", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Algorithm")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Algorithm", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Signature")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Signature", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-SignedHeaders", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Credential")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Credential", valid_774170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774171: Call_DeleteIntegration_774158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_774171.validator(path, query, header, formData, body)
  let scheme = call_774171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774171.url(scheme.get, call_774171.host, call_774171.base,
                         call_774171.route, valid.getOrDefault("path"))
  result = hook(call_774171, url, valid)

proc call*(call_774172: Call_DeleteIntegration_774158; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_774173 = newJObject()
  add(path_774173, "http_method", newJString(httpMethod))
  add(path_774173, "restapi_id", newJString(restapiId))
  add(path_774173, "resource_id", newJString(resourceId))
  result = call_774172.call(path_774173, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_774158(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_774159, base: "/",
    url: url_DeleteIntegration_774160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_774209 = ref object of OpenApiRestCall_772581
proc url_PutIntegrationResponse_774211(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_774210(path: JsonNode; query: JsonNode;
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
  var valid_774212 = path.getOrDefault("http_method")
  valid_774212 = validateParameter(valid_774212, JString, required = true,
                                 default = nil)
  if valid_774212 != nil:
    section.add "http_method", valid_774212
  var valid_774213 = path.getOrDefault("status_code")
  valid_774213 = validateParameter(valid_774213, JString, required = true,
                                 default = nil)
  if valid_774213 != nil:
    section.add "status_code", valid_774213
  var valid_774214 = path.getOrDefault("restapi_id")
  valid_774214 = validateParameter(valid_774214, JString, required = true,
                                 default = nil)
  if valid_774214 != nil:
    section.add "restapi_id", valid_774214
  var valid_774215 = path.getOrDefault("resource_id")
  valid_774215 = validateParameter(valid_774215, JString, required = true,
                                 default = nil)
  if valid_774215 != nil:
    section.add "resource_id", valid_774215
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774216 = header.getOrDefault("X-Amz-Date")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "X-Amz-Date", valid_774216
  var valid_774217 = header.getOrDefault("X-Amz-Security-Token")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-Security-Token", valid_774217
  var valid_774218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Content-Sha256", valid_774218
  var valid_774219 = header.getOrDefault("X-Amz-Algorithm")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "X-Amz-Algorithm", valid_774219
  var valid_774220 = header.getOrDefault("X-Amz-Signature")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-Signature", valid_774220
  var valid_774221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "X-Amz-SignedHeaders", valid_774221
  var valid_774222 = header.getOrDefault("X-Amz-Credential")
  valid_774222 = validateParameter(valid_774222, JString, required = false,
                                 default = nil)
  if valid_774222 != nil:
    section.add "X-Amz-Credential", valid_774222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774224: Call_PutIntegrationResponse_774209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_774224.validator(path, query, header, formData, body)
  let scheme = call_774224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774224.url(scheme.get, call_774224.host, call_774224.base,
                         call_774224.route, valid.getOrDefault("path"))
  result = hook(call_774224, url, valid)

proc call*(call_774225: Call_PutIntegrationResponse_774209; httpMethod: string;
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
  var path_774226 = newJObject()
  var body_774227 = newJObject()
  add(path_774226, "http_method", newJString(httpMethod))
  add(path_774226, "status_code", newJString(statusCode))
  if body != nil:
    body_774227 = body
  add(path_774226, "restapi_id", newJString(restapiId))
  add(path_774226, "resource_id", newJString(resourceId))
  result = call_774225.call(path_774226, nil, nil, nil, body_774227)

var putIntegrationResponse* = Call_PutIntegrationResponse_774209(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_774210, base: "/",
    url: url_PutIntegrationResponse_774211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_774192 = ref object of OpenApiRestCall_772581
proc url_GetIntegrationResponse_774194(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_774193(path: JsonNode; query: JsonNode;
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
  var valid_774195 = path.getOrDefault("http_method")
  valid_774195 = validateParameter(valid_774195, JString, required = true,
                                 default = nil)
  if valid_774195 != nil:
    section.add "http_method", valid_774195
  var valid_774196 = path.getOrDefault("status_code")
  valid_774196 = validateParameter(valid_774196, JString, required = true,
                                 default = nil)
  if valid_774196 != nil:
    section.add "status_code", valid_774196
  var valid_774197 = path.getOrDefault("restapi_id")
  valid_774197 = validateParameter(valid_774197, JString, required = true,
                                 default = nil)
  if valid_774197 != nil:
    section.add "restapi_id", valid_774197
  var valid_774198 = path.getOrDefault("resource_id")
  valid_774198 = validateParameter(valid_774198, JString, required = true,
                                 default = nil)
  if valid_774198 != nil:
    section.add "resource_id", valid_774198
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774199 = header.getOrDefault("X-Amz-Date")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Date", valid_774199
  var valid_774200 = header.getOrDefault("X-Amz-Security-Token")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "X-Amz-Security-Token", valid_774200
  var valid_774201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-Content-Sha256", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-Algorithm")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Algorithm", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Signature")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Signature", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-SignedHeaders", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Credential")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Credential", valid_774205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774206: Call_GetIntegrationResponse_774192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_774206.validator(path, query, header, formData, body)
  let scheme = call_774206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774206.url(scheme.get, call_774206.host, call_774206.base,
                         call_774206.route, valid.getOrDefault("path"))
  result = hook(call_774206, url, valid)

proc call*(call_774207: Call_GetIntegrationResponse_774192; httpMethod: string;
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
  var path_774208 = newJObject()
  add(path_774208, "http_method", newJString(httpMethod))
  add(path_774208, "status_code", newJString(statusCode))
  add(path_774208, "restapi_id", newJString(restapiId))
  add(path_774208, "resource_id", newJString(resourceId))
  result = call_774207.call(path_774208, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_774192(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_774193, base: "/",
    url: url_GetIntegrationResponse_774194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_774245 = ref object of OpenApiRestCall_772581
proc url_UpdateIntegrationResponse_774247(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_774246(path: JsonNode; query: JsonNode;
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
  var valid_774248 = path.getOrDefault("http_method")
  valid_774248 = validateParameter(valid_774248, JString, required = true,
                                 default = nil)
  if valid_774248 != nil:
    section.add "http_method", valid_774248
  var valid_774249 = path.getOrDefault("status_code")
  valid_774249 = validateParameter(valid_774249, JString, required = true,
                                 default = nil)
  if valid_774249 != nil:
    section.add "status_code", valid_774249
  var valid_774250 = path.getOrDefault("restapi_id")
  valid_774250 = validateParameter(valid_774250, JString, required = true,
                                 default = nil)
  if valid_774250 != nil:
    section.add "restapi_id", valid_774250
  var valid_774251 = path.getOrDefault("resource_id")
  valid_774251 = validateParameter(valid_774251, JString, required = true,
                                 default = nil)
  if valid_774251 != nil:
    section.add "resource_id", valid_774251
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774252 = header.getOrDefault("X-Amz-Date")
  valid_774252 = validateParameter(valid_774252, JString, required = false,
                                 default = nil)
  if valid_774252 != nil:
    section.add "X-Amz-Date", valid_774252
  var valid_774253 = header.getOrDefault("X-Amz-Security-Token")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-Security-Token", valid_774253
  var valid_774254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "X-Amz-Content-Sha256", valid_774254
  var valid_774255 = header.getOrDefault("X-Amz-Algorithm")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Algorithm", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-Signature")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-Signature", valid_774256
  var valid_774257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-SignedHeaders", valid_774257
  var valid_774258 = header.getOrDefault("X-Amz-Credential")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Credential", valid_774258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774260: Call_UpdateIntegrationResponse_774245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_774260.validator(path, query, header, formData, body)
  let scheme = call_774260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774260.url(scheme.get, call_774260.host, call_774260.base,
                         call_774260.route, valid.getOrDefault("path"))
  result = hook(call_774260, url, valid)

proc call*(call_774261: Call_UpdateIntegrationResponse_774245; httpMethod: string;
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
  var path_774262 = newJObject()
  var body_774263 = newJObject()
  add(path_774262, "http_method", newJString(httpMethod))
  add(path_774262, "status_code", newJString(statusCode))
  if body != nil:
    body_774263 = body
  add(path_774262, "restapi_id", newJString(restapiId))
  add(path_774262, "resource_id", newJString(resourceId))
  result = call_774261.call(path_774262, nil, nil, nil, body_774263)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_774245(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_774246, base: "/",
    url: url_UpdateIntegrationResponse_774247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_774228 = ref object of OpenApiRestCall_772581
proc url_DeleteIntegrationResponse_774230(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_774229(path: JsonNode; query: JsonNode;
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
  var valid_774231 = path.getOrDefault("http_method")
  valid_774231 = validateParameter(valid_774231, JString, required = true,
                                 default = nil)
  if valid_774231 != nil:
    section.add "http_method", valid_774231
  var valid_774232 = path.getOrDefault("status_code")
  valid_774232 = validateParameter(valid_774232, JString, required = true,
                                 default = nil)
  if valid_774232 != nil:
    section.add "status_code", valid_774232
  var valid_774233 = path.getOrDefault("restapi_id")
  valid_774233 = validateParameter(valid_774233, JString, required = true,
                                 default = nil)
  if valid_774233 != nil:
    section.add "restapi_id", valid_774233
  var valid_774234 = path.getOrDefault("resource_id")
  valid_774234 = validateParameter(valid_774234, JString, required = true,
                                 default = nil)
  if valid_774234 != nil:
    section.add "resource_id", valid_774234
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774235 = header.getOrDefault("X-Amz-Date")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Date", valid_774235
  var valid_774236 = header.getOrDefault("X-Amz-Security-Token")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "X-Amz-Security-Token", valid_774236
  var valid_774237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Content-Sha256", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-Algorithm")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Algorithm", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Signature")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Signature", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-SignedHeaders", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Credential")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Credential", valid_774241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774242: Call_DeleteIntegrationResponse_774228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_774242.validator(path, query, header, formData, body)
  let scheme = call_774242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774242.url(scheme.get, call_774242.host, call_774242.base,
                         call_774242.route, valid.getOrDefault("path"))
  result = hook(call_774242, url, valid)

proc call*(call_774243: Call_DeleteIntegrationResponse_774228; httpMethod: string;
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
  var path_774244 = newJObject()
  add(path_774244, "http_method", newJString(httpMethod))
  add(path_774244, "status_code", newJString(statusCode))
  add(path_774244, "restapi_id", newJString(restapiId))
  add(path_774244, "resource_id", newJString(resourceId))
  result = call_774243.call(path_774244, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_774228(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_774229, base: "/",
    url: url_DeleteIntegrationResponse_774230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_774280 = ref object of OpenApiRestCall_772581
proc url_PutMethod_774282(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_774281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774283 = path.getOrDefault("http_method")
  valid_774283 = validateParameter(valid_774283, JString, required = true,
                                 default = nil)
  if valid_774283 != nil:
    section.add "http_method", valid_774283
  var valid_774284 = path.getOrDefault("restapi_id")
  valid_774284 = validateParameter(valid_774284, JString, required = true,
                                 default = nil)
  if valid_774284 != nil:
    section.add "restapi_id", valid_774284
  var valid_774285 = path.getOrDefault("resource_id")
  valid_774285 = validateParameter(valid_774285, JString, required = true,
                                 default = nil)
  if valid_774285 != nil:
    section.add "resource_id", valid_774285
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774286 = header.getOrDefault("X-Amz-Date")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Date", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Security-Token")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Security-Token", valid_774287
  var valid_774288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "X-Amz-Content-Sha256", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-Algorithm")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Algorithm", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Signature")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Signature", valid_774290
  var valid_774291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-SignedHeaders", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-Credential")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-Credential", valid_774292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774294: Call_PutMethod_774280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_774294.validator(path, query, header, formData, body)
  let scheme = call_774294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774294.url(scheme.get, call_774294.host, call_774294.base,
                         call_774294.route, valid.getOrDefault("path"))
  result = hook(call_774294, url, valid)

proc call*(call_774295: Call_PutMethod_774280; httpMethod: string; body: JsonNode;
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
  var path_774296 = newJObject()
  var body_774297 = newJObject()
  add(path_774296, "http_method", newJString(httpMethod))
  if body != nil:
    body_774297 = body
  add(path_774296, "restapi_id", newJString(restapiId))
  add(path_774296, "resource_id", newJString(resourceId))
  result = call_774295.call(path_774296, nil, nil, nil, body_774297)

var putMethod* = Call_PutMethod_774280(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_774281,
                                    base: "/", url: url_PutMethod_774282,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_774298 = ref object of OpenApiRestCall_772581
proc url_TestInvokeMethod_774300(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_774299(path: JsonNode; query: JsonNode;
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
  var valid_774301 = path.getOrDefault("http_method")
  valid_774301 = validateParameter(valid_774301, JString, required = true,
                                 default = nil)
  if valid_774301 != nil:
    section.add "http_method", valid_774301
  var valid_774302 = path.getOrDefault("restapi_id")
  valid_774302 = validateParameter(valid_774302, JString, required = true,
                                 default = nil)
  if valid_774302 != nil:
    section.add "restapi_id", valid_774302
  var valid_774303 = path.getOrDefault("resource_id")
  valid_774303 = validateParameter(valid_774303, JString, required = true,
                                 default = nil)
  if valid_774303 != nil:
    section.add "resource_id", valid_774303
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774304 = header.getOrDefault("X-Amz-Date")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Date", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Security-Token")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Security-Token", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Content-Sha256", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Algorithm")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Algorithm", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Signature")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Signature", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-SignedHeaders", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-Credential")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-Credential", valid_774310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774312: Call_TestInvokeMethod_774298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_774312.validator(path, query, header, formData, body)
  let scheme = call_774312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774312.url(scheme.get, call_774312.host, call_774312.base,
                         call_774312.route, valid.getOrDefault("path"))
  result = hook(call_774312, url, valid)

proc call*(call_774313: Call_TestInvokeMethod_774298; httpMethod: string;
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
  var path_774314 = newJObject()
  var body_774315 = newJObject()
  add(path_774314, "http_method", newJString(httpMethod))
  if body != nil:
    body_774315 = body
  add(path_774314, "restapi_id", newJString(restapiId))
  add(path_774314, "resource_id", newJString(resourceId))
  result = call_774313.call(path_774314, nil, nil, nil, body_774315)

var testInvokeMethod* = Call_TestInvokeMethod_774298(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_774299, base: "/",
    url: url_TestInvokeMethod_774300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_774264 = ref object of OpenApiRestCall_772581
proc url_GetMethod_774266(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_774265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774267 = path.getOrDefault("http_method")
  valid_774267 = validateParameter(valid_774267, JString, required = true,
                                 default = nil)
  if valid_774267 != nil:
    section.add "http_method", valid_774267
  var valid_774268 = path.getOrDefault("restapi_id")
  valid_774268 = validateParameter(valid_774268, JString, required = true,
                                 default = nil)
  if valid_774268 != nil:
    section.add "restapi_id", valid_774268
  var valid_774269 = path.getOrDefault("resource_id")
  valid_774269 = validateParameter(valid_774269, JString, required = true,
                                 default = nil)
  if valid_774269 != nil:
    section.add "resource_id", valid_774269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774270 = header.getOrDefault("X-Amz-Date")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "X-Amz-Date", valid_774270
  var valid_774271 = header.getOrDefault("X-Amz-Security-Token")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-Security-Token", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Content-Sha256", valid_774272
  var valid_774273 = header.getOrDefault("X-Amz-Algorithm")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "X-Amz-Algorithm", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Signature")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Signature", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-SignedHeaders", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Credential")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Credential", valid_774276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774277: Call_GetMethod_774264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_774277.validator(path, query, header, formData, body)
  let scheme = call_774277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774277.url(scheme.get, call_774277.host, call_774277.base,
                         call_774277.route, valid.getOrDefault("path"))
  result = hook(call_774277, url, valid)

proc call*(call_774278: Call_GetMethod_774264; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_774279 = newJObject()
  add(path_774279, "http_method", newJString(httpMethod))
  add(path_774279, "restapi_id", newJString(restapiId))
  add(path_774279, "resource_id", newJString(resourceId))
  result = call_774278.call(path_774279, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_774264(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_774265,
                                    base: "/", url: url_GetMethod_774266,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_774332 = ref object of OpenApiRestCall_772581
proc url_UpdateMethod_774334(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_774333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774335 = path.getOrDefault("http_method")
  valid_774335 = validateParameter(valid_774335, JString, required = true,
                                 default = nil)
  if valid_774335 != nil:
    section.add "http_method", valid_774335
  var valid_774336 = path.getOrDefault("restapi_id")
  valid_774336 = validateParameter(valid_774336, JString, required = true,
                                 default = nil)
  if valid_774336 != nil:
    section.add "restapi_id", valid_774336
  var valid_774337 = path.getOrDefault("resource_id")
  valid_774337 = validateParameter(valid_774337, JString, required = true,
                                 default = nil)
  if valid_774337 != nil:
    section.add "resource_id", valid_774337
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774338 = header.getOrDefault("X-Amz-Date")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Date", valid_774338
  var valid_774339 = header.getOrDefault("X-Amz-Security-Token")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-Security-Token", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Content-Sha256", valid_774340
  var valid_774341 = header.getOrDefault("X-Amz-Algorithm")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "X-Amz-Algorithm", valid_774341
  var valid_774342 = header.getOrDefault("X-Amz-Signature")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Signature", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-SignedHeaders", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Credential")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Credential", valid_774344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774346: Call_UpdateMethod_774332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_774346.validator(path, query, header, formData, body)
  let scheme = call_774346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774346.url(scheme.get, call_774346.host, call_774346.base,
                         call_774346.route, valid.getOrDefault("path"))
  result = hook(call_774346, url, valid)

proc call*(call_774347: Call_UpdateMethod_774332; httpMethod: string; body: JsonNode;
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
  var path_774348 = newJObject()
  var body_774349 = newJObject()
  add(path_774348, "http_method", newJString(httpMethod))
  if body != nil:
    body_774349 = body
  add(path_774348, "restapi_id", newJString(restapiId))
  add(path_774348, "resource_id", newJString(resourceId))
  result = call_774347.call(path_774348, nil, nil, nil, body_774349)

var updateMethod* = Call_UpdateMethod_774332(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_774333, base: "/", url: url_UpdateMethod_774334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_774316 = ref object of OpenApiRestCall_772581
proc url_DeleteMethod_774318(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_774317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774319 = path.getOrDefault("http_method")
  valid_774319 = validateParameter(valid_774319, JString, required = true,
                                 default = nil)
  if valid_774319 != nil:
    section.add "http_method", valid_774319
  var valid_774320 = path.getOrDefault("restapi_id")
  valid_774320 = validateParameter(valid_774320, JString, required = true,
                                 default = nil)
  if valid_774320 != nil:
    section.add "restapi_id", valid_774320
  var valid_774321 = path.getOrDefault("resource_id")
  valid_774321 = validateParameter(valid_774321, JString, required = true,
                                 default = nil)
  if valid_774321 != nil:
    section.add "resource_id", valid_774321
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774322 = header.getOrDefault("X-Amz-Date")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Date", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-Security-Token")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-Security-Token", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-Content-Sha256", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-Algorithm")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-Algorithm", valid_774325
  var valid_774326 = header.getOrDefault("X-Amz-Signature")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "X-Amz-Signature", valid_774326
  var valid_774327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-SignedHeaders", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-Credential")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-Credential", valid_774328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774329: Call_DeleteMethod_774316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_774329.validator(path, query, header, formData, body)
  let scheme = call_774329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774329.url(scheme.get, call_774329.host, call_774329.base,
                         call_774329.route, valid.getOrDefault("path"))
  result = hook(call_774329, url, valid)

proc call*(call_774330: Call_DeleteMethod_774316; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_774331 = newJObject()
  add(path_774331, "http_method", newJString(httpMethod))
  add(path_774331, "restapi_id", newJString(restapiId))
  add(path_774331, "resource_id", newJString(resourceId))
  result = call_774330.call(path_774331, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_774316(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_774317, base: "/", url: url_DeleteMethod_774318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_774367 = ref object of OpenApiRestCall_772581
proc url_PutMethodResponse_774369(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_774368(path: JsonNode; query: JsonNode;
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
  var valid_774370 = path.getOrDefault("http_method")
  valid_774370 = validateParameter(valid_774370, JString, required = true,
                                 default = nil)
  if valid_774370 != nil:
    section.add "http_method", valid_774370
  var valid_774371 = path.getOrDefault("status_code")
  valid_774371 = validateParameter(valid_774371, JString, required = true,
                                 default = nil)
  if valid_774371 != nil:
    section.add "status_code", valid_774371
  var valid_774372 = path.getOrDefault("restapi_id")
  valid_774372 = validateParameter(valid_774372, JString, required = true,
                                 default = nil)
  if valid_774372 != nil:
    section.add "restapi_id", valid_774372
  var valid_774373 = path.getOrDefault("resource_id")
  valid_774373 = validateParameter(valid_774373, JString, required = true,
                                 default = nil)
  if valid_774373 != nil:
    section.add "resource_id", valid_774373
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774374 = header.getOrDefault("X-Amz-Date")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Date", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-Security-Token")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-Security-Token", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Content-Sha256", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Algorithm")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Algorithm", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Signature")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Signature", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-SignedHeaders", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Credential")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Credential", valid_774380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774382: Call_PutMethodResponse_774367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_774382.validator(path, query, header, formData, body)
  let scheme = call_774382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774382.url(scheme.get, call_774382.host, call_774382.base,
                         call_774382.route, valid.getOrDefault("path"))
  result = hook(call_774382, url, valid)

proc call*(call_774383: Call_PutMethodResponse_774367; httpMethod: string;
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
  var path_774384 = newJObject()
  var body_774385 = newJObject()
  add(path_774384, "http_method", newJString(httpMethod))
  add(path_774384, "status_code", newJString(statusCode))
  if body != nil:
    body_774385 = body
  add(path_774384, "restapi_id", newJString(restapiId))
  add(path_774384, "resource_id", newJString(resourceId))
  result = call_774383.call(path_774384, nil, nil, nil, body_774385)

var putMethodResponse* = Call_PutMethodResponse_774367(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_774368, base: "/",
    url: url_PutMethodResponse_774369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_774350 = ref object of OpenApiRestCall_772581
proc url_GetMethodResponse_774352(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_774351(path: JsonNode; query: JsonNode;
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
  var valid_774353 = path.getOrDefault("http_method")
  valid_774353 = validateParameter(valid_774353, JString, required = true,
                                 default = nil)
  if valid_774353 != nil:
    section.add "http_method", valid_774353
  var valid_774354 = path.getOrDefault("status_code")
  valid_774354 = validateParameter(valid_774354, JString, required = true,
                                 default = nil)
  if valid_774354 != nil:
    section.add "status_code", valid_774354
  var valid_774355 = path.getOrDefault("restapi_id")
  valid_774355 = validateParameter(valid_774355, JString, required = true,
                                 default = nil)
  if valid_774355 != nil:
    section.add "restapi_id", valid_774355
  var valid_774356 = path.getOrDefault("resource_id")
  valid_774356 = validateParameter(valid_774356, JString, required = true,
                                 default = nil)
  if valid_774356 != nil:
    section.add "resource_id", valid_774356
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774357 = header.getOrDefault("X-Amz-Date")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Date", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Security-Token")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Security-Token", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-Content-Sha256", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Algorithm")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Algorithm", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Signature")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Signature", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-SignedHeaders", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-Credential")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-Credential", valid_774363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774364: Call_GetMethodResponse_774350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_774364.validator(path, query, header, formData, body)
  let scheme = call_774364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774364.url(scheme.get, call_774364.host, call_774364.base,
                         call_774364.route, valid.getOrDefault("path"))
  result = hook(call_774364, url, valid)

proc call*(call_774365: Call_GetMethodResponse_774350; httpMethod: string;
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
  var path_774366 = newJObject()
  add(path_774366, "http_method", newJString(httpMethod))
  add(path_774366, "status_code", newJString(statusCode))
  add(path_774366, "restapi_id", newJString(restapiId))
  add(path_774366, "resource_id", newJString(resourceId))
  result = call_774365.call(path_774366, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_774350(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_774351, base: "/",
    url: url_GetMethodResponse_774352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_774403 = ref object of OpenApiRestCall_772581
proc url_UpdateMethodResponse_774405(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_774404(path: JsonNode; query: JsonNode;
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
  var valid_774406 = path.getOrDefault("http_method")
  valid_774406 = validateParameter(valid_774406, JString, required = true,
                                 default = nil)
  if valid_774406 != nil:
    section.add "http_method", valid_774406
  var valid_774407 = path.getOrDefault("status_code")
  valid_774407 = validateParameter(valid_774407, JString, required = true,
                                 default = nil)
  if valid_774407 != nil:
    section.add "status_code", valid_774407
  var valid_774408 = path.getOrDefault("restapi_id")
  valid_774408 = validateParameter(valid_774408, JString, required = true,
                                 default = nil)
  if valid_774408 != nil:
    section.add "restapi_id", valid_774408
  var valid_774409 = path.getOrDefault("resource_id")
  valid_774409 = validateParameter(valid_774409, JString, required = true,
                                 default = nil)
  if valid_774409 != nil:
    section.add "resource_id", valid_774409
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774410 = header.getOrDefault("X-Amz-Date")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Date", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-Security-Token")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-Security-Token", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Content-Sha256", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Algorithm")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Algorithm", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Signature")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Signature", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-SignedHeaders", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Credential")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Credential", valid_774416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774418: Call_UpdateMethodResponse_774403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_774418.validator(path, query, header, formData, body)
  let scheme = call_774418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774418.url(scheme.get, call_774418.host, call_774418.base,
                         call_774418.route, valid.getOrDefault("path"))
  result = hook(call_774418, url, valid)

proc call*(call_774419: Call_UpdateMethodResponse_774403; httpMethod: string;
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
  var path_774420 = newJObject()
  var body_774421 = newJObject()
  add(path_774420, "http_method", newJString(httpMethod))
  add(path_774420, "status_code", newJString(statusCode))
  if body != nil:
    body_774421 = body
  add(path_774420, "restapi_id", newJString(restapiId))
  add(path_774420, "resource_id", newJString(resourceId))
  result = call_774419.call(path_774420, nil, nil, nil, body_774421)

var updateMethodResponse* = Call_UpdateMethodResponse_774403(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_774404, base: "/",
    url: url_UpdateMethodResponse_774405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_774386 = ref object of OpenApiRestCall_772581
proc url_DeleteMethodResponse_774388(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_774387(path: JsonNode; query: JsonNode;
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
  var valid_774389 = path.getOrDefault("http_method")
  valid_774389 = validateParameter(valid_774389, JString, required = true,
                                 default = nil)
  if valid_774389 != nil:
    section.add "http_method", valid_774389
  var valid_774390 = path.getOrDefault("status_code")
  valid_774390 = validateParameter(valid_774390, JString, required = true,
                                 default = nil)
  if valid_774390 != nil:
    section.add "status_code", valid_774390
  var valid_774391 = path.getOrDefault("restapi_id")
  valid_774391 = validateParameter(valid_774391, JString, required = true,
                                 default = nil)
  if valid_774391 != nil:
    section.add "restapi_id", valid_774391
  var valid_774392 = path.getOrDefault("resource_id")
  valid_774392 = validateParameter(valid_774392, JString, required = true,
                                 default = nil)
  if valid_774392 != nil:
    section.add "resource_id", valid_774392
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774393 = header.getOrDefault("X-Amz-Date")
  valid_774393 = validateParameter(valid_774393, JString, required = false,
                                 default = nil)
  if valid_774393 != nil:
    section.add "X-Amz-Date", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-Security-Token")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-Security-Token", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Content-Sha256", valid_774395
  var valid_774396 = header.getOrDefault("X-Amz-Algorithm")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "X-Amz-Algorithm", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-Signature")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Signature", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-SignedHeaders", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Credential")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Credential", valid_774399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774400: Call_DeleteMethodResponse_774386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_774400.validator(path, query, header, formData, body)
  let scheme = call_774400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774400.url(scheme.get, call_774400.host, call_774400.base,
                         call_774400.route, valid.getOrDefault("path"))
  result = hook(call_774400, url, valid)

proc call*(call_774401: Call_DeleteMethodResponse_774386; httpMethod: string;
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
  var path_774402 = newJObject()
  add(path_774402, "http_method", newJString(httpMethod))
  add(path_774402, "status_code", newJString(statusCode))
  add(path_774402, "restapi_id", newJString(restapiId))
  add(path_774402, "resource_id", newJString(resourceId))
  result = call_774401.call(path_774402, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_774386(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_774387, base: "/",
    url: url_DeleteMethodResponse_774388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_774422 = ref object of OpenApiRestCall_772581
proc url_GetModel_774424(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_774423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774425 = path.getOrDefault("model_name")
  valid_774425 = validateParameter(valid_774425, JString, required = true,
                                 default = nil)
  if valid_774425 != nil:
    section.add "model_name", valid_774425
  var valid_774426 = path.getOrDefault("restapi_id")
  valid_774426 = validateParameter(valid_774426, JString, required = true,
                                 default = nil)
  if valid_774426 != nil:
    section.add "restapi_id", valid_774426
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_774427 = query.getOrDefault("flatten")
  valid_774427 = validateParameter(valid_774427, JBool, required = false, default = nil)
  if valid_774427 != nil:
    section.add "flatten", valid_774427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774428 = header.getOrDefault("X-Amz-Date")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-Date", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Security-Token")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Security-Token", valid_774429
  var valid_774430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Content-Sha256", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Algorithm")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Algorithm", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-Signature")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-Signature", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-SignedHeaders", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Credential")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Credential", valid_774434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774435: Call_GetModel_774422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_774435.validator(path, query, header, formData, body)
  let scheme = call_774435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774435.url(scheme.get, call_774435.host, call_774435.base,
                         call_774435.route, valid.getOrDefault("path"))
  result = hook(call_774435, url, valid)

proc call*(call_774436: Call_GetModel_774422; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_774437 = newJObject()
  var query_774438 = newJObject()
  add(query_774438, "flatten", newJBool(flatten))
  add(path_774437, "model_name", newJString(modelName))
  add(path_774437, "restapi_id", newJString(restapiId))
  result = call_774436.call(path_774437, query_774438, nil, nil, nil)

var getModel* = Call_GetModel_774422(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_774423, base: "/",
                                  url: url_GetModel_774424,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_774454 = ref object of OpenApiRestCall_772581
proc url_UpdateModel_774456(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_774455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774457 = path.getOrDefault("model_name")
  valid_774457 = validateParameter(valid_774457, JString, required = true,
                                 default = nil)
  if valid_774457 != nil:
    section.add "model_name", valid_774457
  var valid_774458 = path.getOrDefault("restapi_id")
  valid_774458 = validateParameter(valid_774458, JString, required = true,
                                 default = nil)
  if valid_774458 != nil:
    section.add "restapi_id", valid_774458
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774459 = header.getOrDefault("X-Amz-Date")
  valid_774459 = validateParameter(valid_774459, JString, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "X-Amz-Date", valid_774459
  var valid_774460 = header.getOrDefault("X-Amz-Security-Token")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-Security-Token", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Content-Sha256", valid_774461
  var valid_774462 = header.getOrDefault("X-Amz-Algorithm")
  valid_774462 = validateParameter(valid_774462, JString, required = false,
                                 default = nil)
  if valid_774462 != nil:
    section.add "X-Amz-Algorithm", valid_774462
  var valid_774463 = header.getOrDefault("X-Amz-Signature")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "X-Amz-Signature", valid_774463
  var valid_774464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "X-Amz-SignedHeaders", valid_774464
  var valid_774465 = header.getOrDefault("X-Amz-Credential")
  valid_774465 = validateParameter(valid_774465, JString, required = false,
                                 default = nil)
  if valid_774465 != nil:
    section.add "X-Amz-Credential", valid_774465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774467: Call_UpdateModel_774454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_774467.validator(path, query, header, formData, body)
  let scheme = call_774467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774467.url(scheme.get, call_774467.host, call_774467.base,
                         call_774467.route, valid.getOrDefault("path"))
  result = hook(call_774467, url, valid)

proc call*(call_774468: Call_UpdateModel_774454; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774469 = newJObject()
  var body_774470 = newJObject()
  add(path_774469, "model_name", newJString(modelName))
  if body != nil:
    body_774470 = body
  add(path_774469, "restapi_id", newJString(restapiId))
  result = call_774468.call(path_774469, nil, nil, nil, body_774470)

var updateModel* = Call_UpdateModel_774454(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_774455,
                                        base: "/", url: url_UpdateModel_774456,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_774439 = ref object of OpenApiRestCall_772581
proc url_DeleteModel_774441(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_774440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774442 = path.getOrDefault("model_name")
  valid_774442 = validateParameter(valid_774442, JString, required = true,
                                 default = nil)
  if valid_774442 != nil:
    section.add "model_name", valid_774442
  var valid_774443 = path.getOrDefault("restapi_id")
  valid_774443 = validateParameter(valid_774443, JString, required = true,
                                 default = nil)
  if valid_774443 != nil:
    section.add "restapi_id", valid_774443
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774444 = header.getOrDefault("X-Amz-Date")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Date", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Security-Token")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Security-Token", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Content-Sha256", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Algorithm")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Algorithm", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Signature")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Signature", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-SignedHeaders", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Credential")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Credential", valid_774450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774451: Call_DeleteModel_774439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_774451.validator(path, query, header, formData, body)
  let scheme = call_774451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774451.url(scheme.get, call_774451.host, call_774451.base,
                         call_774451.route, valid.getOrDefault("path"))
  result = hook(call_774451, url, valid)

proc call*(call_774452: Call_DeleteModel_774439; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774453 = newJObject()
  add(path_774453, "model_name", newJString(modelName))
  add(path_774453, "restapi_id", newJString(restapiId))
  result = call_774452.call(path_774453, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_774439(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_774440,
                                        base: "/", url: url_DeleteModel_774441,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_774471 = ref object of OpenApiRestCall_772581
proc url_GetRequestValidator_774473(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_774472(path: JsonNode; query: JsonNode;
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
  var valid_774474 = path.getOrDefault("requestvalidator_id")
  valid_774474 = validateParameter(valid_774474, JString, required = true,
                                 default = nil)
  if valid_774474 != nil:
    section.add "requestvalidator_id", valid_774474
  var valid_774475 = path.getOrDefault("restapi_id")
  valid_774475 = validateParameter(valid_774475, JString, required = true,
                                 default = nil)
  if valid_774475 != nil:
    section.add "restapi_id", valid_774475
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774476 = header.getOrDefault("X-Amz-Date")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Date", valid_774476
  var valid_774477 = header.getOrDefault("X-Amz-Security-Token")
  valid_774477 = validateParameter(valid_774477, JString, required = false,
                                 default = nil)
  if valid_774477 != nil:
    section.add "X-Amz-Security-Token", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Content-Sha256", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Algorithm")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Algorithm", valid_774479
  var valid_774480 = header.getOrDefault("X-Amz-Signature")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Signature", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-SignedHeaders", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Credential")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Credential", valid_774482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774483: Call_GetRequestValidator_774471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_774483.validator(path, query, header, formData, body)
  let scheme = call_774483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774483.url(scheme.get, call_774483.host, call_774483.base,
                         call_774483.route, valid.getOrDefault("path"))
  result = hook(call_774483, url, valid)

proc call*(call_774484: Call_GetRequestValidator_774471;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774485 = newJObject()
  add(path_774485, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_774485, "restapi_id", newJString(restapiId))
  result = call_774484.call(path_774485, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_774471(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_774472, base: "/",
    url: url_GetRequestValidator_774473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_774501 = ref object of OpenApiRestCall_772581
proc url_UpdateRequestValidator_774503(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_774502(path: JsonNode; query: JsonNode;
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
  var valid_774504 = path.getOrDefault("requestvalidator_id")
  valid_774504 = validateParameter(valid_774504, JString, required = true,
                                 default = nil)
  if valid_774504 != nil:
    section.add "requestvalidator_id", valid_774504
  var valid_774505 = path.getOrDefault("restapi_id")
  valid_774505 = validateParameter(valid_774505, JString, required = true,
                                 default = nil)
  if valid_774505 != nil:
    section.add "restapi_id", valid_774505
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774506 = header.getOrDefault("X-Amz-Date")
  valid_774506 = validateParameter(valid_774506, JString, required = false,
                                 default = nil)
  if valid_774506 != nil:
    section.add "X-Amz-Date", valid_774506
  var valid_774507 = header.getOrDefault("X-Amz-Security-Token")
  valid_774507 = validateParameter(valid_774507, JString, required = false,
                                 default = nil)
  if valid_774507 != nil:
    section.add "X-Amz-Security-Token", valid_774507
  var valid_774508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774508 = validateParameter(valid_774508, JString, required = false,
                                 default = nil)
  if valid_774508 != nil:
    section.add "X-Amz-Content-Sha256", valid_774508
  var valid_774509 = header.getOrDefault("X-Amz-Algorithm")
  valid_774509 = validateParameter(valid_774509, JString, required = false,
                                 default = nil)
  if valid_774509 != nil:
    section.add "X-Amz-Algorithm", valid_774509
  var valid_774510 = header.getOrDefault("X-Amz-Signature")
  valid_774510 = validateParameter(valid_774510, JString, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "X-Amz-Signature", valid_774510
  var valid_774511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "X-Amz-SignedHeaders", valid_774511
  var valid_774512 = header.getOrDefault("X-Amz-Credential")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "X-Amz-Credential", valid_774512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774514: Call_UpdateRequestValidator_774501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_774514.validator(path, query, header, formData, body)
  let scheme = call_774514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774514.url(scheme.get, call_774514.host, call_774514.base,
                         call_774514.route, valid.getOrDefault("path"))
  result = hook(call_774514, url, valid)

proc call*(call_774515: Call_UpdateRequestValidator_774501;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774516 = newJObject()
  var body_774517 = newJObject()
  add(path_774516, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_774517 = body
  add(path_774516, "restapi_id", newJString(restapiId))
  result = call_774515.call(path_774516, nil, nil, nil, body_774517)

var updateRequestValidator* = Call_UpdateRequestValidator_774501(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_774502, base: "/",
    url: url_UpdateRequestValidator_774503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_774486 = ref object of OpenApiRestCall_772581
proc url_DeleteRequestValidator_774488(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_774487(path: JsonNode; query: JsonNode;
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
  var valid_774489 = path.getOrDefault("requestvalidator_id")
  valid_774489 = validateParameter(valid_774489, JString, required = true,
                                 default = nil)
  if valid_774489 != nil:
    section.add "requestvalidator_id", valid_774489
  var valid_774490 = path.getOrDefault("restapi_id")
  valid_774490 = validateParameter(valid_774490, JString, required = true,
                                 default = nil)
  if valid_774490 != nil:
    section.add "restapi_id", valid_774490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774491 = header.getOrDefault("X-Amz-Date")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Date", valid_774491
  var valid_774492 = header.getOrDefault("X-Amz-Security-Token")
  valid_774492 = validateParameter(valid_774492, JString, required = false,
                                 default = nil)
  if valid_774492 != nil:
    section.add "X-Amz-Security-Token", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Content-Sha256", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Algorithm")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Algorithm", valid_774494
  var valid_774495 = header.getOrDefault("X-Amz-Signature")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Signature", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-SignedHeaders", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Credential")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Credential", valid_774497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774498: Call_DeleteRequestValidator_774486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_774498.validator(path, query, header, formData, body)
  let scheme = call_774498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774498.url(scheme.get, call_774498.host, call_774498.base,
                         call_774498.route, valid.getOrDefault("path"))
  result = hook(call_774498, url, valid)

proc call*(call_774499: Call_DeleteRequestValidator_774486;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774500 = newJObject()
  add(path_774500, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_774500, "restapi_id", newJString(restapiId))
  result = call_774499.call(path_774500, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_774486(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_774487, base: "/",
    url: url_DeleteRequestValidator_774488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_774518 = ref object of OpenApiRestCall_772581
proc url_GetResource_774520(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_774519(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774521 = path.getOrDefault("restapi_id")
  valid_774521 = validateParameter(valid_774521, JString, required = true,
                                 default = nil)
  if valid_774521 != nil:
    section.add "restapi_id", valid_774521
  var valid_774522 = path.getOrDefault("resource_id")
  valid_774522 = validateParameter(valid_774522, JString, required = true,
                                 default = nil)
  if valid_774522 != nil:
    section.add "resource_id", valid_774522
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_774523 = query.getOrDefault("embed")
  valid_774523 = validateParameter(valid_774523, JArray, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "embed", valid_774523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774524 = header.getOrDefault("X-Amz-Date")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Date", valid_774524
  var valid_774525 = header.getOrDefault("X-Amz-Security-Token")
  valid_774525 = validateParameter(valid_774525, JString, required = false,
                                 default = nil)
  if valid_774525 != nil:
    section.add "X-Amz-Security-Token", valid_774525
  var valid_774526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774526 = validateParameter(valid_774526, JString, required = false,
                                 default = nil)
  if valid_774526 != nil:
    section.add "X-Amz-Content-Sha256", valid_774526
  var valid_774527 = header.getOrDefault("X-Amz-Algorithm")
  valid_774527 = validateParameter(valid_774527, JString, required = false,
                                 default = nil)
  if valid_774527 != nil:
    section.add "X-Amz-Algorithm", valid_774527
  var valid_774528 = header.getOrDefault("X-Amz-Signature")
  valid_774528 = validateParameter(valid_774528, JString, required = false,
                                 default = nil)
  if valid_774528 != nil:
    section.add "X-Amz-Signature", valid_774528
  var valid_774529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774529 = validateParameter(valid_774529, JString, required = false,
                                 default = nil)
  if valid_774529 != nil:
    section.add "X-Amz-SignedHeaders", valid_774529
  var valid_774530 = header.getOrDefault("X-Amz-Credential")
  valid_774530 = validateParameter(valid_774530, JString, required = false,
                                 default = nil)
  if valid_774530 != nil:
    section.add "X-Amz-Credential", valid_774530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774531: Call_GetResource_774518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_774531.validator(path, query, header, formData, body)
  let scheme = call_774531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774531.url(scheme.get, call_774531.host, call_774531.base,
                         call_774531.route, valid.getOrDefault("path"))
  result = hook(call_774531, url, valid)

proc call*(call_774532: Call_GetResource_774518; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_774533 = newJObject()
  var query_774534 = newJObject()
  if embed != nil:
    query_774534.add "embed", embed
  add(path_774533, "restapi_id", newJString(restapiId))
  add(path_774533, "resource_id", newJString(resourceId))
  result = call_774532.call(path_774533, query_774534, nil, nil, nil)

var getResource* = Call_GetResource_774518(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_774519,
                                        base: "/", url: url_GetResource_774520,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_774550 = ref object of OpenApiRestCall_772581
proc url_UpdateResource_774552(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_774551(path: JsonNode; query: JsonNode;
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
  var valid_774553 = path.getOrDefault("restapi_id")
  valid_774553 = validateParameter(valid_774553, JString, required = true,
                                 default = nil)
  if valid_774553 != nil:
    section.add "restapi_id", valid_774553
  var valid_774554 = path.getOrDefault("resource_id")
  valid_774554 = validateParameter(valid_774554, JString, required = true,
                                 default = nil)
  if valid_774554 != nil:
    section.add "resource_id", valid_774554
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774555 = header.getOrDefault("X-Amz-Date")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Date", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-Security-Token")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-Security-Token", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Content-Sha256", valid_774557
  var valid_774558 = header.getOrDefault("X-Amz-Algorithm")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "X-Amz-Algorithm", valid_774558
  var valid_774559 = header.getOrDefault("X-Amz-Signature")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-Signature", valid_774559
  var valid_774560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774560 = validateParameter(valid_774560, JString, required = false,
                                 default = nil)
  if valid_774560 != nil:
    section.add "X-Amz-SignedHeaders", valid_774560
  var valid_774561 = header.getOrDefault("X-Amz-Credential")
  valid_774561 = validateParameter(valid_774561, JString, required = false,
                                 default = nil)
  if valid_774561 != nil:
    section.add "X-Amz-Credential", valid_774561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774563: Call_UpdateResource_774550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_774563.validator(path, query, header, formData, body)
  let scheme = call_774563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774563.url(scheme.get, call_774563.host, call_774563.base,
                         call_774563.route, valid.getOrDefault("path"))
  result = hook(call_774563, url, valid)

proc call*(call_774564: Call_UpdateResource_774550; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_774565 = newJObject()
  var body_774566 = newJObject()
  if body != nil:
    body_774566 = body
  add(path_774565, "restapi_id", newJString(restapiId))
  add(path_774565, "resource_id", newJString(resourceId))
  result = call_774564.call(path_774565, nil, nil, nil, body_774566)

var updateResource* = Call_UpdateResource_774550(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_774551, base: "/", url: url_UpdateResource_774552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_774535 = ref object of OpenApiRestCall_772581
proc url_DeleteResource_774537(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_774536(path: JsonNode; query: JsonNode;
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
  var valid_774538 = path.getOrDefault("restapi_id")
  valid_774538 = validateParameter(valid_774538, JString, required = true,
                                 default = nil)
  if valid_774538 != nil:
    section.add "restapi_id", valid_774538
  var valid_774539 = path.getOrDefault("resource_id")
  valid_774539 = validateParameter(valid_774539, JString, required = true,
                                 default = nil)
  if valid_774539 != nil:
    section.add "resource_id", valid_774539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774540 = header.getOrDefault("X-Amz-Date")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "X-Amz-Date", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-Security-Token")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-Security-Token", valid_774541
  var valid_774542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "X-Amz-Content-Sha256", valid_774542
  var valid_774543 = header.getOrDefault("X-Amz-Algorithm")
  valid_774543 = validateParameter(valid_774543, JString, required = false,
                                 default = nil)
  if valid_774543 != nil:
    section.add "X-Amz-Algorithm", valid_774543
  var valid_774544 = header.getOrDefault("X-Amz-Signature")
  valid_774544 = validateParameter(valid_774544, JString, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "X-Amz-Signature", valid_774544
  var valid_774545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774545 = validateParameter(valid_774545, JString, required = false,
                                 default = nil)
  if valid_774545 != nil:
    section.add "X-Amz-SignedHeaders", valid_774545
  var valid_774546 = header.getOrDefault("X-Amz-Credential")
  valid_774546 = validateParameter(valid_774546, JString, required = false,
                                 default = nil)
  if valid_774546 != nil:
    section.add "X-Amz-Credential", valid_774546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774547: Call_DeleteResource_774535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_774547.validator(path, query, header, formData, body)
  let scheme = call_774547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774547.url(scheme.get, call_774547.host, call_774547.base,
                         call_774547.route, valid.getOrDefault("path"))
  result = hook(call_774547, url, valid)

proc call*(call_774548: Call_DeleteResource_774535; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_774549 = newJObject()
  add(path_774549, "restapi_id", newJString(restapiId))
  add(path_774549, "resource_id", newJString(resourceId))
  result = call_774548.call(path_774549, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_774535(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_774536, base: "/", url: url_DeleteResource_774537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_774581 = ref object of OpenApiRestCall_772581
proc url_PutRestApi_774583(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_774582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774584 = path.getOrDefault("restapi_id")
  valid_774584 = validateParameter(valid_774584, JString, required = true,
                                 default = nil)
  if valid_774584 != nil:
    section.add "restapi_id", valid_774584
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
  var valid_774585 = query.getOrDefault("parameters.0.value")
  valid_774585 = validateParameter(valid_774585, JString, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "parameters.0.value", valid_774585
  var valid_774586 = query.getOrDefault("parameters.2.value")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "parameters.2.value", valid_774586
  var valid_774587 = query.getOrDefault("parameters.1.key")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "parameters.1.key", valid_774587
  var valid_774588 = query.getOrDefault("mode")
  valid_774588 = validateParameter(valid_774588, JString, required = false,
                                 default = newJString("merge"))
  if valid_774588 != nil:
    section.add "mode", valid_774588
  var valid_774589 = query.getOrDefault("parameters.0.key")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "parameters.0.key", valid_774589
  var valid_774590 = query.getOrDefault("parameters.2.key")
  valid_774590 = validateParameter(valid_774590, JString, required = false,
                                 default = nil)
  if valid_774590 != nil:
    section.add "parameters.2.key", valid_774590
  var valid_774591 = query.getOrDefault("failonwarnings")
  valid_774591 = validateParameter(valid_774591, JBool, required = false, default = nil)
  if valid_774591 != nil:
    section.add "failonwarnings", valid_774591
  var valid_774592 = query.getOrDefault("parameters.1.value")
  valid_774592 = validateParameter(valid_774592, JString, required = false,
                                 default = nil)
  if valid_774592 != nil:
    section.add "parameters.1.value", valid_774592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774593 = header.getOrDefault("X-Amz-Date")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "X-Amz-Date", valid_774593
  var valid_774594 = header.getOrDefault("X-Amz-Security-Token")
  valid_774594 = validateParameter(valid_774594, JString, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "X-Amz-Security-Token", valid_774594
  var valid_774595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "X-Amz-Content-Sha256", valid_774595
  var valid_774596 = header.getOrDefault("X-Amz-Algorithm")
  valid_774596 = validateParameter(valid_774596, JString, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "X-Amz-Algorithm", valid_774596
  var valid_774597 = header.getOrDefault("X-Amz-Signature")
  valid_774597 = validateParameter(valid_774597, JString, required = false,
                                 default = nil)
  if valid_774597 != nil:
    section.add "X-Amz-Signature", valid_774597
  var valid_774598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "X-Amz-SignedHeaders", valid_774598
  var valid_774599 = header.getOrDefault("X-Amz-Credential")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "X-Amz-Credential", valid_774599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774601: Call_PutRestApi_774581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_774601.validator(path, query, header, formData, body)
  let scheme = call_774601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774601.url(scheme.get, call_774601.host, call_774601.base,
                         call_774601.route, valid.getOrDefault("path"))
  result = hook(call_774601, url, valid)

proc call*(call_774602: Call_PutRestApi_774581; body: JsonNode; restapiId: string;
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
  var path_774603 = newJObject()
  var query_774604 = newJObject()
  var body_774605 = newJObject()
  add(query_774604, "parameters.0.value", newJString(parameters0Value))
  add(query_774604, "parameters.2.value", newJString(parameters2Value))
  add(query_774604, "parameters.1.key", newJString(parameters1Key))
  add(query_774604, "mode", newJString(mode))
  add(query_774604, "parameters.0.key", newJString(parameters0Key))
  add(query_774604, "parameters.2.key", newJString(parameters2Key))
  add(query_774604, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_774605 = body
  add(query_774604, "parameters.1.value", newJString(parameters1Value))
  add(path_774603, "restapi_id", newJString(restapiId))
  result = call_774602.call(path_774603, query_774604, nil, nil, body_774605)

var putRestApi* = Call_PutRestApi_774581(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_774582,
                                      base: "/", url: url_PutRestApi_774583,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_774567 = ref object of OpenApiRestCall_772581
proc url_GetRestApi_774569(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_774568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774570 = path.getOrDefault("restapi_id")
  valid_774570 = validateParameter(valid_774570, JString, required = true,
                                 default = nil)
  if valid_774570 != nil:
    section.add "restapi_id", valid_774570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774571 = header.getOrDefault("X-Amz-Date")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Date", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Security-Token")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Security-Token", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-Content-Sha256", valid_774573
  var valid_774574 = header.getOrDefault("X-Amz-Algorithm")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-Algorithm", valid_774574
  var valid_774575 = header.getOrDefault("X-Amz-Signature")
  valid_774575 = validateParameter(valid_774575, JString, required = false,
                                 default = nil)
  if valid_774575 != nil:
    section.add "X-Amz-Signature", valid_774575
  var valid_774576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774576 = validateParameter(valid_774576, JString, required = false,
                                 default = nil)
  if valid_774576 != nil:
    section.add "X-Amz-SignedHeaders", valid_774576
  var valid_774577 = header.getOrDefault("X-Amz-Credential")
  valid_774577 = validateParameter(valid_774577, JString, required = false,
                                 default = nil)
  if valid_774577 != nil:
    section.add "X-Amz-Credential", valid_774577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774578: Call_GetRestApi_774567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_774578.validator(path, query, header, formData, body)
  let scheme = call_774578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774578.url(scheme.get, call_774578.host, call_774578.base,
                         call_774578.route, valid.getOrDefault("path"))
  result = hook(call_774578, url, valid)

proc call*(call_774579: Call_GetRestApi_774567; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774580 = newJObject()
  add(path_774580, "restapi_id", newJString(restapiId))
  result = call_774579.call(path_774580, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_774567(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_774568,
                                      base: "/", url: url_GetRestApi_774569,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_774620 = ref object of OpenApiRestCall_772581
proc url_UpdateRestApi_774622(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_774621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774623 = path.getOrDefault("restapi_id")
  valid_774623 = validateParameter(valid_774623, JString, required = true,
                                 default = nil)
  if valid_774623 != nil:
    section.add "restapi_id", valid_774623
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774624 = header.getOrDefault("X-Amz-Date")
  valid_774624 = validateParameter(valid_774624, JString, required = false,
                                 default = nil)
  if valid_774624 != nil:
    section.add "X-Amz-Date", valid_774624
  var valid_774625 = header.getOrDefault("X-Amz-Security-Token")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Security-Token", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Content-Sha256", valid_774626
  var valid_774627 = header.getOrDefault("X-Amz-Algorithm")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "X-Amz-Algorithm", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Signature")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Signature", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-SignedHeaders", valid_774629
  var valid_774630 = header.getOrDefault("X-Amz-Credential")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Credential", valid_774630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774632: Call_UpdateRestApi_774620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_774632.validator(path, query, header, formData, body)
  let scheme = call_774632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774632.url(scheme.get, call_774632.host, call_774632.base,
                         call_774632.route, valid.getOrDefault("path"))
  result = hook(call_774632, url, valid)

proc call*(call_774633: Call_UpdateRestApi_774620; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774634 = newJObject()
  var body_774635 = newJObject()
  if body != nil:
    body_774635 = body
  add(path_774634, "restapi_id", newJString(restapiId))
  result = call_774633.call(path_774634, nil, nil, nil, body_774635)

var updateRestApi* = Call_UpdateRestApi_774620(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_774621,
    base: "/", url: url_UpdateRestApi_774622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_774606 = ref object of OpenApiRestCall_772581
proc url_DeleteRestApi_774608(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_774607(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774609 = path.getOrDefault("restapi_id")
  valid_774609 = validateParameter(valid_774609, JString, required = true,
                                 default = nil)
  if valid_774609 != nil:
    section.add "restapi_id", valid_774609
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774610 = header.getOrDefault("X-Amz-Date")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Date", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Security-Token")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Security-Token", valid_774611
  var valid_774612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "X-Amz-Content-Sha256", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Algorithm")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Algorithm", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Signature")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Signature", valid_774614
  var valid_774615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774615 = validateParameter(valid_774615, JString, required = false,
                                 default = nil)
  if valid_774615 != nil:
    section.add "X-Amz-SignedHeaders", valid_774615
  var valid_774616 = header.getOrDefault("X-Amz-Credential")
  valid_774616 = validateParameter(valid_774616, JString, required = false,
                                 default = nil)
  if valid_774616 != nil:
    section.add "X-Amz-Credential", valid_774616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774617: Call_DeleteRestApi_774606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_774617.validator(path, query, header, formData, body)
  let scheme = call_774617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774617.url(scheme.get, call_774617.host, call_774617.base,
                         call_774617.route, valid.getOrDefault("path"))
  result = hook(call_774617, url, valid)

proc call*(call_774618: Call_DeleteRestApi_774606; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774619 = newJObject()
  add(path_774619, "restapi_id", newJString(restapiId))
  result = call_774618.call(path_774619, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_774606(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_774607,
    base: "/", url: url_DeleteRestApi_774608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_774636 = ref object of OpenApiRestCall_772581
proc url_GetStage_774638(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_774637(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774639 = path.getOrDefault("stage_name")
  valid_774639 = validateParameter(valid_774639, JString, required = true,
                                 default = nil)
  if valid_774639 != nil:
    section.add "stage_name", valid_774639
  var valid_774640 = path.getOrDefault("restapi_id")
  valid_774640 = validateParameter(valid_774640, JString, required = true,
                                 default = nil)
  if valid_774640 != nil:
    section.add "restapi_id", valid_774640
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774641 = header.getOrDefault("X-Amz-Date")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "X-Amz-Date", valid_774641
  var valid_774642 = header.getOrDefault("X-Amz-Security-Token")
  valid_774642 = validateParameter(valid_774642, JString, required = false,
                                 default = nil)
  if valid_774642 != nil:
    section.add "X-Amz-Security-Token", valid_774642
  var valid_774643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-Content-Sha256", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-Algorithm")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-Algorithm", valid_774644
  var valid_774645 = header.getOrDefault("X-Amz-Signature")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "X-Amz-Signature", valid_774645
  var valid_774646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "X-Amz-SignedHeaders", valid_774646
  var valid_774647 = header.getOrDefault("X-Amz-Credential")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "X-Amz-Credential", valid_774647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774648: Call_GetStage_774636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_774648.validator(path, query, header, formData, body)
  let scheme = call_774648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774648.url(scheme.get, call_774648.host, call_774648.base,
                         call_774648.route, valid.getOrDefault("path"))
  result = hook(call_774648, url, valid)

proc call*(call_774649: Call_GetStage_774636; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774650 = newJObject()
  add(path_774650, "stage_name", newJString(stageName))
  add(path_774650, "restapi_id", newJString(restapiId))
  result = call_774649.call(path_774650, nil, nil, nil, nil)

var getStage* = Call_GetStage_774636(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_774637, base: "/",
                                  url: url_GetStage_774638,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_774666 = ref object of OpenApiRestCall_772581
proc url_UpdateStage_774668(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_774667(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774669 = path.getOrDefault("stage_name")
  valid_774669 = validateParameter(valid_774669, JString, required = true,
                                 default = nil)
  if valid_774669 != nil:
    section.add "stage_name", valid_774669
  var valid_774670 = path.getOrDefault("restapi_id")
  valid_774670 = validateParameter(valid_774670, JString, required = true,
                                 default = nil)
  if valid_774670 != nil:
    section.add "restapi_id", valid_774670
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774671 = header.getOrDefault("X-Amz-Date")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-Date", valid_774671
  var valid_774672 = header.getOrDefault("X-Amz-Security-Token")
  valid_774672 = validateParameter(valid_774672, JString, required = false,
                                 default = nil)
  if valid_774672 != nil:
    section.add "X-Amz-Security-Token", valid_774672
  var valid_774673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-Content-Sha256", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Algorithm")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Algorithm", valid_774674
  var valid_774675 = header.getOrDefault("X-Amz-Signature")
  valid_774675 = validateParameter(valid_774675, JString, required = false,
                                 default = nil)
  if valid_774675 != nil:
    section.add "X-Amz-Signature", valid_774675
  var valid_774676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "X-Amz-SignedHeaders", valid_774676
  var valid_774677 = header.getOrDefault("X-Amz-Credential")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "X-Amz-Credential", valid_774677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774679: Call_UpdateStage_774666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_774679.validator(path, query, header, formData, body)
  let scheme = call_774679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774679.url(scheme.get, call_774679.host, call_774679.base,
                         call_774679.route, valid.getOrDefault("path"))
  result = hook(call_774679, url, valid)

proc call*(call_774680: Call_UpdateStage_774666; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774681 = newJObject()
  var body_774682 = newJObject()
  if body != nil:
    body_774682 = body
  add(path_774681, "stage_name", newJString(stageName))
  add(path_774681, "restapi_id", newJString(restapiId))
  result = call_774680.call(path_774681, nil, nil, nil, body_774682)

var updateStage* = Call_UpdateStage_774666(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_774667,
                                        base: "/", url: url_UpdateStage_774668,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_774651 = ref object of OpenApiRestCall_772581
proc url_DeleteStage_774653(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_774652(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774654 = path.getOrDefault("stage_name")
  valid_774654 = validateParameter(valid_774654, JString, required = true,
                                 default = nil)
  if valid_774654 != nil:
    section.add "stage_name", valid_774654
  var valid_774655 = path.getOrDefault("restapi_id")
  valid_774655 = validateParameter(valid_774655, JString, required = true,
                                 default = nil)
  if valid_774655 != nil:
    section.add "restapi_id", valid_774655
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774656 = header.getOrDefault("X-Amz-Date")
  valid_774656 = validateParameter(valid_774656, JString, required = false,
                                 default = nil)
  if valid_774656 != nil:
    section.add "X-Amz-Date", valid_774656
  var valid_774657 = header.getOrDefault("X-Amz-Security-Token")
  valid_774657 = validateParameter(valid_774657, JString, required = false,
                                 default = nil)
  if valid_774657 != nil:
    section.add "X-Amz-Security-Token", valid_774657
  var valid_774658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-Content-Sha256", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Algorithm")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Algorithm", valid_774659
  var valid_774660 = header.getOrDefault("X-Amz-Signature")
  valid_774660 = validateParameter(valid_774660, JString, required = false,
                                 default = nil)
  if valid_774660 != nil:
    section.add "X-Amz-Signature", valid_774660
  var valid_774661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "X-Amz-SignedHeaders", valid_774661
  var valid_774662 = header.getOrDefault("X-Amz-Credential")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Credential", valid_774662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774663: Call_DeleteStage_774651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_774663.validator(path, query, header, formData, body)
  let scheme = call_774663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774663.url(scheme.get, call_774663.host, call_774663.base,
                         call_774663.route, valid.getOrDefault("path"))
  result = hook(call_774663, url, valid)

proc call*(call_774664: Call_DeleteStage_774651; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774665 = newJObject()
  add(path_774665, "stage_name", newJString(stageName))
  add(path_774665, "restapi_id", newJString(restapiId))
  result = call_774664.call(path_774665, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_774651(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_774652,
                                        base: "/", url: url_DeleteStage_774653,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_774683 = ref object of OpenApiRestCall_772581
proc url_GetUsagePlan_774685(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_774684(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774686 = path.getOrDefault("usageplanId")
  valid_774686 = validateParameter(valid_774686, JString, required = true,
                                 default = nil)
  if valid_774686 != nil:
    section.add "usageplanId", valid_774686
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774687 = header.getOrDefault("X-Amz-Date")
  valid_774687 = validateParameter(valid_774687, JString, required = false,
                                 default = nil)
  if valid_774687 != nil:
    section.add "X-Amz-Date", valid_774687
  var valid_774688 = header.getOrDefault("X-Amz-Security-Token")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "X-Amz-Security-Token", valid_774688
  var valid_774689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "X-Amz-Content-Sha256", valid_774689
  var valid_774690 = header.getOrDefault("X-Amz-Algorithm")
  valid_774690 = validateParameter(valid_774690, JString, required = false,
                                 default = nil)
  if valid_774690 != nil:
    section.add "X-Amz-Algorithm", valid_774690
  var valid_774691 = header.getOrDefault("X-Amz-Signature")
  valid_774691 = validateParameter(valid_774691, JString, required = false,
                                 default = nil)
  if valid_774691 != nil:
    section.add "X-Amz-Signature", valid_774691
  var valid_774692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774692 = validateParameter(valid_774692, JString, required = false,
                                 default = nil)
  if valid_774692 != nil:
    section.add "X-Amz-SignedHeaders", valid_774692
  var valid_774693 = header.getOrDefault("X-Amz-Credential")
  valid_774693 = validateParameter(valid_774693, JString, required = false,
                                 default = nil)
  if valid_774693 != nil:
    section.add "X-Amz-Credential", valid_774693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774694: Call_GetUsagePlan_774683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_774694.validator(path, query, header, formData, body)
  let scheme = call_774694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774694.url(scheme.get, call_774694.host, call_774694.base,
                         call_774694.route, valid.getOrDefault("path"))
  result = hook(call_774694, url, valid)

proc call*(call_774695: Call_GetUsagePlan_774683; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_774696 = newJObject()
  add(path_774696, "usageplanId", newJString(usageplanId))
  result = call_774695.call(path_774696, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_774683(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_774684,
    base: "/", url: url_GetUsagePlan_774685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_774711 = ref object of OpenApiRestCall_772581
proc url_UpdateUsagePlan_774713(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_774712(path: JsonNode; query: JsonNode;
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
  var valid_774714 = path.getOrDefault("usageplanId")
  valid_774714 = validateParameter(valid_774714, JString, required = true,
                                 default = nil)
  if valid_774714 != nil:
    section.add "usageplanId", valid_774714
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774715 = header.getOrDefault("X-Amz-Date")
  valid_774715 = validateParameter(valid_774715, JString, required = false,
                                 default = nil)
  if valid_774715 != nil:
    section.add "X-Amz-Date", valid_774715
  var valid_774716 = header.getOrDefault("X-Amz-Security-Token")
  valid_774716 = validateParameter(valid_774716, JString, required = false,
                                 default = nil)
  if valid_774716 != nil:
    section.add "X-Amz-Security-Token", valid_774716
  var valid_774717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774717 = validateParameter(valid_774717, JString, required = false,
                                 default = nil)
  if valid_774717 != nil:
    section.add "X-Amz-Content-Sha256", valid_774717
  var valid_774718 = header.getOrDefault("X-Amz-Algorithm")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-Algorithm", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Signature")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Signature", valid_774719
  var valid_774720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774720 = validateParameter(valid_774720, JString, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "X-Amz-SignedHeaders", valid_774720
  var valid_774721 = header.getOrDefault("X-Amz-Credential")
  valid_774721 = validateParameter(valid_774721, JString, required = false,
                                 default = nil)
  if valid_774721 != nil:
    section.add "X-Amz-Credential", valid_774721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774723: Call_UpdateUsagePlan_774711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_774723.validator(path, query, header, formData, body)
  let scheme = call_774723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774723.url(scheme.get, call_774723.host, call_774723.base,
                         call_774723.route, valid.getOrDefault("path"))
  result = hook(call_774723, url, valid)

proc call*(call_774724: Call_UpdateUsagePlan_774711; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_774725 = newJObject()
  var body_774726 = newJObject()
  add(path_774725, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_774726 = body
  result = call_774724.call(path_774725, nil, nil, nil, body_774726)

var updateUsagePlan* = Call_UpdateUsagePlan_774711(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_774712,
    base: "/", url: url_UpdateUsagePlan_774713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_774697 = ref object of OpenApiRestCall_772581
proc url_DeleteUsagePlan_774699(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_774698(path: JsonNode; query: JsonNode;
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
  var valid_774700 = path.getOrDefault("usageplanId")
  valid_774700 = validateParameter(valid_774700, JString, required = true,
                                 default = nil)
  if valid_774700 != nil:
    section.add "usageplanId", valid_774700
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774701 = header.getOrDefault("X-Amz-Date")
  valid_774701 = validateParameter(valid_774701, JString, required = false,
                                 default = nil)
  if valid_774701 != nil:
    section.add "X-Amz-Date", valid_774701
  var valid_774702 = header.getOrDefault("X-Amz-Security-Token")
  valid_774702 = validateParameter(valid_774702, JString, required = false,
                                 default = nil)
  if valid_774702 != nil:
    section.add "X-Amz-Security-Token", valid_774702
  var valid_774703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Content-Sha256", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Algorithm")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Algorithm", valid_774704
  var valid_774705 = header.getOrDefault("X-Amz-Signature")
  valid_774705 = validateParameter(valid_774705, JString, required = false,
                                 default = nil)
  if valid_774705 != nil:
    section.add "X-Amz-Signature", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-SignedHeaders", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Credential")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Credential", valid_774707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774708: Call_DeleteUsagePlan_774697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_774708.validator(path, query, header, formData, body)
  let scheme = call_774708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774708.url(scheme.get, call_774708.host, call_774708.base,
                         call_774708.route, valid.getOrDefault("path"))
  result = hook(call_774708, url, valid)

proc call*(call_774709: Call_DeleteUsagePlan_774697; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_774710 = newJObject()
  add(path_774710, "usageplanId", newJString(usageplanId))
  result = call_774709.call(path_774710, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_774697(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_774698,
    base: "/", url: url_DeleteUsagePlan_774699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_774727 = ref object of OpenApiRestCall_772581
proc url_GetUsagePlanKey_774729(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_774728(path: JsonNode; query: JsonNode;
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
  var valid_774730 = path.getOrDefault("keyId")
  valid_774730 = validateParameter(valid_774730, JString, required = true,
                                 default = nil)
  if valid_774730 != nil:
    section.add "keyId", valid_774730
  var valid_774731 = path.getOrDefault("usageplanId")
  valid_774731 = validateParameter(valid_774731, JString, required = true,
                                 default = nil)
  if valid_774731 != nil:
    section.add "usageplanId", valid_774731
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774732 = header.getOrDefault("X-Amz-Date")
  valid_774732 = validateParameter(valid_774732, JString, required = false,
                                 default = nil)
  if valid_774732 != nil:
    section.add "X-Amz-Date", valid_774732
  var valid_774733 = header.getOrDefault("X-Amz-Security-Token")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "X-Amz-Security-Token", valid_774733
  var valid_774734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774734 = validateParameter(valid_774734, JString, required = false,
                                 default = nil)
  if valid_774734 != nil:
    section.add "X-Amz-Content-Sha256", valid_774734
  var valid_774735 = header.getOrDefault("X-Amz-Algorithm")
  valid_774735 = validateParameter(valid_774735, JString, required = false,
                                 default = nil)
  if valid_774735 != nil:
    section.add "X-Amz-Algorithm", valid_774735
  var valid_774736 = header.getOrDefault("X-Amz-Signature")
  valid_774736 = validateParameter(valid_774736, JString, required = false,
                                 default = nil)
  if valid_774736 != nil:
    section.add "X-Amz-Signature", valid_774736
  var valid_774737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774737 = validateParameter(valid_774737, JString, required = false,
                                 default = nil)
  if valid_774737 != nil:
    section.add "X-Amz-SignedHeaders", valid_774737
  var valid_774738 = header.getOrDefault("X-Amz-Credential")
  valid_774738 = validateParameter(valid_774738, JString, required = false,
                                 default = nil)
  if valid_774738 != nil:
    section.add "X-Amz-Credential", valid_774738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774739: Call_GetUsagePlanKey_774727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_774739.validator(path, query, header, formData, body)
  let scheme = call_774739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774739.url(scheme.get, call_774739.host, call_774739.base,
                         call_774739.route, valid.getOrDefault("path"))
  result = hook(call_774739, url, valid)

proc call*(call_774740: Call_GetUsagePlanKey_774727; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_774741 = newJObject()
  add(path_774741, "keyId", newJString(keyId))
  add(path_774741, "usageplanId", newJString(usageplanId))
  result = call_774740.call(path_774741, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_774727(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_774728, base: "/", url: url_GetUsagePlanKey_774729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_774742 = ref object of OpenApiRestCall_772581
proc url_DeleteUsagePlanKey_774744(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_774743(path: JsonNode; query: JsonNode;
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
  var valid_774745 = path.getOrDefault("keyId")
  valid_774745 = validateParameter(valid_774745, JString, required = true,
                                 default = nil)
  if valid_774745 != nil:
    section.add "keyId", valid_774745
  var valid_774746 = path.getOrDefault("usageplanId")
  valid_774746 = validateParameter(valid_774746, JString, required = true,
                                 default = nil)
  if valid_774746 != nil:
    section.add "usageplanId", valid_774746
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774747 = header.getOrDefault("X-Amz-Date")
  valid_774747 = validateParameter(valid_774747, JString, required = false,
                                 default = nil)
  if valid_774747 != nil:
    section.add "X-Amz-Date", valid_774747
  var valid_774748 = header.getOrDefault("X-Amz-Security-Token")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Security-Token", valid_774748
  var valid_774749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-Content-Sha256", valid_774749
  var valid_774750 = header.getOrDefault("X-Amz-Algorithm")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "X-Amz-Algorithm", valid_774750
  var valid_774751 = header.getOrDefault("X-Amz-Signature")
  valid_774751 = validateParameter(valid_774751, JString, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "X-Amz-Signature", valid_774751
  var valid_774752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-SignedHeaders", valid_774752
  var valid_774753 = header.getOrDefault("X-Amz-Credential")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "X-Amz-Credential", valid_774753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774754: Call_DeleteUsagePlanKey_774742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_774754.validator(path, query, header, formData, body)
  let scheme = call_774754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774754.url(scheme.get, call_774754.host, call_774754.base,
                         call_774754.route, valid.getOrDefault("path"))
  result = hook(call_774754, url, valid)

proc call*(call_774755: Call_DeleteUsagePlanKey_774742; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_774756 = newJObject()
  add(path_774756, "keyId", newJString(keyId))
  add(path_774756, "usageplanId", newJString(usageplanId))
  result = call_774755.call(path_774756, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_774742(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_774743, base: "/",
    url: url_DeleteUsagePlanKey_774744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_774757 = ref object of OpenApiRestCall_772581
proc url_GetVpcLink_774759(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_774758(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774760 = path.getOrDefault("vpclink_id")
  valid_774760 = validateParameter(valid_774760, JString, required = true,
                                 default = nil)
  if valid_774760 != nil:
    section.add "vpclink_id", valid_774760
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774761 = header.getOrDefault("X-Amz-Date")
  valid_774761 = validateParameter(valid_774761, JString, required = false,
                                 default = nil)
  if valid_774761 != nil:
    section.add "X-Amz-Date", valid_774761
  var valid_774762 = header.getOrDefault("X-Amz-Security-Token")
  valid_774762 = validateParameter(valid_774762, JString, required = false,
                                 default = nil)
  if valid_774762 != nil:
    section.add "X-Amz-Security-Token", valid_774762
  var valid_774763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Content-Sha256", valid_774763
  var valid_774764 = header.getOrDefault("X-Amz-Algorithm")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-Algorithm", valid_774764
  var valid_774765 = header.getOrDefault("X-Amz-Signature")
  valid_774765 = validateParameter(valid_774765, JString, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "X-Amz-Signature", valid_774765
  var valid_774766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774766 = validateParameter(valid_774766, JString, required = false,
                                 default = nil)
  if valid_774766 != nil:
    section.add "X-Amz-SignedHeaders", valid_774766
  var valid_774767 = header.getOrDefault("X-Amz-Credential")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-Credential", valid_774767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774768: Call_GetVpcLink_774757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_774768.validator(path, query, header, formData, body)
  let scheme = call_774768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774768.url(scheme.get, call_774768.host, call_774768.base,
                         call_774768.route, valid.getOrDefault("path"))
  result = hook(call_774768, url, valid)

proc call*(call_774769: Call_GetVpcLink_774757; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_774770 = newJObject()
  add(path_774770, "vpclink_id", newJString(vpclinkId))
  result = call_774769.call(path_774770, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_774757(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_774758,
                                      base: "/", url: url_GetVpcLink_774759,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_774785 = ref object of OpenApiRestCall_772581
proc url_UpdateVpcLink_774787(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_774786(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774788 = path.getOrDefault("vpclink_id")
  valid_774788 = validateParameter(valid_774788, JString, required = true,
                                 default = nil)
  if valid_774788 != nil:
    section.add "vpclink_id", valid_774788
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774789 = header.getOrDefault("X-Amz-Date")
  valid_774789 = validateParameter(valid_774789, JString, required = false,
                                 default = nil)
  if valid_774789 != nil:
    section.add "X-Amz-Date", valid_774789
  var valid_774790 = header.getOrDefault("X-Amz-Security-Token")
  valid_774790 = validateParameter(valid_774790, JString, required = false,
                                 default = nil)
  if valid_774790 != nil:
    section.add "X-Amz-Security-Token", valid_774790
  var valid_774791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774791 = validateParameter(valid_774791, JString, required = false,
                                 default = nil)
  if valid_774791 != nil:
    section.add "X-Amz-Content-Sha256", valid_774791
  var valid_774792 = header.getOrDefault("X-Amz-Algorithm")
  valid_774792 = validateParameter(valid_774792, JString, required = false,
                                 default = nil)
  if valid_774792 != nil:
    section.add "X-Amz-Algorithm", valid_774792
  var valid_774793 = header.getOrDefault("X-Amz-Signature")
  valid_774793 = validateParameter(valid_774793, JString, required = false,
                                 default = nil)
  if valid_774793 != nil:
    section.add "X-Amz-Signature", valid_774793
  var valid_774794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774794 = validateParameter(valid_774794, JString, required = false,
                                 default = nil)
  if valid_774794 != nil:
    section.add "X-Amz-SignedHeaders", valid_774794
  var valid_774795 = header.getOrDefault("X-Amz-Credential")
  valid_774795 = validateParameter(valid_774795, JString, required = false,
                                 default = nil)
  if valid_774795 != nil:
    section.add "X-Amz-Credential", valid_774795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774797: Call_UpdateVpcLink_774785; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_774797.validator(path, query, header, formData, body)
  let scheme = call_774797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774797.url(scheme.get, call_774797.host, call_774797.base,
                         call_774797.route, valid.getOrDefault("path"))
  result = hook(call_774797, url, valid)

proc call*(call_774798: Call_UpdateVpcLink_774785; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_774799 = newJObject()
  var body_774800 = newJObject()
  if body != nil:
    body_774800 = body
  add(path_774799, "vpclink_id", newJString(vpclinkId))
  result = call_774798.call(path_774799, nil, nil, nil, body_774800)

var updateVpcLink* = Call_UpdateVpcLink_774785(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_774786,
    base: "/", url: url_UpdateVpcLink_774787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_774771 = ref object of OpenApiRestCall_772581
proc url_DeleteVpcLink_774773(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_774772(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774774 = path.getOrDefault("vpclink_id")
  valid_774774 = validateParameter(valid_774774, JString, required = true,
                                 default = nil)
  if valid_774774 != nil:
    section.add "vpclink_id", valid_774774
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774775 = header.getOrDefault("X-Amz-Date")
  valid_774775 = validateParameter(valid_774775, JString, required = false,
                                 default = nil)
  if valid_774775 != nil:
    section.add "X-Amz-Date", valid_774775
  var valid_774776 = header.getOrDefault("X-Amz-Security-Token")
  valid_774776 = validateParameter(valid_774776, JString, required = false,
                                 default = nil)
  if valid_774776 != nil:
    section.add "X-Amz-Security-Token", valid_774776
  var valid_774777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774777 = validateParameter(valid_774777, JString, required = false,
                                 default = nil)
  if valid_774777 != nil:
    section.add "X-Amz-Content-Sha256", valid_774777
  var valid_774778 = header.getOrDefault("X-Amz-Algorithm")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "X-Amz-Algorithm", valid_774778
  var valid_774779 = header.getOrDefault("X-Amz-Signature")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "X-Amz-Signature", valid_774779
  var valid_774780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774780 = validateParameter(valid_774780, JString, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "X-Amz-SignedHeaders", valid_774780
  var valid_774781 = header.getOrDefault("X-Amz-Credential")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "X-Amz-Credential", valid_774781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774782: Call_DeleteVpcLink_774771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_774782.validator(path, query, header, formData, body)
  let scheme = call_774782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774782.url(scheme.get, call_774782.host, call_774782.base,
                         call_774782.route, valid.getOrDefault("path"))
  result = hook(call_774782, url, valid)

proc call*(call_774783: Call_DeleteVpcLink_774771; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_774784 = newJObject()
  add(path_774784, "vpclink_id", newJString(vpclinkId))
  result = call_774783.call(path_774784, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_774771(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_774772,
    base: "/", url: url_DeleteVpcLink_774773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_774801 = ref object of OpenApiRestCall_772581
proc url_FlushStageAuthorizersCache_774803(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_774802(path: JsonNode; query: JsonNode;
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
  var valid_774804 = path.getOrDefault("stage_name")
  valid_774804 = validateParameter(valid_774804, JString, required = true,
                                 default = nil)
  if valid_774804 != nil:
    section.add "stage_name", valid_774804
  var valid_774805 = path.getOrDefault("restapi_id")
  valid_774805 = validateParameter(valid_774805, JString, required = true,
                                 default = nil)
  if valid_774805 != nil:
    section.add "restapi_id", valid_774805
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774806 = header.getOrDefault("X-Amz-Date")
  valid_774806 = validateParameter(valid_774806, JString, required = false,
                                 default = nil)
  if valid_774806 != nil:
    section.add "X-Amz-Date", valid_774806
  var valid_774807 = header.getOrDefault("X-Amz-Security-Token")
  valid_774807 = validateParameter(valid_774807, JString, required = false,
                                 default = nil)
  if valid_774807 != nil:
    section.add "X-Amz-Security-Token", valid_774807
  var valid_774808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774808 = validateParameter(valid_774808, JString, required = false,
                                 default = nil)
  if valid_774808 != nil:
    section.add "X-Amz-Content-Sha256", valid_774808
  var valid_774809 = header.getOrDefault("X-Amz-Algorithm")
  valid_774809 = validateParameter(valid_774809, JString, required = false,
                                 default = nil)
  if valid_774809 != nil:
    section.add "X-Amz-Algorithm", valid_774809
  var valid_774810 = header.getOrDefault("X-Amz-Signature")
  valid_774810 = validateParameter(valid_774810, JString, required = false,
                                 default = nil)
  if valid_774810 != nil:
    section.add "X-Amz-Signature", valid_774810
  var valid_774811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774811 = validateParameter(valid_774811, JString, required = false,
                                 default = nil)
  if valid_774811 != nil:
    section.add "X-Amz-SignedHeaders", valid_774811
  var valid_774812 = header.getOrDefault("X-Amz-Credential")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "X-Amz-Credential", valid_774812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774813: Call_FlushStageAuthorizersCache_774801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_774813.validator(path, query, header, formData, body)
  let scheme = call_774813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774813.url(scheme.get, call_774813.host, call_774813.base,
                         call_774813.route, valid.getOrDefault("path"))
  result = hook(call_774813, url, valid)

proc call*(call_774814: Call_FlushStageAuthorizersCache_774801; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_774815 = newJObject()
  add(path_774815, "stage_name", newJString(stageName))
  add(path_774815, "restapi_id", newJString(restapiId))
  result = call_774814.call(path_774815, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_774801(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_774802, base: "/",
    url: url_FlushStageAuthorizersCache_774803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_774816 = ref object of OpenApiRestCall_772581
proc url_FlushStageCache_774818(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_774817(path: JsonNode; query: JsonNode;
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
  var valid_774819 = path.getOrDefault("stage_name")
  valid_774819 = validateParameter(valid_774819, JString, required = true,
                                 default = nil)
  if valid_774819 != nil:
    section.add "stage_name", valid_774819
  var valid_774820 = path.getOrDefault("restapi_id")
  valid_774820 = validateParameter(valid_774820, JString, required = true,
                                 default = nil)
  if valid_774820 != nil:
    section.add "restapi_id", valid_774820
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774821 = header.getOrDefault("X-Amz-Date")
  valid_774821 = validateParameter(valid_774821, JString, required = false,
                                 default = nil)
  if valid_774821 != nil:
    section.add "X-Amz-Date", valid_774821
  var valid_774822 = header.getOrDefault("X-Amz-Security-Token")
  valid_774822 = validateParameter(valid_774822, JString, required = false,
                                 default = nil)
  if valid_774822 != nil:
    section.add "X-Amz-Security-Token", valid_774822
  var valid_774823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774823 = validateParameter(valid_774823, JString, required = false,
                                 default = nil)
  if valid_774823 != nil:
    section.add "X-Amz-Content-Sha256", valid_774823
  var valid_774824 = header.getOrDefault("X-Amz-Algorithm")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "X-Amz-Algorithm", valid_774824
  var valid_774825 = header.getOrDefault("X-Amz-Signature")
  valid_774825 = validateParameter(valid_774825, JString, required = false,
                                 default = nil)
  if valid_774825 != nil:
    section.add "X-Amz-Signature", valid_774825
  var valid_774826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774826 = validateParameter(valid_774826, JString, required = false,
                                 default = nil)
  if valid_774826 != nil:
    section.add "X-Amz-SignedHeaders", valid_774826
  var valid_774827 = header.getOrDefault("X-Amz-Credential")
  valid_774827 = validateParameter(valid_774827, JString, required = false,
                                 default = nil)
  if valid_774827 != nil:
    section.add "X-Amz-Credential", valid_774827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774828: Call_FlushStageCache_774816; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_774828.validator(path, query, header, formData, body)
  let scheme = call_774828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774828.url(scheme.get, call_774828.host, call_774828.base,
                         call_774828.route, valid.getOrDefault("path"))
  result = hook(call_774828, url, valid)

proc call*(call_774829: Call_FlushStageCache_774816; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774830 = newJObject()
  add(path_774830, "stage_name", newJString(stageName))
  add(path_774830, "restapi_id", newJString(restapiId))
  result = call_774829.call(path_774830, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_774816(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_774817, base: "/", url: url_FlushStageCache_774818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_774846 = ref object of OpenApiRestCall_772581
proc url_GenerateClientCertificate_774848(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateClientCertificate_774847(path: JsonNode; query: JsonNode;
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
  var valid_774849 = header.getOrDefault("X-Amz-Date")
  valid_774849 = validateParameter(valid_774849, JString, required = false,
                                 default = nil)
  if valid_774849 != nil:
    section.add "X-Amz-Date", valid_774849
  var valid_774850 = header.getOrDefault("X-Amz-Security-Token")
  valid_774850 = validateParameter(valid_774850, JString, required = false,
                                 default = nil)
  if valid_774850 != nil:
    section.add "X-Amz-Security-Token", valid_774850
  var valid_774851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774851 = validateParameter(valid_774851, JString, required = false,
                                 default = nil)
  if valid_774851 != nil:
    section.add "X-Amz-Content-Sha256", valid_774851
  var valid_774852 = header.getOrDefault("X-Amz-Algorithm")
  valid_774852 = validateParameter(valid_774852, JString, required = false,
                                 default = nil)
  if valid_774852 != nil:
    section.add "X-Amz-Algorithm", valid_774852
  var valid_774853 = header.getOrDefault("X-Amz-Signature")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Signature", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-SignedHeaders", valid_774854
  var valid_774855 = header.getOrDefault("X-Amz-Credential")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Credential", valid_774855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774857: Call_GenerateClientCertificate_774846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_774857.validator(path, query, header, formData, body)
  let scheme = call_774857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774857.url(scheme.get, call_774857.host, call_774857.base,
                         call_774857.route, valid.getOrDefault("path"))
  result = hook(call_774857, url, valid)

proc call*(call_774858: Call_GenerateClientCertificate_774846; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_774859 = newJObject()
  if body != nil:
    body_774859 = body
  result = call_774858.call(nil, nil, nil, nil, body_774859)

var generateClientCertificate* = Call_GenerateClientCertificate_774846(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_774847, base: "/",
    url: url_GenerateClientCertificate_774848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_774831 = ref object of OpenApiRestCall_772581
proc url_GetClientCertificates_774833(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetClientCertificates_774832(path: JsonNode; query: JsonNode;
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
  var valid_774834 = query.getOrDefault("position")
  valid_774834 = validateParameter(valid_774834, JString, required = false,
                                 default = nil)
  if valid_774834 != nil:
    section.add "position", valid_774834
  var valid_774835 = query.getOrDefault("limit")
  valid_774835 = validateParameter(valid_774835, JInt, required = false, default = nil)
  if valid_774835 != nil:
    section.add "limit", valid_774835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774836 = header.getOrDefault("X-Amz-Date")
  valid_774836 = validateParameter(valid_774836, JString, required = false,
                                 default = nil)
  if valid_774836 != nil:
    section.add "X-Amz-Date", valid_774836
  var valid_774837 = header.getOrDefault("X-Amz-Security-Token")
  valid_774837 = validateParameter(valid_774837, JString, required = false,
                                 default = nil)
  if valid_774837 != nil:
    section.add "X-Amz-Security-Token", valid_774837
  var valid_774838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Content-Sha256", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-Algorithm")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-Algorithm", valid_774839
  var valid_774840 = header.getOrDefault("X-Amz-Signature")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Signature", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-SignedHeaders", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Credential")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Credential", valid_774842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774843: Call_GetClientCertificates_774831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_774843.validator(path, query, header, formData, body)
  let scheme = call_774843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774843.url(scheme.get, call_774843.host, call_774843.base,
                         call_774843.route, valid.getOrDefault("path"))
  result = hook(call_774843, url, valid)

proc call*(call_774844: Call_GetClientCertificates_774831; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_774845 = newJObject()
  add(query_774845, "position", newJString(position))
  add(query_774845, "limit", newJInt(limit))
  result = call_774844.call(nil, query_774845, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_774831(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_774832, base: "/",
    url: url_GetClientCertificates_774833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_774860 = ref object of OpenApiRestCall_772581
proc url_GetAccount_774862(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccount_774861(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774863 = header.getOrDefault("X-Amz-Date")
  valid_774863 = validateParameter(valid_774863, JString, required = false,
                                 default = nil)
  if valid_774863 != nil:
    section.add "X-Amz-Date", valid_774863
  var valid_774864 = header.getOrDefault("X-Amz-Security-Token")
  valid_774864 = validateParameter(valid_774864, JString, required = false,
                                 default = nil)
  if valid_774864 != nil:
    section.add "X-Amz-Security-Token", valid_774864
  var valid_774865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774865 = validateParameter(valid_774865, JString, required = false,
                                 default = nil)
  if valid_774865 != nil:
    section.add "X-Amz-Content-Sha256", valid_774865
  var valid_774866 = header.getOrDefault("X-Amz-Algorithm")
  valid_774866 = validateParameter(valid_774866, JString, required = false,
                                 default = nil)
  if valid_774866 != nil:
    section.add "X-Amz-Algorithm", valid_774866
  var valid_774867 = header.getOrDefault("X-Amz-Signature")
  valid_774867 = validateParameter(valid_774867, JString, required = false,
                                 default = nil)
  if valid_774867 != nil:
    section.add "X-Amz-Signature", valid_774867
  var valid_774868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "X-Amz-SignedHeaders", valid_774868
  var valid_774869 = header.getOrDefault("X-Amz-Credential")
  valid_774869 = validateParameter(valid_774869, JString, required = false,
                                 default = nil)
  if valid_774869 != nil:
    section.add "X-Amz-Credential", valid_774869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774870: Call_GetAccount_774860; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_774870.validator(path, query, header, formData, body)
  let scheme = call_774870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774870.url(scheme.get, call_774870.host, call_774870.base,
                         call_774870.route, valid.getOrDefault("path"))
  result = hook(call_774870, url, valid)

proc call*(call_774871: Call_GetAccount_774860): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_774871.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_774860(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_774861,
                                      base: "/", url: url_GetAccount_774862,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_774872 = ref object of OpenApiRestCall_772581
proc url_UpdateAccount_774874(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAccount_774873(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774875 = header.getOrDefault("X-Amz-Date")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "X-Amz-Date", valid_774875
  var valid_774876 = header.getOrDefault("X-Amz-Security-Token")
  valid_774876 = validateParameter(valid_774876, JString, required = false,
                                 default = nil)
  if valid_774876 != nil:
    section.add "X-Amz-Security-Token", valid_774876
  var valid_774877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774877 = validateParameter(valid_774877, JString, required = false,
                                 default = nil)
  if valid_774877 != nil:
    section.add "X-Amz-Content-Sha256", valid_774877
  var valid_774878 = header.getOrDefault("X-Amz-Algorithm")
  valid_774878 = validateParameter(valid_774878, JString, required = false,
                                 default = nil)
  if valid_774878 != nil:
    section.add "X-Amz-Algorithm", valid_774878
  var valid_774879 = header.getOrDefault("X-Amz-Signature")
  valid_774879 = validateParameter(valid_774879, JString, required = false,
                                 default = nil)
  if valid_774879 != nil:
    section.add "X-Amz-Signature", valid_774879
  var valid_774880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774880 = validateParameter(valid_774880, JString, required = false,
                                 default = nil)
  if valid_774880 != nil:
    section.add "X-Amz-SignedHeaders", valid_774880
  var valid_774881 = header.getOrDefault("X-Amz-Credential")
  valid_774881 = validateParameter(valid_774881, JString, required = false,
                                 default = nil)
  if valid_774881 != nil:
    section.add "X-Amz-Credential", valid_774881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774883: Call_UpdateAccount_774872; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_774883.validator(path, query, header, formData, body)
  let scheme = call_774883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774883.url(scheme.get, call_774883.host, call_774883.base,
                         call_774883.route, valid.getOrDefault("path"))
  result = hook(call_774883, url, valid)

proc call*(call_774884: Call_UpdateAccount_774872; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_774885 = newJObject()
  if body != nil:
    body_774885 = body
  result = call_774884.call(nil, nil, nil, nil, body_774885)

var updateAccount* = Call_UpdateAccount_774872(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_774873, base: "/", url: url_UpdateAccount_774874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_774886 = ref object of OpenApiRestCall_772581
proc url_GetExport_774888(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_774887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774889 = path.getOrDefault("export_type")
  valid_774889 = validateParameter(valid_774889, JString, required = true,
                                 default = nil)
  if valid_774889 != nil:
    section.add "export_type", valid_774889
  var valid_774890 = path.getOrDefault("stage_name")
  valid_774890 = validateParameter(valid_774890, JString, required = true,
                                 default = nil)
  if valid_774890 != nil:
    section.add "stage_name", valid_774890
  var valid_774891 = path.getOrDefault("restapi_id")
  valid_774891 = validateParameter(valid_774891, JString, required = true,
                                 default = nil)
  if valid_774891 != nil:
    section.add "restapi_id", valid_774891
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_774892 = query.getOrDefault("parameters.0.value")
  valid_774892 = validateParameter(valid_774892, JString, required = false,
                                 default = nil)
  if valid_774892 != nil:
    section.add "parameters.0.value", valid_774892
  var valid_774893 = query.getOrDefault("parameters.2.value")
  valid_774893 = validateParameter(valid_774893, JString, required = false,
                                 default = nil)
  if valid_774893 != nil:
    section.add "parameters.2.value", valid_774893
  var valid_774894 = query.getOrDefault("parameters.1.key")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "parameters.1.key", valid_774894
  var valid_774895 = query.getOrDefault("parameters.0.key")
  valid_774895 = validateParameter(valid_774895, JString, required = false,
                                 default = nil)
  if valid_774895 != nil:
    section.add "parameters.0.key", valid_774895
  var valid_774896 = query.getOrDefault("parameters.2.key")
  valid_774896 = validateParameter(valid_774896, JString, required = false,
                                 default = nil)
  if valid_774896 != nil:
    section.add "parameters.2.key", valid_774896
  var valid_774897 = query.getOrDefault("parameters.1.value")
  valid_774897 = validateParameter(valid_774897, JString, required = false,
                                 default = nil)
  if valid_774897 != nil:
    section.add "parameters.1.value", valid_774897
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
  var valid_774898 = header.getOrDefault("X-Amz-Date")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-Date", valid_774898
  var valid_774899 = header.getOrDefault("X-Amz-Security-Token")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "X-Amz-Security-Token", valid_774899
  var valid_774900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774900 = validateParameter(valid_774900, JString, required = false,
                                 default = nil)
  if valid_774900 != nil:
    section.add "X-Amz-Content-Sha256", valid_774900
  var valid_774901 = header.getOrDefault("X-Amz-Algorithm")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "X-Amz-Algorithm", valid_774901
  var valid_774902 = header.getOrDefault("X-Amz-Signature")
  valid_774902 = validateParameter(valid_774902, JString, required = false,
                                 default = nil)
  if valid_774902 != nil:
    section.add "X-Amz-Signature", valid_774902
  var valid_774903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774903 = validateParameter(valid_774903, JString, required = false,
                                 default = nil)
  if valid_774903 != nil:
    section.add "X-Amz-SignedHeaders", valid_774903
  var valid_774904 = header.getOrDefault("Accept")
  valid_774904 = validateParameter(valid_774904, JString, required = false,
                                 default = nil)
  if valid_774904 != nil:
    section.add "Accept", valid_774904
  var valid_774905 = header.getOrDefault("X-Amz-Credential")
  valid_774905 = validateParameter(valid_774905, JString, required = false,
                                 default = nil)
  if valid_774905 != nil:
    section.add "X-Amz-Credential", valid_774905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774906: Call_GetExport_774886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_774906.validator(path, query, header, formData, body)
  let scheme = call_774906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774906.url(scheme.get, call_774906.host, call_774906.base,
                         call_774906.route, valid.getOrDefault("path"))
  result = hook(call_774906, url, valid)

proc call*(call_774907: Call_GetExport_774886; exportType: string; stageName: string;
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
  var path_774908 = newJObject()
  var query_774909 = newJObject()
  add(query_774909, "parameters.0.value", newJString(parameters0Value))
  add(query_774909, "parameters.2.value", newJString(parameters2Value))
  add(query_774909, "parameters.1.key", newJString(parameters1Key))
  add(query_774909, "parameters.0.key", newJString(parameters0Key))
  add(path_774908, "export_type", newJString(exportType))
  add(query_774909, "parameters.2.key", newJString(parameters2Key))
  add(path_774908, "stage_name", newJString(stageName))
  add(query_774909, "parameters.1.value", newJString(parameters1Value))
  add(path_774908, "restapi_id", newJString(restapiId))
  result = call_774907.call(path_774908, query_774909, nil, nil, nil)

var getExport* = Call_GetExport_774886(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_774887,
                                    base: "/", url: url_GetExport_774888,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_774910 = ref object of OpenApiRestCall_772581
proc url_GetGatewayResponses_774912(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_774911(path: JsonNode; query: JsonNode;
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
  var valid_774913 = path.getOrDefault("restapi_id")
  valid_774913 = validateParameter(valid_774913, JString, required = true,
                                 default = nil)
  if valid_774913 != nil:
    section.add "restapi_id", valid_774913
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_774914 = query.getOrDefault("position")
  valid_774914 = validateParameter(valid_774914, JString, required = false,
                                 default = nil)
  if valid_774914 != nil:
    section.add "position", valid_774914
  var valid_774915 = query.getOrDefault("limit")
  valid_774915 = validateParameter(valid_774915, JInt, required = false, default = nil)
  if valid_774915 != nil:
    section.add "limit", valid_774915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774916 = header.getOrDefault("X-Amz-Date")
  valid_774916 = validateParameter(valid_774916, JString, required = false,
                                 default = nil)
  if valid_774916 != nil:
    section.add "X-Amz-Date", valid_774916
  var valid_774917 = header.getOrDefault("X-Amz-Security-Token")
  valid_774917 = validateParameter(valid_774917, JString, required = false,
                                 default = nil)
  if valid_774917 != nil:
    section.add "X-Amz-Security-Token", valid_774917
  var valid_774918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774918 = validateParameter(valid_774918, JString, required = false,
                                 default = nil)
  if valid_774918 != nil:
    section.add "X-Amz-Content-Sha256", valid_774918
  var valid_774919 = header.getOrDefault("X-Amz-Algorithm")
  valid_774919 = validateParameter(valid_774919, JString, required = false,
                                 default = nil)
  if valid_774919 != nil:
    section.add "X-Amz-Algorithm", valid_774919
  var valid_774920 = header.getOrDefault("X-Amz-Signature")
  valid_774920 = validateParameter(valid_774920, JString, required = false,
                                 default = nil)
  if valid_774920 != nil:
    section.add "X-Amz-Signature", valid_774920
  var valid_774921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774921 = validateParameter(valid_774921, JString, required = false,
                                 default = nil)
  if valid_774921 != nil:
    section.add "X-Amz-SignedHeaders", valid_774921
  var valid_774922 = header.getOrDefault("X-Amz-Credential")
  valid_774922 = validateParameter(valid_774922, JString, required = false,
                                 default = nil)
  if valid_774922 != nil:
    section.add "X-Amz-Credential", valid_774922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774923: Call_GetGatewayResponses_774910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_774923.validator(path, query, header, formData, body)
  let scheme = call_774923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774923.url(scheme.get, call_774923.host, call_774923.base,
                         call_774923.route, valid.getOrDefault("path"))
  result = hook(call_774923, url, valid)

proc call*(call_774924: Call_GetGatewayResponses_774910; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774925 = newJObject()
  var query_774926 = newJObject()
  add(query_774926, "position", newJString(position))
  add(query_774926, "limit", newJInt(limit))
  add(path_774925, "restapi_id", newJString(restapiId))
  result = call_774924.call(path_774925, query_774926, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_774910(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_774911, base: "/",
    url: url_GetGatewayResponses_774912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_774927 = ref object of OpenApiRestCall_772581
proc url_GetModelTemplate_774929(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_774928(path: JsonNode; query: JsonNode;
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
  var valid_774930 = path.getOrDefault("model_name")
  valid_774930 = validateParameter(valid_774930, JString, required = true,
                                 default = nil)
  if valid_774930 != nil:
    section.add "model_name", valid_774930
  var valid_774931 = path.getOrDefault("restapi_id")
  valid_774931 = validateParameter(valid_774931, JString, required = true,
                                 default = nil)
  if valid_774931 != nil:
    section.add "restapi_id", valid_774931
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774932 = header.getOrDefault("X-Amz-Date")
  valid_774932 = validateParameter(valid_774932, JString, required = false,
                                 default = nil)
  if valid_774932 != nil:
    section.add "X-Amz-Date", valid_774932
  var valid_774933 = header.getOrDefault("X-Amz-Security-Token")
  valid_774933 = validateParameter(valid_774933, JString, required = false,
                                 default = nil)
  if valid_774933 != nil:
    section.add "X-Amz-Security-Token", valid_774933
  var valid_774934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774934 = validateParameter(valid_774934, JString, required = false,
                                 default = nil)
  if valid_774934 != nil:
    section.add "X-Amz-Content-Sha256", valid_774934
  var valid_774935 = header.getOrDefault("X-Amz-Algorithm")
  valid_774935 = validateParameter(valid_774935, JString, required = false,
                                 default = nil)
  if valid_774935 != nil:
    section.add "X-Amz-Algorithm", valid_774935
  var valid_774936 = header.getOrDefault("X-Amz-Signature")
  valid_774936 = validateParameter(valid_774936, JString, required = false,
                                 default = nil)
  if valid_774936 != nil:
    section.add "X-Amz-Signature", valid_774936
  var valid_774937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774937 = validateParameter(valid_774937, JString, required = false,
                                 default = nil)
  if valid_774937 != nil:
    section.add "X-Amz-SignedHeaders", valid_774937
  var valid_774938 = header.getOrDefault("X-Amz-Credential")
  valid_774938 = validateParameter(valid_774938, JString, required = false,
                                 default = nil)
  if valid_774938 != nil:
    section.add "X-Amz-Credential", valid_774938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774939: Call_GetModelTemplate_774927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_774939.validator(path, query, header, formData, body)
  let scheme = call_774939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774939.url(scheme.get, call_774939.host, call_774939.base,
                         call_774939.route, valid.getOrDefault("path"))
  result = hook(call_774939, url, valid)

proc call*(call_774940: Call_GetModelTemplate_774927; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_774941 = newJObject()
  add(path_774941, "model_name", newJString(modelName))
  add(path_774941, "restapi_id", newJString(restapiId))
  result = call_774940.call(path_774941, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_774927(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_774928, base: "/",
    url: url_GetModelTemplate_774929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_774942 = ref object of OpenApiRestCall_772581
proc url_GetResources_774944(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_774943(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774945 = path.getOrDefault("restapi_id")
  valid_774945 = validateParameter(valid_774945, JString, required = true,
                                 default = nil)
  if valid_774945 != nil:
    section.add "restapi_id", valid_774945
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_774946 = query.getOrDefault("embed")
  valid_774946 = validateParameter(valid_774946, JArray, required = false,
                                 default = nil)
  if valid_774946 != nil:
    section.add "embed", valid_774946
  var valid_774947 = query.getOrDefault("position")
  valid_774947 = validateParameter(valid_774947, JString, required = false,
                                 default = nil)
  if valid_774947 != nil:
    section.add "position", valid_774947
  var valid_774948 = query.getOrDefault("limit")
  valid_774948 = validateParameter(valid_774948, JInt, required = false, default = nil)
  if valid_774948 != nil:
    section.add "limit", valid_774948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774949 = header.getOrDefault("X-Amz-Date")
  valid_774949 = validateParameter(valid_774949, JString, required = false,
                                 default = nil)
  if valid_774949 != nil:
    section.add "X-Amz-Date", valid_774949
  var valid_774950 = header.getOrDefault("X-Amz-Security-Token")
  valid_774950 = validateParameter(valid_774950, JString, required = false,
                                 default = nil)
  if valid_774950 != nil:
    section.add "X-Amz-Security-Token", valid_774950
  var valid_774951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774951 = validateParameter(valid_774951, JString, required = false,
                                 default = nil)
  if valid_774951 != nil:
    section.add "X-Amz-Content-Sha256", valid_774951
  var valid_774952 = header.getOrDefault("X-Amz-Algorithm")
  valid_774952 = validateParameter(valid_774952, JString, required = false,
                                 default = nil)
  if valid_774952 != nil:
    section.add "X-Amz-Algorithm", valid_774952
  var valid_774953 = header.getOrDefault("X-Amz-Signature")
  valid_774953 = validateParameter(valid_774953, JString, required = false,
                                 default = nil)
  if valid_774953 != nil:
    section.add "X-Amz-Signature", valid_774953
  var valid_774954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774954 = validateParameter(valid_774954, JString, required = false,
                                 default = nil)
  if valid_774954 != nil:
    section.add "X-Amz-SignedHeaders", valid_774954
  var valid_774955 = header.getOrDefault("X-Amz-Credential")
  valid_774955 = validateParameter(valid_774955, JString, required = false,
                                 default = nil)
  if valid_774955 != nil:
    section.add "X-Amz-Credential", valid_774955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774956: Call_GetResources_774942; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_774956.validator(path, query, header, formData, body)
  let scheme = call_774956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774956.url(scheme.get, call_774956.host, call_774956.base,
                         call_774956.route, valid.getOrDefault("path"))
  result = hook(call_774956, url, valid)

proc call*(call_774957: Call_GetResources_774942; restapiId: string;
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
  var path_774958 = newJObject()
  var query_774959 = newJObject()
  if embed != nil:
    query_774959.add "embed", embed
  add(query_774959, "position", newJString(position))
  add(query_774959, "limit", newJInt(limit))
  add(path_774958, "restapi_id", newJString(restapiId))
  result = call_774957.call(path_774958, query_774959, nil, nil, nil)

var getResources* = Call_GetResources_774942(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_774943,
    base: "/", url: url_GetResources_774944, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_774960 = ref object of OpenApiRestCall_772581
proc url_GetSdk_774962(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_774961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774963 = path.getOrDefault("sdk_type")
  valid_774963 = validateParameter(valid_774963, JString, required = true,
                                 default = nil)
  if valid_774963 != nil:
    section.add "sdk_type", valid_774963
  var valid_774964 = path.getOrDefault("stage_name")
  valid_774964 = validateParameter(valid_774964, JString, required = true,
                                 default = nil)
  if valid_774964 != nil:
    section.add "stage_name", valid_774964
  var valid_774965 = path.getOrDefault("restapi_id")
  valid_774965 = validateParameter(valid_774965, JString, required = true,
                                 default = nil)
  if valid_774965 != nil:
    section.add "restapi_id", valid_774965
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_774966 = query.getOrDefault("parameters.0.value")
  valid_774966 = validateParameter(valid_774966, JString, required = false,
                                 default = nil)
  if valid_774966 != nil:
    section.add "parameters.0.value", valid_774966
  var valid_774967 = query.getOrDefault("parameters.2.value")
  valid_774967 = validateParameter(valid_774967, JString, required = false,
                                 default = nil)
  if valid_774967 != nil:
    section.add "parameters.2.value", valid_774967
  var valid_774968 = query.getOrDefault("parameters.1.key")
  valid_774968 = validateParameter(valid_774968, JString, required = false,
                                 default = nil)
  if valid_774968 != nil:
    section.add "parameters.1.key", valid_774968
  var valid_774969 = query.getOrDefault("parameters.0.key")
  valid_774969 = validateParameter(valid_774969, JString, required = false,
                                 default = nil)
  if valid_774969 != nil:
    section.add "parameters.0.key", valid_774969
  var valid_774970 = query.getOrDefault("parameters.2.key")
  valid_774970 = validateParameter(valid_774970, JString, required = false,
                                 default = nil)
  if valid_774970 != nil:
    section.add "parameters.2.key", valid_774970
  var valid_774971 = query.getOrDefault("parameters.1.value")
  valid_774971 = validateParameter(valid_774971, JString, required = false,
                                 default = nil)
  if valid_774971 != nil:
    section.add "parameters.1.value", valid_774971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774972 = header.getOrDefault("X-Amz-Date")
  valid_774972 = validateParameter(valid_774972, JString, required = false,
                                 default = nil)
  if valid_774972 != nil:
    section.add "X-Amz-Date", valid_774972
  var valid_774973 = header.getOrDefault("X-Amz-Security-Token")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Security-Token", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Content-Sha256", valid_774974
  var valid_774975 = header.getOrDefault("X-Amz-Algorithm")
  valid_774975 = validateParameter(valid_774975, JString, required = false,
                                 default = nil)
  if valid_774975 != nil:
    section.add "X-Amz-Algorithm", valid_774975
  var valid_774976 = header.getOrDefault("X-Amz-Signature")
  valid_774976 = validateParameter(valid_774976, JString, required = false,
                                 default = nil)
  if valid_774976 != nil:
    section.add "X-Amz-Signature", valid_774976
  var valid_774977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774977 = validateParameter(valid_774977, JString, required = false,
                                 default = nil)
  if valid_774977 != nil:
    section.add "X-Amz-SignedHeaders", valid_774977
  var valid_774978 = header.getOrDefault("X-Amz-Credential")
  valid_774978 = validateParameter(valid_774978, JString, required = false,
                                 default = nil)
  if valid_774978 != nil:
    section.add "X-Amz-Credential", valid_774978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774979: Call_GetSdk_774960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_774979.validator(path, query, header, formData, body)
  let scheme = call_774979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774979.url(scheme.get, call_774979.host, call_774979.base,
                         call_774979.route, valid.getOrDefault("path"))
  result = hook(call_774979, url, valid)

proc call*(call_774980: Call_GetSdk_774960; sdkType: string; stageName: string;
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
  var path_774981 = newJObject()
  var query_774982 = newJObject()
  add(path_774981, "sdk_type", newJString(sdkType))
  add(query_774982, "parameters.0.value", newJString(parameters0Value))
  add(query_774982, "parameters.2.value", newJString(parameters2Value))
  add(query_774982, "parameters.1.key", newJString(parameters1Key))
  add(query_774982, "parameters.0.key", newJString(parameters0Key))
  add(query_774982, "parameters.2.key", newJString(parameters2Key))
  add(path_774981, "stage_name", newJString(stageName))
  add(query_774982, "parameters.1.value", newJString(parameters1Value))
  add(path_774981, "restapi_id", newJString(restapiId))
  result = call_774980.call(path_774981, query_774982, nil, nil, nil)

var getSdk* = Call_GetSdk_774960(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_774961, base: "/",
                              url: url_GetSdk_774962,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_774983 = ref object of OpenApiRestCall_772581
proc url_GetSdkType_774985(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_774984(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_774986 = path.getOrDefault("sdktype_id")
  valid_774986 = validateParameter(valid_774986, JString, required = true,
                                 default = nil)
  if valid_774986 != nil:
    section.add "sdktype_id", valid_774986
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774987 = header.getOrDefault("X-Amz-Date")
  valid_774987 = validateParameter(valid_774987, JString, required = false,
                                 default = nil)
  if valid_774987 != nil:
    section.add "X-Amz-Date", valid_774987
  var valid_774988 = header.getOrDefault("X-Amz-Security-Token")
  valid_774988 = validateParameter(valid_774988, JString, required = false,
                                 default = nil)
  if valid_774988 != nil:
    section.add "X-Amz-Security-Token", valid_774988
  var valid_774989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774989 = validateParameter(valid_774989, JString, required = false,
                                 default = nil)
  if valid_774989 != nil:
    section.add "X-Amz-Content-Sha256", valid_774989
  var valid_774990 = header.getOrDefault("X-Amz-Algorithm")
  valid_774990 = validateParameter(valid_774990, JString, required = false,
                                 default = nil)
  if valid_774990 != nil:
    section.add "X-Amz-Algorithm", valid_774990
  var valid_774991 = header.getOrDefault("X-Amz-Signature")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "X-Amz-Signature", valid_774991
  var valid_774992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774992 = validateParameter(valid_774992, JString, required = false,
                                 default = nil)
  if valid_774992 != nil:
    section.add "X-Amz-SignedHeaders", valid_774992
  var valid_774993 = header.getOrDefault("X-Amz-Credential")
  valid_774993 = validateParameter(valid_774993, JString, required = false,
                                 default = nil)
  if valid_774993 != nil:
    section.add "X-Amz-Credential", valid_774993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774994: Call_GetSdkType_774983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774994.validator(path, query, header, formData, body)
  let scheme = call_774994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774994.url(scheme.get, call_774994.host, call_774994.base,
                         call_774994.route, valid.getOrDefault("path"))
  result = hook(call_774994, url, valid)

proc call*(call_774995: Call_GetSdkType_774983; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_774996 = newJObject()
  add(path_774996, "sdktype_id", newJString(sdktypeId))
  result = call_774995.call(path_774996, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_774983(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_774984,
                                      base: "/", url: url_GetSdkType_774985,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_774997 = ref object of OpenApiRestCall_772581
proc url_GetSdkTypes_774999(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSdkTypes_774998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775000 = query.getOrDefault("position")
  valid_775000 = validateParameter(valid_775000, JString, required = false,
                                 default = nil)
  if valid_775000 != nil:
    section.add "position", valid_775000
  var valid_775001 = query.getOrDefault("limit")
  valid_775001 = validateParameter(valid_775001, JInt, required = false, default = nil)
  if valid_775001 != nil:
    section.add "limit", valid_775001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775002 = header.getOrDefault("X-Amz-Date")
  valid_775002 = validateParameter(valid_775002, JString, required = false,
                                 default = nil)
  if valid_775002 != nil:
    section.add "X-Amz-Date", valid_775002
  var valid_775003 = header.getOrDefault("X-Amz-Security-Token")
  valid_775003 = validateParameter(valid_775003, JString, required = false,
                                 default = nil)
  if valid_775003 != nil:
    section.add "X-Amz-Security-Token", valid_775003
  var valid_775004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775004 = validateParameter(valid_775004, JString, required = false,
                                 default = nil)
  if valid_775004 != nil:
    section.add "X-Amz-Content-Sha256", valid_775004
  var valid_775005 = header.getOrDefault("X-Amz-Algorithm")
  valid_775005 = validateParameter(valid_775005, JString, required = false,
                                 default = nil)
  if valid_775005 != nil:
    section.add "X-Amz-Algorithm", valid_775005
  var valid_775006 = header.getOrDefault("X-Amz-Signature")
  valid_775006 = validateParameter(valid_775006, JString, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "X-Amz-Signature", valid_775006
  var valid_775007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-SignedHeaders", valid_775007
  var valid_775008 = header.getOrDefault("X-Amz-Credential")
  valid_775008 = validateParameter(valid_775008, JString, required = false,
                                 default = nil)
  if valid_775008 != nil:
    section.add "X-Amz-Credential", valid_775008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775009: Call_GetSdkTypes_774997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775009.validator(path, query, header, formData, body)
  let scheme = call_775009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775009.url(scheme.get, call_775009.host, call_775009.base,
                         call_775009.route, valid.getOrDefault("path"))
  result = hook(call_775009, url, valid)

proc call*(call_775010: Call_GetSdkTypes_774997; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_775011 = newJObject()
  add(query_775011, "position", newJString(position))
  add(query_775011, "limit", newJInt(limit))
  result = call_775010.call(nil, query_775011, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_774997(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_774998,
                                        base: "/", url: url_GetSdkTypes_774999,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_775029 = ref object of OpenApiRestCall_772581
proc url_TagResource_775031(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_775030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775032 = path.getOrDefault("resource_arn")
  valid_775032 = validateParameter(valid_775032, JString, required = true,
                                 default = nil)
  if valid_775032 != nil:
    section.add "resource_arn", valid_775032
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775033 = header.getOrDefault("X-Amz-Date")
  valid_775033 = validateParameter(valid_775033, JString, required = false,
                                 default = nil)
  if valid_775033 != nil:
    section.add "X-Amz-Date", valid_775033
  var valid_775034 = header.getOrDefault("X-Amz-Security-Token")
  valid_775034 = validateParameter(valid_775034, JString, required = false,
                                 default = nil)
  if valid_775034 != nil:
    section.add "X-Amz-Security-Token", valid_775034
  var valid_775035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775035 = validateParameter(valid_775035, JString, required = false,
                                 default = nil)
  if valid_775035 != nil:
    section.add "X-Amz-Content-Sha256", valid_775035
  var valid_775036 = header.getOrDefault("X-Amz-Algorithm")
  valid_775036 = validateParameter(valid_775036, JString, required = false,
                                 default = nil)
  if valid_775036 != nil:
    section.add "X-Amz-Algorithm", valid_775036
  var valid_775037 = header.getOrDefault("X-Amz-Signature")
  valid_775037 = validateParameter(valid_775037, JString, required = false,
                                 default = nil)
  if valid_775037 != nil:
    section.add "X-Amz-Signature", valid_775037
  var valid_775038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775038 = validateParameter(valid_775038, JString, required = false,
                                 default = nil)
  if valid_775038 != nil:
    section.add "X-Amz-SignedHeaders", valid_775038
  var valid_775039 = header.getOrDefault("X-Amz-Credential")
  valid_775039 = validateParameter(valid_775039, JString, required = false,
                                 default = nil)
  if valid_775039 != nil:
    section.add "X-Amz-Credential", valid_775039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775041: Call_TagResource_775029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_775041.validator(path, query, header, formData, body)
  let scheme = call_775041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775041.url(scheme.get, call_775041.host, call_775041.base,
                         call_775041.route, valid.getOrDefault("path"))
  result = hook(call_775041, url, valid)

proc call*(call_775042: Call_TagResource_775029; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_775043 = newJObject()
  var body_775044 = newJObject()
  add(path_775043, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_775044 = body
  result = call_775042.call(path_775043, nil, nil, nil, body_775044)

var tagResource* = Call_TagResource_775029(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_775030,
                                        base: "/", url: url_TagResource_775031,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_775012 = ref object of OpenApiRestCall_772581
proc url_GetTags_775014(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_775013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775015 = path.getOrDefault("resource_arn")
  valid_775015 = validateParameter(valid_775015, JString, required = true,
                                 default = nil)
  if valid_775015 != nil:
    section.add "resource_arn", valid_775015
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_775016 = query.getOrDefault("position")
  valid_775016 = validateParameter(valid_775016, JString, required = false,
                                 default = nil)
  if valid_775016 != nil:
    section.add "position", valid_775016
  var valid_775017 = query.getOrDefault("limit")
  valid_775017 = validateParameter(valid_775017, JInt, required = false, default = nil)
  if valid_775017 != nil:
    section.add "limit", valid_775017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775018 = header.getOrDefault("X-Amz-Date")
  valid_775018 = validateParameter(valid_775018, JString, required = false,
                                 default = nil)
  if valid_775018 != nil:
    section.add "X-Amz-Date", valid_775018
  var valid_775019 = header.getOrDefault("X-Amz-Security-Token")
  valid_775019 = validateParameter(valid_775019, JString, required = false,
                                 default = nil)
  if valid_775019 != nil:
    section.add "X-Amz-Security-Token", valid_775019
  var valid_775020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775020 = validateParameter(valid_775020, JString, required = false,
                                 default = nil)
  if valid_775020 != nil:
    section.add "X-Amz-Content-Sha256", valid_775020
  var valid_775021 = header.getOrDefault("X-Amz-Algorithm")
  valid_775021 = validateParameter(valid_775021, JString, required = false,
                                 default = nil)
  if valid_775021 != nil:
    section.add "X-Amz-Algorithm", valid_775021
  var valid_775022 = header.getOrDefault("X-Amz-Signature")
  valid_775022 = validateParameter(valid_775022, JString, required = false,
                                 default = nil)
  if valid_775022 != nil:
    section.add "X-Amz-Signature", valid_775022
  var valid_775023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775023 = validateParameter(valid_775023, JString, required = false,
                                 default = nil)
  if valid_775023 != nil:
    section.add "X-Amz-SignedHeaders", valid_775023
  var valid_775024 = header.getOrDefault("X-Amz-Credential")
  valid_775024 = validateParameter(valid_775024, JString, required = false,
                                 default = nil)
  if valid_775024 != nil:
    section.add "X-Amz-Credential", valid_775024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775025: Call_GetTags_775012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_775025.validator(path, query, header, formData, body)
  let scheme = call_775025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775025.url(scheme.get, call_775025.host, call_775025.base,
                         call_775025.route, valid.getOrDefault("path"))
  result = hook(call_775025, url, valid)

proc call*(call_775026: Call_GetTags_775012; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_775027 = newJObject()
  var query_775028 = newJObject()
  add(path_775027, "resource_arn", newJString(resourceArn))
  add(query_775028, "position", newJString(position))
  add(query_775028, "limit", newJInt(limit))
  result = call_775026.call(path_775027, query_775028, nil, nil, nil)

var getTags* = Call_GetTags_775012(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_775013, base: "/",
                                url: url_GetTags_775014,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_775045 = ref object of OpenApiRestCall_772581
proc url_GetUsage_775047(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_775046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775048 = path.getOrDefault("usageplanId")
  valid_775048 = validateParameter(valid_775048, JString, required = true,
                                 default = nil)
  if valid_775048 != nil:
    section.add "usageplanId", valid_775048
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
  var valid_775049 = query.getOrDefault("endDate")
  valid_775049 = validateParameter(valid_775049, JString, required = true,
                                 default = nil)
  if valid_775049 != nil:
    section.add "endDate", valid_775049
  var valid_775050 = query.getOrDefault("startDate")
  valid_775050 = validateParameter(valid_775050, JString, required = true,
                                 default = nil)
  if valid_775050 != nil:
    section.add "startDate", valid_775050
  var valid_775051 = query.getOrDefault("keyId")
  valid_775051 = validateParameter(valid_775051, JString, required = false,
                                 default = nil)
  if valid_775051 != nil:
    section.add "keyId", valid_775051
  var valid_775052 = query.getOrDefault("position")
  valid_775052 = validateParameter(valid_775052, JString, required = false,
                                 default = nil)
  if valid_775052 != nil:
    section.add "position", valid_775052
  var valid_775053 = query.getOrDefault("limit")
  valid_775053 = validateParameter(valid_775053, JInt, required = false, default = nil)
  if valid_775053 != nil:
    section.add "limit", valid_775053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775054 = header.getOrDefault("X-Amz-Date")
  valid_775054 = validateParameter(valid_775054, JString, required = false,
                                 default = nil)
  if valid_775054 != nil:
    section.add "X-Amz-Date", valid_775054
  var valid_775055 = header.getOrDefault("X-Amz-Security-Token")
  valid_775055 = validateParameter(valid_775055, JString, required = false,
                                 default = nil)
  if valid_775055 != nil:
    section.add "X-Amz-Security-Token", valid_775055
  var valid_775056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775056 = validateParameter(valid_775056, JString, required = false,
                                 default = nil)
  if valid_775056 != nil:
    section.add "X-Amz-Content-Sha256", valid_775056
  var valid_775057 = header.getOrDefault("X-Amz-Algorithm")
  valid_775057 = validateParameter(valid_775057, JString, required = false,
                                 default = nil)
  if valid_775057 != nil:
    section.add "X-Amz-Algorithm", valid_775057
  var valid_775058 = header.getOrDefault("X-Amz-Signature")
  valid_775058 = validateParameter(valid_775058, JString, required = false,
                                 default = nil)
  if valid_775058 != nil:
    section.add "X-Amz-Signature", valid_775058
  var valid_775059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775059 = validateParameter(valid_775059, JString, required = false,
                                 default = nil)
  if valid_775059 != nil:
    section.add "X-Amz-SignedHeaders", valid_775059
  var valid_775060 = header.getOrDefault("X-Amz-Credential")
  valid_775060 = validateParameter(valid_775060, JString, required = false,
                                 default = nil)
  if valid_775060 != nil:
    section.add "X-Amz-Credential", valid_775060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775061: Call_GetUsage_775045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_775061.validator(path, query, header, formData, body)
  let scheme = call_775061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775061.url(scheme.get, call_775061.host, call_775061.base,
                         call_775061.route, valid.getOrDefault("path"))
  result = hook(call_775061, url, valid)

proc call*(call_775062: Call_GetUsage_775045; endDate: string; startDate: string;
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
  var path_775063 = newJObject()
  var query_775064 = newJObject()
  add(query_775064, "endDate", newJString(endDate))
  add(query_775064, "startDate", newJString(startDate))
  add(path_775063, "usageplanId", newJString(usageplanId))
  add(query_775064, "keyId", newJString(keyId))
  add(query_775064, "position", newJString(position))
  add(query_775064, "limit", newJInt(limit))
  result = call_775062.call(path_775063, query_775064, nil, nil, nil)

var getUsage* = Call_GetUsage_775045(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_775046, base: "/",
                                  url: url_GetUsage_775047,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_775065 = ref object of OpenApiRestCall_772581
proc url_ImportApiKeys_775067(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportApiKeys_775066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775068 = query.getOrDefault("mode")
  valid_775068 = validateParameter(valid_775068, JString, required = true,
                                 default = newJString("import"))
  if valid_775068 != nil:
    section.add "mode", valid_775068
  var valid_775069 = query.getOrDefault("failonwarnings")
  valid_775069 = validateParameter(valid_775069, JBool, required = false, default = nil)
  if valid_775069 != nil:
    section.add "failonwarnings", valid_775069
  var valid_775070 = query.getOrDefault("format")
  valid_775070 = validateParameter(valid_775070, JString, required = true,
                                 default = newJString("csv"))
  if valid_775070 != nil:
    section.add "format", valid_775070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775071 = header.getOrDefault("X-Amz-Date")
  valid_775071 = validateParameter(valid_775071, JString, required = false,
                                 default = nil)
  if valid_775071 != nil:
    section.add "X-Amz-Date", valid_775071
  var valid_775072 = header.getOrDefault("X-Amz-Security-Token")
  valid_775072 = validateParameter(valid_775072, JString, required = false,
                                 default = nil)
  if valid_775072 != nil:
    section.add "X-Amz-Security-Token", valid_775072
  var valid_775073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775073 = validateParameter(valid_775073, JString, required = false,
                                 default = nil)
  if valid_775073 != nil:
    section.add "X-Amz-Content-Sha256", valid_775073
  var valid_775074 = header.getOrDefault("X-Amz-Algorithm")
  valid_775074 = validateParameter(valid_775074, JString, required = false,
                                 default = nil)
  if valid_775074 != nil:
    section.add "X-Amz-Algorithm", valid_775074
  var valid_775075 = header.getOrDefault("X-Amz-Signature")
  valid_775075 = validateParameter(valid_775075, JString, required = false,
                                 default = nil)
  if valid_775075 != nil:
    section.add "X-Amz-Signature", valid_775075
  var valid_775076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775076 = validateParameter(valid_775076, JString, required = false,
                                 default = nil)
  if valid_775076 != nil:
    section.add "X-Amz-SignedHeaders", valid_775076
  var valid_775077 = header.getOrDefault("X-Amz-Credential")
  valid_775077 = validateParameter(valid_775077, JString, required = false,
                                 default = nil)
  if valid_775077 != nil:
    section.add "X-Amz-Credential", valid_775077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775079: Call_ImportApiKeys_775065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_775079.validator(path, query, header, formData, body)
  let scheme = call_775079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775079.url(scheme.get, call_775079.host, call_775079.base,
                         call_775079.route, valid.getOrDefault("path"))
  result = hook(call_775079, url, valid)

proc call*(call_775080: Call_ImportApiKeys_775065; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_775081 = newJObject()
  var body_775082 = newJObject()
  add(query_775081, "mode", newJString(mode))
  add(query_775081, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_775082 = body
  add(query_775081, "format", newJString(format))
  result = call_775080.call(nil, query_775081, nil, nil, body_775082)

var importApiKeys* = Call_ImportApiKeys_775065(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_775066,
    base: "/", url: url_ImportApiKeys_775067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_775083 = ref object of OpenApiRestCall_772581
proc url_ImportRestApi_775085(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportRestApi_775084(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775086 = query.getOrDefault("parameters.0.value")
  valid_775086 = validateParameter(valid_775086, JString, required = false,
                                 default = nil)
  if valid_775086 != nil:
    section.add "parameters.0.value", valid_775086
  var valid_775087 = query.getOrDefault("parameters.2.value")
  valid_775087 = validateParameter(valid_775087, JString, required = false,
                                 default = nil)
  if valid_775087 != nil:
    section.add "parameters.2.value", valid_775087
  var valid_775088 = query.getOrDefault("parameters.1.key")
  valid_775088 = validateParameter(valid_775088, JString, required = false,
                                 default = nil)
  if valid_775088 != nil:
    section.add "parameters.1.key", valid_775088
  var valid_775089 = query.getOrDefault("parameters.0.key")
  valid_775089 = validateParameter(valid_775089, JString, required = false,
                                 default = nil)
  if valid_775089 != nil:
    section.add "parameters.0.key", valid_775089
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_775090 = query.getOrDefault("mode")
  valid_775090 = validateParameter(valid_775090, JString, required = true,
                                 default = newJString("import"))
  if valid_775090 != nil:
    section.add "mode", valid_775090
  var valid_775091 = query.getOrDefault("parameters.2.key")
  valid_775091 = validateParameter(valid_775091, JString, required = false,
                                 default = nil)
  if valid_775091 != nil:
    section.add "parameters.2.key", valid_775091
  var valid_775092 = query.getOrDefault("failonwarnings")
  valid_775092 = validateParameter(valid_775092, JBool, required = false, default = nil)
  if valid_775092 != nil:
    section.add "failonwarnings", valid_775092
  var valid_775093 = query.getOrDefault("parameters.1.value")
  valid_775093 = validateParameter(valid_775093, JString, required = false,
                                 default = nil)
  if valid_775093 != nil:
    section.add "parameters.1.value", valid_775093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775094 = header.getOrDefault("X-Amz-Date")
  valid_775094 = validateParameter(valid_775094, JString, required = false,
                                 default = nil)
  if valid_775094 != nil:
    section.add "X-Amz-Date", valid_775094
  var valid_775095 = header.getOrDefault("X-Amz-Security-Token")
  valid_775095 = validateParameter(valid_775095, JString, required = false,
                                 default = nil)
  if valid_775095 != nil:
    section.add "X-Amz-Security-Token", valid_775095
  var valid_775096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775096 = validateParameter(valid_775096, JString, required = false,
                                 default = nil)
  if valid_775096 != nil:
    section.add "X-Amz-Content-Sha256", valid_775096
  var valid_775097 = header.getOrDefault("X-Amz-Algorithm")
  valid_775097 = validateParameter(valid_775097, JString, required = false,
                                 default = nil)
  if valid_775097 != nil:
    section.add "X-Amz-Algorithm", valid_775097
  var valid_775098 = header.getOrDefault("X-Amz-Signature")
  valid_775098 = validateParameter(valid_775098, JString, required = false,
                                 default = nil)
  if valid_775098 != nil:
    section.add "X-Amz-Signature", valid_775098
  var valid_775099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775099 = validateParameter(valid_775099, JString, required = false,
                                 default = nil)
  if valid_775099 != nil:
    section.add "X-Amz-SignedHeaders", valid_775099
  var valid_775100 = header.getOrDefault("X-Amz-Credential")
  valid_775100 = validateParameter(valid_775100, JString, required = false,
                                 default = nil)
  if valid_775100 != nil:
    section.add "X-Amz-Credential", valid_775100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775102: Call_ImportRestApi_775083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_775102.validator(path, query, header, formData, body)
  let scheme = call_775102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775102.url(scheme.get, call_775102.host, call_775102.base,
                         call_775102.route, valid.getOrDefault("path"))
  result = hook(call_775102, url, valid)

proc call*(call_775103: Call_ImportRestApi_775083; body: JsonNode;
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
  var query_775104 = newJObject()
  var body_775105 = newJObject()
  add(query_775104, "parameters.0.value", newJString(parameters0Value))
  add(query_775104, "parameters.2.value", newJString(parameters2Value))
  add(query_775104, "parameters.1.key", newJString(parameters1Key))
  add(query_775104, "parameters.0.key", newJString(parameters0Key))
  add(query_775104, "mode", newJString(mode))
  add(query_775104, "parameters.2.key", newJString(parameters2Key))
  add(query_775104, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_775105 = body
  add(query_775104, "parameters.1.value", newJString(parameters1Value))
  result = call_775103.call(nil, query_775104, nil, nil, body_775105)

var importRestApi* = Call_ImportRestApi_775083(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_775084,
    base: "/", url: url_ImportRestApi_775085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_775106 = ref object of OpenApiRestCall_772581
proc url_UntagResource_775108(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_775107(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775109 = path.getOrDefault("resource_arn")
  valid_775109 = validateParameter(valid_775109, JString, required = true,
                                 default = nil)
  if valid_775109 != nil:
    section.add "resource_arn", valid_775109
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_775110 = query.getOrDefault("tagKeys")
  valid_775110 = validateParameter(valid_775110, JArray, required = true, default = nil)
  if valid_775110 != nil:
    section.add "tagKeys", valid_775110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775111 = header.getOrDefault("X-Amz-Date")
  valid_775111 = validateParameter(valid_775111, JString, required = false,
                                 default = nil)
  if valid_775111 != nil:
    section.add "X-Amz-Date", valid_775111
  var valid_775112 = header.getOrDefault("X-Amz-Security-Token")
  valid_775112 = validateParameter(valid_775112, JString, required = false,
                                 default = nil)
  if valid_775112 != nil:
    section.add "X-Amz-Security-Token", valid_775112
  var valid_775113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775113 = validateParameter(valid_775113, JString, required = false,
                                 default = nil)
  if valid_775113 != nil:
    section.add "X-Amz-Content-Sha256", valid_775113
  var valid_775114 = header.getOrDefault("X-Amz-Algorithm")
  valid_775114 = validateParameter(valid_775114, JString, required = false,
                                 default = nil)
  if valid_775114 != nil:
    section.add "X-Amz-Algorithm", valid_775114
  var valid_775115 = header.getOrDefault("X-Amz-Signature")
  valid_775115 = validateParameter(valid_775115, JString, required = false,
                                 default = nil)
  if valid_775115 != nil:
    section.add "X-Amz-Signature", valid_775115
  var valid_775116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775116 = validateParameter(valid_775116, JString, required = false,
                                 default = nil)
  if valid_775116 != nil:
    section.add "X-Amz-SignedHeaders", valid_775116
  var valid_775117 = header.getOrDefault("X-Amz-Credential")
  valid_775117 = validateParameter(valid_775117, JString, required = false,
                                 default = nil)
  if valid_775117 != nil:
    section.add "X-Amz-Credential", valid_775117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775118: Call_UntagResource_775106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_775118.validator(path, query, header, formData, body)
  let scheme = call_775118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775118.url(scheme.get, call_775118.host, call_775118.base,
                         call_775118.route, valid.getOrDefault("path"))
  result = hook(call_775118, url, valid)

proc call*(call_775119: Call_UntagResource_775106; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_775120 = newJObject()
  var query_775121 = newJObject()
  add(path_775120, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_775121.add "tagKeys", tagKeys
  result = call_775119.call(path_775120, query_775121, nil, nil, nil)

var untagResource* = Call_UntagResource_775106(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_775107,
    base: "/", url: url_UntagResource_775108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_775122 = ref object of OpenApiRestCall_772581
proc url_UpdateUsage_775124(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_775123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775125 = path.getOrDefault("keyId")
  valid_775125 = validateParameter(valid_775125, JString, required = true,
                                 default = nil)
  if valid_775125 != nil:
    section.add "keyId", valid_775125
  var valid_775126 = path.getOrDefault("usageplanId")
  valid_775126 = validateParameter(valid_775126, JString, required = true,
                                 default = nil)
  if valid_775126 != nil:
    section.add "usageplanId", valid_775126
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775127 = header.getOrDefault("X-Amz-Date")
  valid_775127 = validateParameter(valid_775127, JString, required = false,
                                 default = nil)
  if valid_775127 != nil:
    section.add "X-Amz-Date", valid_775127
  var valid_775128 = header.getOrDefault("X-Amz-Security-Token")
  valid_775128 = validateParameter(valid_775128, JString, required = false,
                                 default = nil)
  if valid_775128 != nil:
    section.add "X-Amz-Security-Token", valid_775128
  var valid_775129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775129 = validateParameter(valid_775129, JString, required = false,
                                 default = nil)
  if valid_775129 != nil:
    section.add "X-Amz-Content-Sha256", valid_775129
  var valid_775130 = header.getOrDefault("X-Amz-Algorithm")
  valid_775130 = validateParameter(valid_775130, JString, required = false,
                                 default = nil)
  if valid_775130 != nil:
    section.add "X-Amz-Algorithm", valid_775130
  var valid_775131 = header.getOrDefault("X-Amz-Signature")
  valid_775131 = validateParameter(valid_775131, JString, required = false,
                                 default = nil)
  if valid_775131 != nil:
    section.add "X-Amz-Signature", valid_775131
  var valid_775132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775132 = validateParameter(valid_775132, JString, required = false,
                                 default = nil)
  if valid_775132 != nil:
    section.add "X-Amz-SignedHeaders", valid_775132
  var valid_775133 = header.getOrDefault("X-Amz-Credential")
  valid_775133 = validateParameter(valid_775133, JString, required = false,
                                 default = nil)
  if valid_775133 != nil:
    section.add "X-Amz-Credential", valid_775133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775135: Call_UpdateUsage_775122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_775135.validator(path, query, header, formData, body)
  let scheme = call_775135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775135.url(scheme.get, call_775135.host, call_775135.base,
                         call_775135.route, valid.getOrDefault("path"))
  result = hook(call_775135, url, valid)

proc call*(call_775136: Call_UpdateUsage_775122; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_775137 = newJObject()
  var body_775138 = newJObject()
  add(path_775137, "keyId", newJString(keyId))
  add(path_775137, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_775138 = body
  result = call_775136.call(path_775137, nil, nil, nil, body_775138)

var updateUsage* = Call_UpdateUsage_775122(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_775123,
                                        base: "/", url: url_UpdateUsage_775124,
                                        schemes: {Scheme.Https, Scheme.Http})
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
