
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_594018 = ref object of OpenApiRestCall_593421
proc url_CreateApiKey_594020(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApiKey_594019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594021 = header.getOrDefault("X-Amz-Date")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Date", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Security-Token")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Security-Token", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Content-Sha256", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Algorithm")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Algorithm", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Signature")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Signature", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-SignedHeaders", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-Credential")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Credential", valid_594027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594029: Call_CreateApiKey_594018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_594029.validator(path, query, header, formData, body)
  let scheme = call_594029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594029.url(scheme.get, call_594029.host, call_594029.base,
                         call_594029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594029, url, valid)

proc call*(call_594030: Call_CreateApiKey_594018; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_594031 = newJObject()
  if body != nil:
    body_594031 = body
  result = call_594030.call(nil, nil, nil, nil, body_594031)

var createApiKey* = Call_CreateApiKey_594018(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_594019, base: "/", url: url_CreateApiKey_594020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_593758 = ref object of OpenApiRestCall_593421
proc url_GetApiKeys_593760(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApiKeys_593759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593872 = query.getOrDefault("customerId")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "customerId", valid_593872
  var valid_593873 = query.getOrDefault("includeValues")
  valid_593873 = validateParameter(valid_593873, JBool, required = false, default = nil)
  if valid_593873 != nil:
    section.add "includeValues", valid_593873
  var valid_593874 = query.getOrDefault("name")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "name", valid_593874
  var valid_593875 = query.getOrDefault("position")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "position", valid_593875
  var valid_593876 = query.getOrDefault("limit")
  valid_593876 = validateParameter(valid_593876, JInt, required = false, default = nil)
  if valid_593876 != nil:
    section.add "limit", valid_593876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593877 = header.getOrDefault("X-Amz-Date")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Date", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Security-Token")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Security-Token", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Content-Sha256", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-Algorithm")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-Algorithm", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-Signature")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Signature", valid_593881
  var valid_593882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-SignedHeaders", valid_593882
  var valid_593883 = header.getOrDefault("X-Amz-Credential")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Credential", valid_593883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593906: Call_GetApiKeys_593758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_593906.validator(path, query, header, formData, body)
  let scheme = call_593906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593906.url(scheme.get, call_593906.host, call_593906.base,
                         call_593906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593906, url, valid)

proc call*(call_593977: Call_GetApiKeys_593758; customerId: string = "";
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
  var query_593978 = newJObject()
  add(query_593978, "customerId", newJString(customerId))
  add(query_593978, "includeValues", newJBool(includeValues))
  add(query_593978, "name", newJString(name))
  add(query_593978, "position", newJString(position))
  add(query_593978, "limit", newJInt(limit))
  result = call_593977.call(nil, query_593978, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_593758(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_593759,
                                      base: "/", url: url_GetApiKeys_593760,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_594063 = ref object of OpenApiRestCall_593421
proc url_CreateAuthorizer_594065(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateAuthorizer_594064(path: JsonNode; query: JsonNode;
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
  var valid_594066 = path.getOrDefault("restapi_id")
  valid_594066 = validateParameter(valid_594066, JString, required = true,
                                 default = nil)
  if valid_594066 != nil:
    section.add "restapi_id", valid_594066
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594067 = header.getOrDefault("X-Amz-Date")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Date", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Security-Token")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Security-Token", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Content-Sha256", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Algorithm")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Algorithm", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Signature")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Signature", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-SignedHeaders", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Credential")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Credential", valid_594073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594075: Call_CreateAuthorizer_594063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_594075.validator(path, query, header, formData, body)
  let scheme = call_594075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594075.url(scheme.get, call_594075.host, call_594075.base,
                         call_594075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594075, url, valid)

proc call*(call_594076: Call_CreateAuthorizer_594063; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594077 = newJObject()
  var body_594078 = newJObject()
  if body != nil:
    body_594078 = body
  add(path_594077, "restapi_id", newJString(restapiId))
  result = call_594076.call(path_594077, nil, nil, nil, body_594078)

var createAuthorizer* = Call_CreateAuthorizer_594063(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_594064, base: "/",
    url: url_CreateAuthorizer_594065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_594032 = ref object of OpenApiRestCall_593421
proc url_GetAuthorizers_594034(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetAuthorizers_594033(path: JsonNode; query: JsonNode;
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
  var valid_594049 = path.getOrDefault("restapi_id")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = nil)
  if valid_594049 != nil:
    section.add "restapi_id", valid_594049
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594050 = query.getOrDefault("position")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "position", valid_594050
  var valid_594051 = query.getOrDefault("limit")
  valid_594051 = validateParameter(valid_594051, JInt, required = false, default = nil)
  if valid_594051 != nil:
    section.add "limit", valid_594051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594052 = header.getOrDefault("X-Amz-Date")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Date", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Security-Token")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Security-Token", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Content-Sha256", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Algorithm")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Algorithm", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Signature")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Signature", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-SignedHeaders", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Credential")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Credential", valid_594058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_GetAuthorizers_594032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_GetAuthorizers_594032; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594061 = newJObject()
  var query_594062 = newJObject()
  add(query_594062, "position", newJString(position))
  add(query_594062, "limit", newJInt(limit))
  add(path_594061, "restapi_id", newJString(restapiId))
  result = call_594060.call(path_594061, query_594062, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_594032(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_594033, base: "/", url: url_GetAuthorizers_594034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_594096 = ref object of OpenApiRestCall_593421
proc url_CreateBasePathMapping_594098(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateBasePathMapping_594097(path: JsonNode; query: JsonNode;
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
  var valid_594099 = path.getOrDefault("domain_name")
  valid_594099 = validateParameter(valid_594099, JString, required = true,
                                 default = nil)
  if valid_594099 != nil:
    section.add "domain_name", valid_594099
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594100 = header.getOrDefault("X-Amz-Date")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Date", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Content-Sha256", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Algorithm")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Algorithm", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Signature")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Signature", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-SignedHeaders", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Credential")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Credential", valid_594106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594108: Call_CreateBasePathMapping_594096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_594108.validator(path, query, header, formData, body)
  let scheme = call_594108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594108.url(scheme.get, call_594108.host, call_594108.base,
                         call_594108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594108, url, valid)

proc call*(call_594109: Call_CreateBasePathMapping_594096; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_594110 = newJObject()
  var body_594111 = newJObject()
  add(path_594110, "domain_name", newJString(domainName))
  if body != nil:
    body_594111 = body
  result = call_594109.call(path_594110, nil, nil, nil, body_594111)

var createBasePathMapping* = Call_CreateBasePathMapping_594096(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_594097, base: "/",
    url: url_CreateBasePathMapping_594098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_594079 = ref object of OpenApiRestCall_593421
proc url_GetBasePathMappings_594081(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetBasePathMappings_594080(path: JsonNode; query: JsonNode;
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
  var valid_594082 = path.getOrDefault("domain_name")
  valid_594082 = validateParameter(valid_594082, JString, required = true,
                                 default = nil)
  if valid_594082 != nil:
    section.add "domain_name", valid_594082
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594083 = query.getOrDefault("position")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "position", valid_594083
  var valid_594084 = query.getOrDefault("limit")
  valid_594084 = validateParameter(valid_594084, JInt, required = false, default = nil)
  if valid_594084 != nil:
    section.add "limit", valid_594084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594085 = header.getOrDefault("X-Amz-Date")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Date", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Security-Token")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Security-Token", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Content-Sha256", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Algorithm")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Algorithm", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Signature")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Signature", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-SignedHeaders", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Credential")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Credential", valid_594091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594092: Call_GetBasePathMappings_594079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_594092.validator(path, query, header, formData, body)
  let scheme = call_594092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594092.url(scheme.get, call_594092.host, call_594092.base,
                         call_594092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594092, url, valid)

proc call*(call_594093: Call_GetBasePathMappings_594079; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_594094 = newJObject()
  var query_594095 = newJObject()
  add(path_594094, "domain_name", newJString(domainName))
  add(query_594095, "position", newJString(position))
  add(query_594095, "limit", newJInt(limit))
  result = call_594093.call(path_594094, query_594095, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_594079(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_594080, base: "/",
    url: url_GetBasePathMappings_594081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_594129 = ref object of OpenApiRestCall_593421
proc url_CreateDeployment_594131(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateDeployment_594130(path: JsonNode; query: JsonNode;
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
  var valid_594132 = path.getOrDefault("restapi_id")
  valid_594132 = validateParameter(valid_594132, JString, required = true,
                                 default = nil)
  if valid_594132 != nil:
    section.add "restapi_id", valid_594132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594133 = header.getOrDefault("X-Amz-Date")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Date", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Security-Token")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Security-Token", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Content-Sha256", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Algorithm")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Algorithm", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Signature")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Signature", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-SignedHeaders", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Credential")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Credential", valid_594139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594141: Call_CreateDeployment_594129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_594141.validator(path, query, header, formData, body)
  let scheme = call_594141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594141.url(scheme.get, call_594141.host, call_594141.base,
                         call_594141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594141, url, valid)

proc call*(call_594142: Call_CreateDeployment_594129; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594143 = newJObject()
  var body_594144 = newJObject()
  if body != nil:
    body_594144 = body
  add(path_594143, "restapi_id", newJString(restapiId))
  result = call_594142.call(path_594143, nil, nil, nil, body_594144)

var createDeployment* = Call_CreateDeployment_594129(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_594130, base: "/",
    url: url_CreateDeployment_594131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_594112 = ref object of OpenApiRestCall_593421
proc url_GetDeployments_594114(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeployments_594113(path: JsonNode; query: JsonNode;
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
  var valid_594115 = path.getOrDefault("restapi_id")
  valid_594115 = validateParameter(valid_594115, JString, required = true,
                                 default = nil)
  if valid_594115 != nil:
    section.add "restapi_id", valid_594115
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594116 = query.getOrDefault("position")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "position", valid_594116
  var valid_594117 = query.getOrDefault("limit")
  valid_594117 = validateParameter(valid_594117, JInt, required = false, default = nil)
  if valid_594117 != nil:
    section.add "limit", valid_594117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594118 = header.getOrDefault("X-Amz-Date")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Date", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Security-Token")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Security-Token", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Content-Sha256", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Algorithm")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Algorithm", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Signature")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Signature", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-SignedHeaders", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Credential")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Credential", valid_594124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594125: Call_GetDeployments_594112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_594125.validator(path, query, header, formData, body)
  let scheme = call_594125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594125.url(scheme.get, call_594125.host, call_594125.base,
                         call_594125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594125, url, valid)

proc call*(call_594126: Call_GetDeployments_594112; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594127 = newJObject()
  var query_594128 = newJObject()
  add(query_594128, "position", newJString(position))
  add(query_594128, "limit", newJInt(limit))
  add(path_594127, "restapi_id", newJString(restapiId))
  result = call_594126.call(path_594127, query_594128, nil, nil, nil)

var getDeployments* = Call_GetDeployments_594112(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_594113, base: "/", url: url_GetDeployments_594114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_594179 = ref object of OpenApiRestCall_593421
proc url_ImportDocumentationParts_594181(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ImportDocumentationParts_594180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_594182 = path.getOrDefault("restapi_id")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = nil)
  if valid_594182 != nil:
    section.add "restapi_id", valid_594182
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_594183 = query.getOrDefault("mode")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = newJString("merge"))
  if valid_594183 != nil:
    section.add "mode", valid_594183
  var valid_594184 = query.getOrDefault("failonwarnings")
  valid_594184 = validateParameter(valid_594184, JBool, required = false, default = nil)
  if valid_594184 != nil:
    section.add "failonwarnings", valid_594184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594185 = header.getOrDefault("X-Amz-Date")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Date", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Security-Token")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Security-Token", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Content-Sha256", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Algorithm")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Algorithm", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Signature")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Signature", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-SignedHeaders", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Credential")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Credential", valid_594191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594193: Call_ImportDocumentationParts_594179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594193.validator(path, query, header, formData, body)
  let scheme = call_594193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594193.url(scheme.get, call_594193.host, call_594193.base,
                         call_594193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594193, url, valid)

proc call*(call_594194: Call_ImportDocumentationParts_594179; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594195 = newJObject()
  var query_594196 = newJObject()
  var body_594197 = newJObject()
  add(query_594196, "mode", newJString(mode))
  add(query_594196, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_594197 = body
  add(path_594195, "restapi_id", newJString(restapiId))
  result = call_594194.call(path_594195, query_594196, nil, nil, body_594197)

var importDocumentationParts* = Call_ImportDocumentationParts_594179(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_594180, base: "/",
    url: url_ImportDocumentationParts_594181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_594198 = ref object of OpenApiRestCall_593421
proc url_CreateDocumentationPart_594200(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateDocumentationPart_594199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_594201 = path.getOrDefault("restapi_id")
  valid_594201 = validateParameter(valid_594201, JString, required = true,
                                 default = nil)
  if valid_594201 != nil:
    section.add "restapi_id", valid_594201
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594202 = header.getOrDefault("X-Amz-Date")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Date", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Security-Token")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Security-Token", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Content-Sha256", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Algorithm")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Algorithm", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Signature")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Signature", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-SignedHeaders", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Credential")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Credential", valid_594208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594210: Call_CreateDocumentationPart_594198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594210.validator(path, query, header, formData, body)
  let scheme = call_594210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594210.url(scheme.get, call_594210.host, call_594210.base,
                         call_594210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594210, url, valid)

proc call*(call_594211: Call_CreateDocumentationPart_594198; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594212 = newJObject()
  var body_594213 = newJObject()
  if body != nil:
    body_594213 = body
  add(path_594212, "restapi_id", newJString(restapiId))
  result = call_594211.call(path_594212, nil, nil, nil, body_594213)

var createDocumentationPart* = Call_CreateDocumentationPart_594198(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_594199, base: "/",
    url: url_CreateDocumentationPart_594200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_594145 = ref object of OpenApiRestCall_593421
proc url_GetDocumentationParts_594147(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentationParts_594146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_594148 = path.getOrDefault("restapi_id")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = nil)
  if valid_594148 != nil:
    section.add "restapi_id", valid_594148
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
  var valid_594162 = query.getOrDefault("type")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = newJString("API"))
  if valid_594162 != nil:
    section.add "type", valid_594162
  var valid_594163 = query.getOrDefault("path")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "path", valid_594163
  var valid_594164 = query.getOrDefault("locationStatus")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_594164 != nil:
    section.add "locationStatus", valid_594164
  var valid_594165 = query.getOrDefault("name")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "name", valid_594165
  var valid_594166 = query.getOrDefault("position")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "position", valid_594166
  var valid_594167 = query.getOrDefault("limit")
  valid_594167 = validateParameter(valid_594167, JInt, required = false, default = nil)
  if valid_594167 != nil:
    section.add "limit", valid_594167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594168 = header.getOrDefault("X-Amz-Date")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Date", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Content-Sha256", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Algorithm")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Algorithm", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Signature")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Signature", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-SignedHeaders", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Credential")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Credential", valid_594174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_GetDocumentationParts_594145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_GetDocumentationParts_594145; restapiId: string;
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
  var path_594177 = newJObject()
  var query_594178 = newJObject()
  add(query_594178, "type", newJString(`type`))
  add(query_594178, "path", newJString(path))
  add(query_594178, "locationStatus", newJString(locationStatus))
  add(query_594178, "name", newJString(name))
  add(query_594178, "position", newJString(position))
  add(query_594178, "limit", newJInt(limit))
  add(path_594177, "restapi_id", newJString(restapiId))
  result = call_594176.call(path_594177, query_594178, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_594145(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_594146, base: "/",
    url: url_GetDocumentationParts_594147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_594231 = ref object of OpenApiRestCall_593421
proc url_CreateDocumentationVersion_594233(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateDocumentationVersion_594232(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_594234 = path.getOrDefault("restapi_id")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = nil)
  if valid_594234 != nil:
    section.add "restapi_id", valid_594234
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594235 = header.getOrDefault("X-Amz-Date")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Date", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Security-Token")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Security-Token", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Content-Sha256", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Algorithm")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Algorithm", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Signature")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Signature", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-SignedHeaders", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Credential")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Credential", valid_594241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594243: Call_CreateDocumentationVersion_594231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594243.validator(path, query, header, formData, body)
  let scheme = call_594243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594243.url(scheme.get, call_594243.host, call_594243.base,
                         call_594243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594243, url, valid)

proc call*(call_594244: Call_CreateDocumentationVersion_594231; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594245 = newJObject()
  var body_594246 = newJObject()
  if body != nil:
    body_594246 = body
  add(path_594245, "restapi_id", newJString(restapiId))
  result = call_594244.call(path_594245, nil, nil, nil, body_594246)

var createDocumentationVersion* = Call_CreateDocumentationVersion_594231(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_594232, base: "/",
    url: url_CreateDocumentationVersion_594233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_594214 = ref object of OpenApiRestCall_593421
proc url_GetDocumentationVersions_594216(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentationVersions_594215(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_594217 = path.getOrDefault("restapi_id")
  valid_594217 = validateParameter(valid_594217, JString, required = true,
                                 default = nil)
  if valid_594217 != nil:
    section.add "restapi_id", valid_594217
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594218 = query.getOrDefault("position")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "position", valid_594218
  var valid_594219 = query.getOrDefault("limit")
  valid_594219 = validateParameter(valid_594219, JInt, required = false, default = nil)
  if valid_594219 != nil:
    section.add "limit", valid_594219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594220 = header.getOrDefault("X-Amz-Date")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Date", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Security-Token")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Security-Token", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Content-Sha256", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Algorithm")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Algorithm", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Signature")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Signature", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-SignedHeaders", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Credential")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Credential", valid_594226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594227: Call_GetDocumentationVersions_594214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594227.validator(path, query, header, formData, body)
  let scheme = call_594227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594227.url(scheme.get, call_594227.host, call_594227.base,
                         call_594227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594227, url, valid)

proc call*(call_594228: Call_GetDocumentationVersions_594214; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594229 = newJObject()
  var query_594230 = newJObject()
  add(query_594230, "position", newJString(position))
  add(query_594230, "limit", newJInt(limit))
  add(path_594229, "restapi_id", newJString(restapiId))
  result = call_594228.call(path_594229, query_594230, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_594214(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_594215, base: "/",
    url: url_GetDocumentationVersions_594216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_594262 = ref object of OpenApiRestCall_593421
proc url_CreateDomainName_594264(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainName_594263(path: JsonNode; query: JsonNode;
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
  var valid_594265 = header.getOrDefault("X-Amz-Date")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Date", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Security-Token")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Security-Token", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Content-Sha256", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Algorithm")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Algorithm", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Signature")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Signature", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-SignedHeaders", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Credential")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Credential", valid_594271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594273: Call_CreateDomainName_594262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_594273.validator(path, query, header, formData, body)
  let scheme = call_594273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594273.url(scheme.get, call_594273.host, call_594273.base,
                         call_594273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594273, url, valid)

proc call*(call_594274: Call_CreateDomainName_594262; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_594275 = newJObject()
  if body != nil:
    body_594275 = body
  result = call_594274.call(nil, nil, nil, nil, body_594275)

var createDomainName* = Call_CreateDomainName_594262(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_594263, base: "/",
    url: url_CreateDomainName_594264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_594247 = ref object of OpenApiRestCall_593421
proc url_GetDomainNames_594249(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainNames_594248(path: JsonNode; query: JsonNode;
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
  var valid_594250 = query.getOrDefault("position")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "position", valid_594250
  var valid_594251 = query.getOrDefault("limit")
  valid_594251 = validateParameter(valid_594251, JInt, required = false, default = nil)
  if valid_594251 != nil:
    section.add "limit", valid_594251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594252 = header.getOrDefault("X-Amz-Date")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Date", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Security-Token")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Security-Token", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Content-Sha256", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Algorithm")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Algorithm", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Signature")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Signature", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-SignedHeaders", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594259: Call_GetDomainNames_594247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_594259.validator(path, query, header, formData, body)
  let scheme = call_594259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594259.url(scheme.get, call_594259.host, call_594259.base,
                         call_594259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594259, url, valid)

proc call*(call_594260: Call_GetDomainNames_594247; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_594261 = newJObject()
  add(query_594261, "position", newJString(position))
  add(query_594261, "limit", newJInt(limit))
  result = call_594260.call(nil, query_594261, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_594247(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_594248, base: "/",
    url: url_GetDomainNames_594249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_594293 = ref object of OpenApiRestCall_593421
proc url_CreateModel_594295(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateModel_594294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594296 = path.getOrDefault("restapi_id")
  valid_594296 = validateParameter(valid_594296, JString, required = true,
                                 default = nil)
  if valid_594296 != nil:
    section.add "restapi_id", valid_594296
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594297 = header.getOrDefault("X-Amz-Date")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Date", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Security-Token")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Security-Token", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Content-Sha256", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Algorithm")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Algorithm", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-SignedHeaders", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Credential")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Credential", valid_594303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594305: Call_CreateModel_594293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_594305.validator(path, query, header, formData, body)
  let scheme = call_594305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594305.url(scheme.get, call_594305.host, call_594305.base,
                         call_594305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594305, url, valid)

proc call*(call_594306: Call_CreateModel_594293; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_594307 = newJObject()
  var body_594308 = newJObject()
  if body != nil:
    body_594308 = body
  add(path_594307, "restapi_id", newJString(restapiId))
  result = call_594306.call(path_594307, nil, nil, nil, body_594308)

var createModel* = Call_CreateModel_594293(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_594294,
                                        base: "/", url: url_CreateModel_594295,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_594276 = ref object of OpenApiRestCall_593421
proc url_GetModels_594278(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetModels_594277(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594279 = path.getOrDefault("restapi_id")
  valid_594279 = validateParameter(valid_594279, JString, required = true,
                                 default = nil)
  if valid_594279 != nil:
    section.add "restapi_id", valid_594279
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594280 = query.getOrDefault("position")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "position", valid_594280
  var valid_594281 = query.getOrDefault("limit")
  valid_594281 = validateParameter(valid_594281, JInt, required = false, default = nil)
  if valid_594281 != nil:
    section.add "limit", valid_594281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594282 = header.getOrDefault("X-Amz-Date")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Date", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Security-Token")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Security-Token", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Content-Sha256", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Algorithm")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Algorithm", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Signature")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Signature", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-SignedHeaders", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Credential")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Credential", valid_594288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594289: Call_GetModels_594276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_594289.validator(path, query, header, formData, body)
  let scheme = call_594289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594289.url(scheme.get, call_594289.host, call_594289.base,
                         call_594289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594289, url, valid)

proc call*(call_594290: Call_GetModels_594276; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594291 = newJObject()
  var query_594292 = newJObject()
  add(query_594292, "position", newJString(position))
  add(query_594292, "limit", newJInt(limit))
  add(path_594291, "restapi_id", newJString(restapiId))
  result = call_594290.call(path_594291, query_594292, nil, nil, nil)

var getModels* = Call_GetModels_594276(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_594277,
                                    base: "/", url: url_GetModels_594278,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_594326 = ref object of OpenApiRestCall_593421
proc url_CreateRequestValidator_594328(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateRequestValidator_594327(path: JsonNode; query: JsonNode;
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
  var valid_594329 = path.getOrDefault("restapi_id")
  valid_594329 = validateParameter(valid_594329, JString, required = true,
                                 default = nil)
  if valid_594329 != nil:
    section.add "restapi_id", valid_594329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594330 = header.getOrDefault("X-Amz-Date")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Date", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Security-Token")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Security-Token", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Algorithm")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Algorithm", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Signature")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Signature", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-SignedHeaders", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Credential")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Credential", valid_594336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_CreateRequestValidator_594326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_CreateRequestValidator_594326; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594340 = newJObject()
  var body_594341 = newJObject()
  if body != nil:
    body_594341 = body
  add(path_594340, "restapi_id", newJString(restapiId))
  result = call_594339.call(path_594340, nil, nil, nil, body_594341)

var createRequestValidator* = Call_CreateRequestValidator_594326(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_594327, base: "/",
    url: url_CreateRequestValidator_594328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_594309 = ref object of OpenApiRestCall_593421
proc url_GetRequestValidators_594311(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetRequestValidators_594310(path: JsonNode; query: JsonNode;
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
  var valid_594312 = path.getOrDefault("restapi_id")
  valid_594312 = validateParameter(valid_594312, JString, required = true,
                                 default = nil)
  if valid_594312 != nil:
    section.add "restapi_id", valid_594312
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594313 = query.getOrDefault("position")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "position", valid_594313
  var valid_594314 = query.getOrDefault("limit")
  valid_594314 = validateParameter(valid_594314, JInt, required = false, default = nil)
  if valid_594314 != nil:
    section.add "limit", valid_594314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594315 = header.getOrDefault("X-Amz-Date")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Date", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Security-Token")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Security-Token", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Content-Sha256", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Algorithm")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Algorithm", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Signature")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Signature", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-SignedHeaders", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Credential")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Credential", valid_594321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594322: Call_GetRequestValidators_594309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_594322.validator(path, query, header, formData, body)
  let scheme = call_594322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594322.url(scheme.get, call_594322.host, call_594322.base,
                         call_594322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594322, url, valid)

proc call*(call_594323: Call_GetRequestValidators_594309; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594324 = newJObject()
  var query_594325 = newJObject()
  add(query_594325, "position", newJString(position))
  add(query_594325, "limit", newJInt(limit))
  add(path_594324, "restapi_id", newJString(restapiId))
  result = call_594323.call(path_594324, query_594325, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_594309(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_594310, base: "/",
    url: url_GetRequestValidators_594311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_594342 = ref object of OpenApiRestCall_593421
proc url_CreateResource_594344(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateResource_594343(path: JsonNode; query: JsonNode;
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
  var valid_594345 = path.getOrDefault("parent_id")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = nil)
  if valid_594345 != nil:
    section.add "parent_id", valid_594345
  var valid_594346 = path.getOrDefault("restapi_id")
  valid_594346 = validateParameter(valid_594346, JString, required = true,
                                 default = nil)
  if valid_594346 != nil:
    section.add "restapi_id", valid_594346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594347 = header.getOrDefault("X-Amz-Date")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Date", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Security-Token")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Security-Token", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_CreateResource_594342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_CreateResource_594342; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594357 = newJObject()
  var body_594358 = newJObject()
  add(path_594357, "parent_id", newJString(parentId))
  if body != nil:
    body_594358 = body
  add(path_594357, "restapi_id", newJString(restapiId))
  result = call_594356.call(path_594357, nil, nil, nil, body_594358)

var createResource* = Call_CreateResource_594342(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_594343, base: "/", url: url_CreateResource_594344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_594374 = ref object of OpenApiRestCall_593421
proc url_CreateRestApi_594376(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRestApi_594375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594377 = header.getOrDefault("X-Amz-Date")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Date", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Security-Token")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Security-Token", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_CreateRestApi_594374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_CreateRestApi_594374; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var createRestApi* = Call_CreateRestApi_594374(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_594375, base: "/", url: url_CreateRestApi_594376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_594359 = ref object of OpenApiRestCall_593421
proc url_GetRestApis_594361(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestApis_594360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594362 = query.getOrDefault("position")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "position", valid_594362
  var valid_594363 = query.getOrDefault("limit")
  valid_594363 = validateParameter(valid_594363, JInt, required = false, default = nil)
  if valid_594363 != nil:
    section.add "limit", valid_594363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594364 = header.getOrDefault("X-Amz-Date")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Date", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Security-Token")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Security-Token", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Content-Sha256", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Algorithm")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Algorithm", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Signature")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Signature", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-SignedHeaders", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Credential")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Credential", valid_594370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_GetRestApis_594359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_GetRestApis_594359; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_594373 = newJObject()
  add(query_594373, "position", newJString(position))
  add(query_594373, "limit", newJInt(limit))
  result = call_594372.call(nil, query_594373, nil, nil, nil)

var getRestApis* = Call_GetRestApis_594359(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_594360,
                                        base: "/", url: url_GetRestApis_594361,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_594404 = ref object of OpenApiRestCall_593421
proc url_CreateStage_594406(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateStage_594405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594407 = path.getOrDefault("restapi_id")
  valid_594407 = validateParameter(valid_594407, JString, required = true,
                                 default = nil)
  if valid_594407 != nil:
    section.add "restapi_id", valid_594407
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594408 = header.getOrDefault("X-Amz-Date")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Date", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Security-Token")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Security-Token", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Content-Sha256", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Algorithm")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Algorithm", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Signature")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Signature", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-SignedHeaders", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Credential")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Credential", valid_594414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_CreateStage_594404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_CreateStage_594404; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594418 = newJObject()
  var body_594419 = newJObject()
  if body != nil:
    body_594419 = body
  add(path_594418, "restapi_id", newJString(restapiId))
  result = call_594417.call(path_594418, nil, nil, nil, body_594419)

var createStage* = Call_CreateStage_594404(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_594405,
                                        base: "/", url: url_CreateStage_594406,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_594388 = ref object of OpenApiRestCall_593421
proc url_GetStages_594390(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetStages_594389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594391 = path.getOrDefault("restapi_id")
  valid_594391 = validateParameter(valid_594391, JString, required = true,
                                 default = nil)
  if valid_594391 != nil:
    section.add "restapi_id", valid_594391
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_594392 = query.getOrDefault("deploymentId")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "deploymentId", valid_594392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594393 = header.getOrDefault("X-Amz-Date")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Date", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Security-Token")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Security-Token", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Algorithm")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Algorithm", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Signature")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Signature", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-SignedHeaders", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Credential")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Credential", valid_594399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594400: Call_GetStages_594388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_594400.validator(path, query, header, formData, body)
  let scheme = call_594400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594400.url(scheme.get, call_594400.host, call_594400.base,
                         call_594400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594400, url, valid)

proc call*(call_594401: Call_GetStages_594388; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594402 = newJObject()
  var query_594403 = newJObject()
  add(query_594403, "deploymentId", newJString(deploymentId))
  add(path_594402, "restapi_id", newJString(restapiId))
  result = call_594401.call(path_594402, query_594403, nil, nil, nil)

var getStages* = Call_GetStages_594388(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_594389,
                                    base: "/", url: url_GetStages_594390,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_594436 = ref object of OpenApiRestCall_593421
proc url_CreateUsagePlan_594438(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUsagePlan_594437(path: JsonNode; query: JsonNode;
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
  var valid_594439 = header.getOrDefault("X-Amz-Date")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Date", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Security-Token")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Security-Token", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Content-Sha256", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Algorithm")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Algorithm", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Signature")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Signature", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-SignedHeaders", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Credential")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Credential", valid_594445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594447: Call_CreateUsagePlan_594436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_594447.validator(path, query, header, formData, body)
  let scheme = call_594447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594447.url(scheme.get, call_594447.host, call_594447.base,
                         call_594447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594447, url, valid)

proc call*(call_594448: Call_CreateUsagePlan_594436; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_594449 = newJObject()
  if body != nil:
    body_594449 = body
  result = call_594448.call(nil, nil, nil, nil, body_594449)

var createUsagePlan* = Call_CreateUsagePlan_594436(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_594437, base: "/",
    url: url_CreateUsagePlan_594438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_594420 = ref object of OpenApiRestCall_593421
proc url_GetUsagePlans_594422(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUsagePlans_594421(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594423 = query.getOrDefault("keyId")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "keyId", valid_594423
  var valid_594424 = query.getOrDefault("position")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "position", valid_594424
  var valid_594425 = query.getOrDefault("limit")
  valid_594425 = validateParameter(valid_594425, JInt, required = false, default = nil)
  if valid_594425 != nil:
    section.add "limit", valid_594425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594426 = header.getOrDefault("X-Amz-Date")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Date", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Security-Token")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Security-Token", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Content-Sha256", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Signature")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Signature", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-SignedHeaders", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594433: Call_GetUsagePlans_594420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_594433.validator(path, query, header, formData, body)
  let scheme = call_594433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594433.url(scheme.get, call_594433.host, call_594433.base,
                         call_594433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594433, url, valid)

proc call*(call_594434: Call_GetUsagePlans_594420; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_594435 = newJObject()
  add(query_594435, "keyId", newJString(keyId))
  add(query_594435, "position", newJString(position))
  add(query_594435, "limit", newJInt(limit))
  result = call_594434.call(nil, query_594435, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_594420(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_594421, base: "/",
    url: url_GetUsagePlans_594422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_594468 = ref object of OpenApiRestCall_593421
proc url_CreateUsagePlanKey_594470(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateUsagePlanKey_594469(path: JsonNode; query: JsonNode;
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
  var valid_594471 = path.getOrDefault("usageplanId")
  valid_594471 = validateParameter(valid_594471, JString, required = true,
                                 default = nil)
  if valid_594471 != nil:
    section.add "usageplanId", valid_594471
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594472 = header.getOrDefault("X-Amz-Date")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Date", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Security-Token")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Security-Token", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Content-Sha256", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Algorithm")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Algorithm", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Signature")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Signature", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-SignedHeaders", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Credential")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Credential", valid_594478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594480: Call_CreateUsagePlanKey_594468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_594480.validator(path, query, header, formData, body)
  let scheme = call_594480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594480.url(scheme.get, call_594480.host, call_594480.base,
                         call_594480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594480, url, valid)

proc call*(call_594481: Call_CreateUsagePlanKey_594468; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_594482 = newJObject()
  var body_594483 = newJObject()
  add(path_594482, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_594483 = body
  result = call_594481.call(path_594482, nil, nil, nil, body_594483)

var createUsagePlanKey* = Call_CreateUsagePlanKey_594468(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_594469, base: "/",
    url: url_CreateUsagePlanKey_594470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_594450 = ref object of OpenApiRestCall_593421
proc url_GetUsagePlanKeys_594452(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUsagePlanKeys_594451(path: JsonNode; query: JsonNode;
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
  var valid_594453 = path.getOrDefault("usageplanId")
  valid_594453 = validateParameter(valid_594453, JString, required = true,
                                 default = nil)
  if valid_594453 != nil:
    section.add "usageplanId", valid_594453
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_594454 = query.getOrDefault("name")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "name", valid_594454
  var valid_594455 = query.getOrDefault("position")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "position", valid_594455
  var valid_594456 = query.getOrDefault("limit")
  valid_594456 = validateParameter(valid_594456, JInt, required = false, default = nil)
  if valid_594456 != nil:
    section.add "limit", valid_594456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594457 = header.getOrDefault("X-Amz-Date")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Date", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Security-Token")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Security-Token", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Content-Sha256", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Algorithm")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Algorithm", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Signature")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Signature", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-SignedHeaders", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Credential")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Credential", valid_594463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_GetUsagePlanKeys_594450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_GetUsagePlanKeys_594450; usageplanId: string;
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
  var path_594466 = newJObject()
  var query_594467 = newJObject()
  add(path_594466, "usageplanId", newJString(usageplanId))
  add(query_594467, "name", newJString(name))
  add(query_594467, "position", newJString(position))
  add(query_594467, "limit", newJInt(limit))
  result = call_594465.call(path_594466, query_594467, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_594450(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_594451,
    base: "/", url: url_GetUsagePlanKeys_594452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_594499 = ref object of OpenApiRestCall_593421
proc url_CreateVpcLink_594501(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVpcLink_594500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594502 = header.getOrDefault("X-Amz-Date")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Date", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Security-Token")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Security-Token", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Content-Sha256", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Algorithm")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Algorithm", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Signature")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Signature", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-SignedHeaders", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Credential")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Credential", valid_594508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594510: Call_CreateVpcLink_594499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_594510.validator(path, query, header, formData, body)
  let scheme = call_594510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594510.url(scheme.get, call_594510.host, call_594510.base,
                         call_594510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594510, url, valid)

proc call*(call_594511: Call_CreateVpcLink_594499; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_594512 = newJObject()
  if body != nil:
    body_594512 = body
  result = call_594511.call(nil, nil, nil, nil, body_594512)

var createVpcLink* = Call_CreateVpcLink_594499(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_594500, base: "/", url: url_CreateVpcLink_594501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_594484 = ref object of OpenApiRestCall_593421
proc url_GetVpcLinks_594486(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVpcLinks_594485(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594487 = query.getOrDefault("position")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "position", valid_594487
  var valid_594488 = query.getOrDefault("limit")
  valid_594488 = validateParameter(valid_594488, JInt, required = false, default = nil)
  if valid_594488 != nil:
    section.add "limit", valid_594488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594489 = header.getOrDefault("X-Amz-Date")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Date", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Security-Token")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Security-Token", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Content-Sha256", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Algorithm")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Algorithm", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Signature")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Signature", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-SignedHeaders", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Credential")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Credential", valid_594495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594496: Call_GetVpcLinks_594484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_594496.validator(path, query, header, formData, body)
  let scheme = call_594496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594496.url(scheme.get, call_594496.host, call_594496.base,
                         call_594496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594496, url, valid)

proc call*(call_594497: Call_GetVpcLinks_594484; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_594498 = newJObject()
  add(query_594498, "position", newJString(position))
  add(query_594498, "limit", newJInt(limit))
  result = call_594497.call(nil, query_594498, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_594484(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_594485,
                                        base: "/", url: url_GetVpcLinks_594486,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_594513 = ref object of OpenApiRestCall_593421
proc url_GetApiKey_594515(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetApiKey_594514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594516 = path.getOrDefault("api_Key")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = nil)
  if valid_594516 != nil:
    section.add "api_Key", valid_594516
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_594517 = query.getOrDefault("includeValue")
  valid_594517 = validateParameter(valid_594517, JBool, required = false, default = nil)
  if valid_594517 != nil:
    section.add "includeValue", valid_594517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Security-Token")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Security-Token", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594525: Call_GetApiKey_594513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_594525.validator(path, query, header, formData, body)
  let scheme = call_594525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594525.url(scheme.get, call_594525.host, call_594525.base,
                         call_594525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594525, url, valid)

proc call*(call_594526: Call_GetApiKey_594513; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_594527 = newJObject()
  var query_594528 = newJObject()
  add(query_594528, "includeValue", newJBool(includeValue))
  add(path_594527, "api_Key", newJString(apiKey))
  result = call_594526.call(path_594527, query_594528, nil, nil, nil)

var getApiKey* = Call_GetApiKey_594513(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_594514,
                                    base: "/", url: url_GetApiKey_594515,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_594543 = ref object of OpenApiRestCall_593421
proc url_UpdateApiKey_594545(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApiKey_594544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594546 = path.getOrDefault("api_Key")
  valid_594546 = validateParameter(valid_594546, JString, required = true,
                                 default = nil)
  if valid_594546 != nil:
    section.add "api_Key", valid_594546
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594547 = header.getOrDefault("X-Amz-Date")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Date", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Security-Token")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Security-Token", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Content-Sha256", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Algorithm")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Algorithm", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Signature")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Signature", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-SignedHeaders", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Credential")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Credential", valid_594553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594555: Call_UpdateApiKey_594543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_594555.validator(path, query, header, formData, body)
  let scheme = call_594555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594555.url(scheme.get, call_594555.host, call_594555.base,
                         call_594555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594555, url, valid)

proc call*(call_594556: Call_UpdateApiKey_594543; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_594557 = newJObject()
  var body_594558 = newJObject()
  add(path_594557, "api_Key", newJString(apiKey))
  if body != nil:
    body_594558 = body
  result = call_594556.call(path_594557, nil, nil, nil, body_594558)

var updateApiKey* = Call_UpdateApiKey_594543(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_594544, base: "/",
    url: url_UpdateApiKey_594545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_594529 = ref object of OpenApiRestCall_593421
proc url_DeleteApiKey_594531(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApiKey_594530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594532 = path.getOrDefault("api_Key")
  valid_594532 = validateParameter(valid_594532, JString, required = true,
                                 default = nil)
  if valid_594532 != nil:
    section.add "api_Key", valid_594532
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Security-Token")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Security-Token", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Content-Sha256", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Signature")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Signature", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-SignedHeaders", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Credential")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Credential", valid_594539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594540: Call_DeleteApiKey_594529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_594540.validator(path, query, header, formData, body)
  let scheme = call_594540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594540.url(scheme.get, call_594540.host, call_594540.base,
                         call_594540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594540, url, valid)

proc call*(call_594541: Call_DeleteApiKey_594529; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_594542 = newJObject()
  add(path_594542, "api_Key", newJString(apiKey))
  result = call_594541.call(path_594542, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_594529(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_594530, base: "/",
    url: url_DeleteApiKey_594531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_594574 = ref object of OpenApiRestCall_593421
proc url_TestInvokeAuthorizer_594576(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TestInvokeAuthorizer_594575(path: JsonNode; query: JsonNode;
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
  var valid_594577 = path.getOrDefault("authorizer_id")
  valid_594577 = validateParameter(valid_594577, JString, required = true,
                                 default = nil)
  if valid_594577 != nil:
    section.add "authorizer_id", valid_594577
  var valid_594578 = path.getOrDefault("restapi_id")
  valid_594578 = validateParameter(valid_594578, JString, required = true,
                                 default = nil)
  if valid_594578 != nil:
    section.add "restapi_id", valid_594578
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594579 = header.getOrDefault("X-Amz-Date")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Date", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Security-Token")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Security-Token", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Content-Sha256", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Algorithm")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Algorithm", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Signature")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Signature", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-SignedHeaders", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-Credential")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Credential", valid_594585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594587: Call_TestInvokeAuthorizer_594574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_594587.validator(path, query, header, formData, body)
  let scheme = call_594587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594587.url(scheme.get, call_594587.host, call_594587.base,
                         call_594587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594587, url, valid)

proc call*(call_594588: Call_TestInvokeAuthorizer_594574; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594589 = newJObject()
  var body_594590 = newJObject()
  add(path_594589, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_594590 = body
  add(path_594589, "restapi_id", newJString(restapiId))
  result = call_594588.call(path_594589, nil, nil, nil, body_594590)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_594574(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_594575, base: "/",
    url: url_TestInvokeAuthorizer_594576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_594559 = ref object of OpenApiRestCall_593421
proc url_GetAuthorizer_594561(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetAuthorizer_594560(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594562 = path.getOrDefault("authorizer_id")
  valid_594562 = validateParameter(valid_594562, JString, required = true,
                                 default = nil)
  if valid_594562 != nil:
    section.add "authorizer_id", valid_594562
  var valid_594563 = path.getOrDefault("restapi_id")
  valid_594563 = validateParameter(valid_594563, JString, required = true,
                                 default = nil)
  if valid_594563 != nil:
    section.add "restapi_id", valid_594563
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594564 = header.getOrDefault("X-Amz-Date")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Date", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Security-Token")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Security-Token", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Content-Sha256", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Algorithm")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Algorithm", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Signature")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Signature", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-SignedHeaders", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Credential")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Credential", valid_594570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594571: Call_GetAuthorizer_594559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_594571.validator(path, query, header, formData, body)
  let scheme = call_594571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594571.url(scheme.get, call_594571.host, call_594571.base,
                         call_594571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594571, url, valid)

proc call*(call_594572: Call_GetAuthorizer_594559; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594573 = newJObject()
  add(path_594573, "authorizer_id", newJString(authorizerId))
  add(path_594573, "restapi_id", newJString(restapiId))
  result = call_594572.call(path_594573, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_594559(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_594560, base: "/", url: url_GetAuthorizer_594561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_594606 = ref object of OpenApiRestCall_593421
proc url_UpdateAuthorizer_594608(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateAuthorizer_594607(path: JsonNode; query: JsonNode;
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
  var valid_594609 = path.getOrDefault("authorizer_id")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = nil)
  if valid_594609 != nil:
    section.add "authorizer_id", valid_594609
  var valid_594610 = path.getOrDefault("restapi_id")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = nil)
  if valid_594610 != nil:
    section.add "restapi_id", valid_594610
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594611 = header.getOrDefault("X-Amz-Date")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Date", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Security-Token")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Security-Token", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Content-Sha256", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Algorithm")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Algorithm", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Signature")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Signature", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-SignedHeaders", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Credential")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Credential", valid_594617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594619: Call_UpdateAuthorizer_594606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_594619.validator(path, query, header, formData, body)
  let scheme = call_594619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594619.url(scheme.get, call_594619.host, call_594619.base,
                         call_594619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594619, url, valid)

proc call*(call_594620: Call_UpdateAuthorizer_594606; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594621 = newJObject()
  var body_594622 = newJObject()
  add(path_594621, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_594622 = body
  add(path_594621, "restapi_id", newJString(restapiId))
  result = call_594620.call(path_594621, nil, nil, nil, body_594622)

var updateAuthorizer* = Call_UpdateAuthorizer_594606(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_594607, base: "/",
    url: url_UpdateAuthorizer_594608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_594591 = ref object of OpenApiRestCall_593421
proc url_DeleteAuthorizer_594593(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteAuthorizer_594592(path: JsonNode; query: JsonNode;
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
  var valid_594594 = path.getOrDefault("authorizer_id")
  valid_594594 = validateParameter(valid_594594, JString, required = true,
                                 default = nil)
  if valid_594594 != nil:
    section.add "authorizer_id", valid_594594
  var valid_594595 = path.getOrDefault("restapi_id")
  valid_594595 = validateParameter(valid_594595, JString, required = true,
                                 default = nil)
  if valid_594595 != nil:
    section.add "restapi_id", valid_594595
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594596 = header.getOrDefault("X-Amz-Date")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Date", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Security-Token")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Security-Token", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Content-Sha256", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Algorithm")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Algorithm", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Signature")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Signature", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-SignedHeaders", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Credential")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Credential", valid_594602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594603: Call_DeleteAuthorizer_594591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_594603.validator(path, query, header, formData, body)
  let scheme = call_594603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594603.url(scheme.get, call_594603.host, call_594603.base,
                         call_594603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594603, url, valid)

proc call*(call_594604: Call_DeleteAuthorizer_594591; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594605 = newJObject()
  add(path_594605, "authorizer_id", newJString(authorizerId))
  add(path_594605, "restapi_id", newJString(restapiId))
  result = call_594604.call(path_594605, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_594591(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_594592, base: "/",
    url: url_DeleteAuthorizer_594593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_594623 = ref object of OpenApiRestCall_593421
proc url_GetBasePathMapping_594625(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetBasePathMapping_594624(path: JsonNode; query: JsonNode;
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
  var valid_594626 = path.getOrDefault("base_path")
  valid_594626 = validateParameter(valid_594626, JString, required = true,
                                 default = nil)
  if valid_594626 != nil:
    section.add "base_path", valid_594626
  var valid_594627 = path.getOrDefault("domain_name")
  valid_594627 = validateParameter(valid_594627, JString, required = true,
                                 default = nil)
  if valid_594627 != nil:
    section.add "domain_name", valid_594627
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594628 = header.getOrDefault("X-Amz-Date")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Date", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Security-Token")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Security-Token", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Content-Sha256", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Algorithm")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Algorithm", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Signature")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Signature", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-SignedHeaders", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Credential")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Credential", valid_594634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594635: Call_GetBasePathMapping_594623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_594635.validator(path, query, header, formData, body)
  let scheme = call_594635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594635.url(scheme.get, call_594635.host, call_594635.base,
                         call_594635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594635, url, valid)

proc call*(call_594636: Call_GetBasePathMapping_594623; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_594637 = newJObject()
  add(path_594637, "base_path", newJString(basePath))
  add(path_594637, "domain_name", newJString(domainName))
  result = call_594636.call(path_594637, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_594623(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_594624, base: "/",
    url: url_GetBasePathMapping_594625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_594653 = ref object of OpenApiRestCall_593421
proc url_UpdateBasePathMapping_594655(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBasePathMapping_594654(path: JsonNode; query: JsonNode;
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
  var valid_594656 = path.getOrDefault("base_path")
  valid_594656 = validateParameter(valid_594656, JString, required = true,
                                 default = nil)
  if valid_594656 != nil:
    section.add "base_path", valid_594656
  var valid_594657 = path.getOrDefault("domain_name")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = nil)
  if valid_594657 != nil:
    section.add "domain_name", valid_594657
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594658 = header.getOrDefault("X-Amz-Date")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Date", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Security-Token")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Security-Token", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Content-Sha256", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Algorithm")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Algorithm", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Signature")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Signature", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-SignedHeaders", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Credential")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Credential", valid_594664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594666: Call_UpdateBasePathMapping_594653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_594666.validator(path, query, header, formData, body)
  let scheme = call_594666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594666.url(scheme.get, call_594666.host, call_594666.base,
                         call_594666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594666, url, valid)

proc call*(call_594667: Call_UpdateBasePathMapping_594653; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_594668 = newJObject()
  var body_594669 = newJObject()
  add(path_594668, "base_path", newJString(basePath))
  add(path_594668, "domain_name", newJString(domainName))
  if body != nil:
    body_594669 = body
  result = call_594667.call(path_594668, nil, nil, nil, body_594669)

var updateBasePathMapping* = Call_UpdateBasePathMapping_594653(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_594654, base: "/",
    url: url_UpdateBasePathMapping_594655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_594638 = ref object of OpenApiRestCall_593421
proc url_DeleteBasePathMapping_594640(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteBasePathMapping_594639(path: JsonNode; query: JsonNode;
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
  var valid_594641 = path.getOrDefault("base_path")
  valid_594641 = validateParameter(valid_594641, JString, required = true,
                                 default = nil)
  if valid_594641 != nil:
    section.add "base_path", valid_594641
  var valid_594642 = path.getOrDefault("domain_name")
  valid_594642 = validateParameter(valid_594642, JString, required = true,
                                 default = nil)
  if valid_594642 != nil:
    section.add "domain_name", valid_594642
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594643 = header.getOrDefault("X-Amz-Date")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Date", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Security-Token")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Security-Token", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Content-Sha256", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Algorithm")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Algorithm", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Signature")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Signature", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-SignedHeaders", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Credential")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Credential", valid_594649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594650: Call_DeleteBasePathMapping_594638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_594650.validator(path, query, header, formData, body)
  let scheme = call_594650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594650.url(scheme.get, call_594650.host, call_594650.base,
                         call_594650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594650, url, valid)

proc call*(call_594651: Call_DeleteBasePathMapping_594638; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_594652 = newJObject()
  add(path_594652, "base_path", newJString(basePath))
  add(path_594652, "domain_name", newJString(domainName))
  result = call_594651.call(path_594652, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_594638(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_594639, base: "/",
    url: url_DeleteBasePathMapping_594640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_594670 = ref object of OpenApiRestCall_593421
proc url_GetClientCertificate_594672(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetClientCertificate_594671(path: JsonNode; query: JsonNode;
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
  var valid_594673 = path.getOrDefault("clientcertificate_id")
  valid_594673 = validateParameter(valid_594673, JString, required = true,
                                 default = nil)
  if valid_594673 != nil:
    section.add "clientcertificate_id", valid_594673
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594674 = header.getOrDefault("X-Amz-Date")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Date", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Security-Token")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Security-Token", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Content-Sha256", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Algorithm")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Algorithm", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Signature")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Signature", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-SignedHeaders", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Credential")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Credential", valid_594680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594681: Call_GetClientCertificate_594670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_594681.validator(path, query, header, formData, body)
  let scheme = call_594681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594681.url(scheme.get, call_594681.host, call_594681.base,
                         call_594681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594681, url, valid)

proc call*(call_594682: Call_GetClientCertificate_594670;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_594683 = newJObject()
  add(path_594683, "clientcertificate_id", newJString(clientcertificateId))
  result = call_594682.call(path_594683, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_594670(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_594671, base: "/",
    url: url_GetClientCertificate_594672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_594698 = ref object of OpenApiRestCall_593421
proc url_UpdateClientCertificate_594700(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateClientCertificate_594699(path: JsonNode; query: JsonNode;
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
  var valid_594701 = path.getOrDefault("clientcertificate_id")
  valid_594701 = validateParameter(valid_594701, JString, required = true,
                                 default = nil)
  if valid_594701 != nil:
    section.add "clientcertificate_id", valid_594701
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594702 = header.getOrDefault("X-Amz-Date")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Date", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Security-Token")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Security-Token", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Content-Sha256", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Algorithm")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Algorithm", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Signature")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Signature", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-SignedHeaders", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-Credential")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Credential", valid_594708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594710: Call_UpdateClientCertificate_594698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_594710.validator(path, query, header, formData, body)
  let scheme = call_594710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594710.url(scheme.get, call_594710.host, call_594710.base,
                         call_594710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594710, url, valid)

proc call*(call_594711: Call_UpdateClientCertificate_594698;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_594712 = newJObject()
  var body_594713 = newJObject()
  add(path_594712, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_594713 = body
  result = call_594711.call(path_594712, nil, nil, nil, body_594713)

var updateClientCertificate* = Call_UpdateClientCertificate_594698(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_594699, base: "/",
    url: url_UpdateClientCertificate_594700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_594684 = ref object of OpenApiRestCall_593421
proc url_DeleteClientCertificate_594686(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteClientCertificate_594685(path: JsonNode; query: JsonNode;
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
  var valid_594687 = path.getOrDefault("clientcertificate_id")
  valid_594687 = validateParameter(valid_594687, JString, required = true,
                                 default = nil)
  if valid_594687 != nil:
    section.add "clientcertificate_id", valid_594687
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594688 = header.getOrDefault("X-Amz-Date")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Date", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Security-Token")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Security-Token", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Content-Sha256", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Algorithm")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Algorithm", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Signature")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Signature", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-SignedHeaders", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Credential")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Credential", valid_594694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594695: Call_DeleteClientCertificate_594684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_594695.validator(path, query, header, formData, body)
  let scheme = call_594695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594695.url(scheme.get, call_594695.host, call_594695.base,
                         call_594695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594695, url, valid)

proc call*(call_594696: Call_DeleteClientCertificate_594684;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_594697 = newJObject()
  add(path_594697, "clientcertificate_id", newJString(clientcertificateId))
  result = call_594696.call(path_594697, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_594684(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_594685, base: "/",
    url: url_DeleteClientCertificate_594686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_594714 = ref object of OpenApiRestCall_593421
proc url_GetDeployment_594716(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeployment_594715(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594717 = path.getOrDefault("deployment_id")
  valid_594717 = validateParameter(valid_594717, JString, required = true,
                                 default = nil)
  if valid_594717 != nil:
    section.add "deployment_id", valid_594717
  var valid_594718 = path.getOrDefault("restapi_id")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = nil)
  if valid_594718 != nil:
    section.add "restapi_id", valid_594718
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_594719 = query.getOrDefault("embed")
  valid_594719 = validateParameter(valid_594719, JArray, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "embed", valid_594719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594720 = header.getOrDefault("X-Amz-Date")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Date", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Security-Token")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Security-Token", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Content-Sha256", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Algorithm")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Algorithm", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Signature")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Signature", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-SignedHeaders", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Credential")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Credential", valid_594726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594727: Call_GetDeployment_594714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_594727.validator(path, query, header, formData, body)
  let scheme = call_594727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594727.url(scheme.get, call_594727.host, call_594727.base,
                         call_594727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594727, url, valid)

proc call*(call_594728: Call_GetDeployment_594714; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594729 = newJObject()
  var query_594730 = newJObject()
  add(path_594729, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_594730.add "embed", embed
  add(path_594729, "restapi_id", newJString(restapiId))
  result = call_594728.call(path_594729, query_594730, nil, nil, nil)

var getDeployment* = Call_GetDeployment_594714(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_594715, base: "/", url: url_GetDeployment_594716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_594746 = ref object of OpenApiRestCall_593421
proc url_UpdateDeployment_594748(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDeployment_594747(path: JsonNode; query: JsonNode;
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
  var valid_594749 = path.getOrDefault("deployment_id")
  valid_594749 = validateParameter(valid_594749, JString, required = true,
                                 default = nil)
  if valid_594749 != nil:
    section.add "deployment_id", valid_594749
  var valid_594750 = path.getOrDefault("restapi_id")
  valid_594750 = validateParameter(valid_594750, JString, required = true,
                                 default = nil)
  if valid_594750 != nil:
    section.add "restapi_id", valid_594750
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Content-Sha256", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Algorithm")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Algorithm", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Signature")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Signature", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-SignedHeaders", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Credential")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Credential", valid_594757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594759: Call_UpdateDeployment_594746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_594759.validator(path, query, header, formData, body)
  let scheme = call_594759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594759.url(scheme.get, call_594759.host, call_594759.base,
                         call_594759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594759, url, valid)

proc call*(call_594760: Call_UpdateDeployment_594746; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594761 = newJObject()
  var body_594762 = newJObject()
  add(path_594761, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_594762 = body
  add(path_594761, "restapi_id", newJString(restapiId))
  result = call_594760.call(path_594761, nil, nil, nil, body_594762)

var updateDeployment* = Call_UpdateDeployment_594746(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_594747, base: "/",
    url: url_UpdateDeployment_594748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_594731 = ref object of OpenApiRestCall_593421
proc url_DeleteDeployment_594733(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDeployment_594732(path: JsonNode; query: JsonNode;
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
  var valid_594734 = path.getOrDefault("deployment_id")
  valid_594734 = validateParameter(valid_594734, JString, required = true,
                                 default = nil)
  if valid_594734 != nil:
    section.add "deployment_id", valid_594734
  var valid_594735 = path.getOrDefault("restapi_id")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = nil)
  if valid_594735 != nil:
    section.add "restapi_id", valid_594735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Content-Sha256", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Algorithm")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Algorithm", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Signature")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Signature", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-SignedHeaders", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Credential")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Credential", valid_594742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594743: Call_DeleteDeployment_594731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_594743.validator(path, query, header, formData, body)
  let scheme = call_594743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594743.url(scheme.get, call_594743.host, call_594743.base,
                         call_594743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594743, url, valid)

proc call*(call_594744: Call_DeleteDeployment_594731; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594745 = newJObject()
  add(path_594745, "deployment_id", newJString(deploymentId))
  add(path_594745, "restapi_id", newJString(restapiId))
  result = call_594744.call(path_594745, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_594731(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_594732, base: "/",
    url: url_DeleteDeployment_594733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_594763 = ref object of OpenApiRestCall_593421
proc url_GetDocumentationPart_594765(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentationPart_594764(path: JsonNode; query: JsonNode;
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
  var valid_594766 = path.getOrDefault("part_id")
  valid_594766 = validateParameter(valid_594766, JString, required = true,
                                 default = nil)
  if valid_594766 != nil:
    section.add "part_id", valid_594766
  var valid_594767 = path.getOrDefault("restapi_id")
  valid_594767 = validateParameter(valid_594767, JString, required = true,
                                 default = nil)
  if valid_594767 != nil:
    section.add "restapi_id", valid_594767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594768 = header.getOrDefault("X-Amz-Date")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Date", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Security-Token")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Security-Token", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Content-Sha256", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Algorithm")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Algorithm", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-Signature")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Signature", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-SignedHeaders", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Credential")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Credential", valid_594774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594775: Call_GetDocumentationPart_594763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594775.validator(path, query, header, formData, body)
  let scheme = call_594775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594775.url(scheme.get, call_594775.host, call_594775.base,
                         call_594775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594775, url, valid)

proc call*(call_594776: Call_GetDocumentationPart_594763; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594777 = newJObject()
  add(path_594777, "part_id", newJString(partId))
  add(path_594777, "restapi_id", newJString(restapiId))
  result = call_594776.call(path_594777, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_594763(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_594764, base: "/",
    url: url_GetDocumentationPart_594765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_594793 = ref object of OpenApiRestCall_593421
proc url_UpdateDocumentationPart_594795(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDocumentationPart_594794(path: JsonNode; query: JsonNode;
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
  var valid_594796 = path.getOrDefault("part_id")
  valid_594796 = validateParameter(valid_594796, JString, required = true,
                                 default = nil)
  if valid_594796 != nil:
    section.add "part_id", valid_594796
  var valid_594797 = path.getOrDefault("restapi_id")
  valid_594797 = validateParameter(valid_594797, JString, required = true,
                                 default = nil)
  if valid_594797 != nil:
    section.add "restapi_id", valid_594797
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594798 = header.getOrDefault("X-Amz-Date")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Date", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Security-Token")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Security-Token", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Content-Sha256", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Algorithm")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Algorithm", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Signature")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Signature", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-SignedHeaders", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-Credential")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Credential", valid_594804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594806: Call_UpdateDocumentationPart_594793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594806.validator(path, query, header, formData, body)
  let scheme = call_594806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594806.url(scheme.get, call_594806.host, call_594806.base,
                         call_594806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594806, url, valid)

proc call*(call_594807: Call_UpdateDocumentationPart_594793; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594808 = newJObject()
  var body_594809 = newJObject()
  if body != nil:
    body_594809 = body
  add(path_594808, "part_id", newJString(partId))
  add(path_594808, "restapi_id", newJString(restapiId))
  result = call_594807.call(path_594808, nil, nil, nil, body_594809)

var updateDocumentationPart* = Call_UpdateDocumentationPart_594793(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_594794, base: "/",
    url: url_UpdateDocumentationPart_594795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_594778 = ref object of OpenApiRestCall_593421
proc url_DeleteDocumentationPart_594780(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDocumentationPart_594779(path: JsonNode; query: JsonNode;
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
  var valid_594781 = path.getOrDefault("part_id")
  valid_594781 = validateParameter(valid_594781, JString, required = true,
                                 default = nil)
  if valid_594781 != nil:
    section.add "part_id", valid_594781
  var valid_594782 = path.getOrDefault("restapi_id")
  valid_594782 = validateParameter(valid_594782, JString, required = true,
                                 default = nil)
  if valid_594782 != nil:
    section.add "restapi_id", valid_594782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594783 = header.getOrDefault("X-Amz-Date")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Date", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Security-Token")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Security-Token", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Content-Sha256", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Algorithm")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Algorithm", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-Signature")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-Signature", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-SignedHeaders", valid_594788
  var valid_594789 = header.getOrDefault("X-Amz-Credential")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Credential", valid_594789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594790: Call_DeleteDocumentationPart_594778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594790.validator(path, query, header, formData, body)
  let scheme = call_594790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594790.url(scheme.get, call_594790.host, call_594790.base,
                         call_594790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594790, url, valid)

proc call*(call_594791: Call_DeleteDocumentationPart_594778; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594792 = newJObject()
  add(path_594792, "part_id", newJString(partId))
  add(path_594792, "restapi_id", newJString(restapiId))
  result = call_594791.call(path_594792, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_594778(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_594779, base: "/",
    url: url_DeleteDocumentationPart_594780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_594810 = ref object of OpenApiRestCall_593421
proc url_GetDocumentationVersion_594812(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentationVersion_594811(path: JsonNode; query: JsonNode;
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
  var valid_594813 = path.getOrDefault("doc_version")
  valid_594813 = validateParameter(valid_594813, JString, required = true,
                                 default = nil)
  if valid_594813 != nil:
    section.add "doc_version", valid_594813
  var valid_594814 = path.getOrDefault("restapi_id")
  valid_594814 = validateParameter(valid_594814, JString, required = true,
                                 default = nil)
  if valid_594814 != nil:
    section.add "restapi_id", valid_594814
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594815 = header.getOrDefault("X-Amz-Date")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Date", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Security-Token")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Security-Token", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Content-Sha256", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Algorithm")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Algorithm", valid_594818
  var valid_594819 = header.getOrDefault("X-Amz-Signature")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Signature", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-SignedHeaders", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Credential")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Credential", valid_594821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594822: Call_GetDocumentationVersion_594810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594822.validator(path, query, header, formData, body)
  let scheme = call_594822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594822.url(scheme.get, call_594822.host, call_594822.base,
                         call_594822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594822, url, valid)

proc call*(call_594823: Call_GetDocumentationVersion_594810; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594824 = newJObject()
  add(path_594824, "doc_version", newJString(docVersion))
  add(path_594824, "restapi_id", newJString(restapiId))
  result = call_594823.call(path_594824, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_594810(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_594811, base: "/",
    url: url_GetDocumentationVersion_594812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_594840 = ref object of OpenApiRestCall_593421
proc url_UpdateDocumentationVersion_594842(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDocumentationVersion_594841(path: JsonNode; query: JsonNode;
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
  var valid_594843 = path.getOrDefault("doc_version")
  valid_594843 = validateParameter(valid_594843, JString, required = true,
                                 default = nil)
  if valid_594843 != nil:
    section.add "doc_version", valid_594843
  var valid_594844 = path.getOrDefault("restapi_id")
  valid_594844 = validateParameter(valid_594844, JString, required = true,
                                 default = nil)
  if valid_594844 != nil:
    section.add "restapi_id", valid_594844
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594845 = header.getOrDefault("X-Amz-Date")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Date", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Security-Token")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Security-Token", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Content-Sha256", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Algorithm")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Algorithm", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Signature")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Signature", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-SignedHeaders", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Credential")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Credential", valid_594851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594853: Call_UpdateDocumentationVersion_594840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594853.validator(path, query, header, formData, body)
  let scheme = call_594853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594853.url(scheme.get, call_594853.host, call_594853.base,
                         call_594853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594853, url, valid)

proc call*(call_594854: Call_UpdateDocumentationVersion_594840; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_594855 = newJObject()
  var body_594856 = newJObject()
  add(path_594855, "doc_version", newJString(docVersion))
  if body != nil:
    body_594856 = body
  add(path_594855, "restapi_id", newJString(restapiId))
  result = call_594854.call(path_594855, nil, nil, nil, body_594856)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_594840(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_594841, base: "/",
    url: url_UpdateDocumentationVersion_594842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_594825 = ref object of OpenApiRestCall_593421
proc url_DeleteDocumentationVersion_594827(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDocumentationVersion_594826(path: JsonNode; query: JsonNode;
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
  var valid_594828 = path.getOrDefault("doc_version")
  valid_594828 = validateParameter(valid_594828, JString, required = true,
                                 default = nil)
  if valid_594828 != nil:
    section.add "doc_version", valid_594828
  var valid_594829 = path.getOrDefault("restapi_id")
  valid_594829 = validateParameter(valid_594829, JString, required = true,
                                 default = nil)
  if valid_594829 != nil:
    section.add "restapi_id", valid_594829
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594830 = header.getOrDefault("X-Amz-Date")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Date", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Security-Token")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Security-Token", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Content-Sha256", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Algorithm")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Algorithm", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Signature")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Signature", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-SignedHeaders", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Credential")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Credential", valid_594836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594837: Call_DeleteDocumentationVersion_594825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594837.validator(path, query, header, formData, body)
  let scheme = call_594837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594837.url(scheme.get, call_594837.host, call_594837.base,
                         call_594837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594837, url, valid)

proc call*(call_594838: Call_DeleteDocumentationVersion_594825; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594839 = newJObject()
  add(path_594839, "doc_version", newJString(docVersion))
  add(path_594839, "restapi_id", newJString(restapiId))
  result = call_594838.call(path_594839, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_594825(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_594826, base: "/",
    url: url_DeleteDocumentationVersion_594827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_594857 = ref object of OpenApiRestCall_593421
proc url_GetDomainName_594859(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDomainName_594858(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594860 = path.getOrDefault("domain_name")
  valid_594860 = validateParameter(valid_594860, JString, required = true,
                                 default = nil)
  if valid_594860 != nil:
    section.add "domain_name", valid_594860
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594861 = header.getOrDefault("X-Amz-Date")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Date", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Security-Token")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Security-Token", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Content-Sha256", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-Algorithm")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Algorithm", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Signature")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Signature", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-SignedHeaders", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Credential")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Credential", valid_594867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594868: Call_GetDomainName_594857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_594868.validator(path, query, header, formData, body)
  let scheme = call_594868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594868.url(scheme.get, call_594868.host, call_594868.base,
                         call_594868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594868, url, valid)

proc call*(call_594869: Call_GetDomainName_594857; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_594870 = newJObject()
  add(path_594870, "domain_name", newJString(domainName))
  result = call_594869.call(path_594870, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_594857(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_594858,
    base: "/", url: url_GetDomainName_594859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_594885 = ref object of OpenApiRestCall_593421
proc url_UpdateDomainName_594887(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDomainName_594886(path: JsonNode; query: JsonNode;
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
  var valid_594888 = path.getOrDefault("domain_name")
  valid_594888 = validateParameter(valid_594888, JString, required = true,
                                 default = nil)
  if valid_594888 != nil:
    section.add "domain_name", valid_594888
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594889 = header.getOrDefault("X-Amz-Date")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Date", valid_594889
  var valid_594890 = header.getOrDefault("X-Amz-Security-Token")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Security-Token", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Content-Sha256", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Algorithm")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Algorithm", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Signature")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Signature", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-SignedHeaders", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Credential")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Credential", valid_594895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594897: Call_UpdateDomainName_594885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_594897.validator(path, query, header, formData, body)
  let scheme = call_594897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594897.url(scheme.get, call_594897.host, call_594897.base,
                         call_594897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594897, url, valid)

proc call*(call_594898: Call_UpdateDomainName_594885; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_594899 = newJObject()
  var body_594900 = newJObject()
  add(path_594899, "domain_name", newJString(domainName))
  if body != nil:
    body_594900 = body
  result = call_594898.call(path_594899, nil, nil, nil, body_594900)

var updateDomainName* = Call_UpdateDomainName_594885(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_594886,
    base: "/", url: url_UpdateDomainName_594887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_594871 = ref object of OpenApiRestCall_593421
proc url_DeleteDomainName_594873(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDomainName_594872(path: JsonNode; query: JsonNode;
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
  var valid_594874 = path.getOrDefault("domain_name")
  valid_594874 = validateParameter(valid_594874, JString, required = true,
                                 default = nil)
  if valid_594874 != nil:
    section.add "domain_name", valid_594874
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594875 = header.getOrDefault("X-Amz-Date")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Date", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Security-Token")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Security-Token", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Content-Sha256", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Algorithm")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Algorithm", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Signature")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Signature", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-SignedHeaders", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Credential")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Credential", valid_594881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594882: Call_DeleteDomainName_594871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_594882.validator(path, query, header, formData, body)
  let scheme = call_594882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594882.url(scheme.get, call_594882.host, call_594882.base,
                         call_594882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594882, url, valid)

proc call*(call_594883: Call_DeleteDomainName_594871; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_594884 = newJObject()
  add(path_594884, "domain_name", newJString(domainName))
  result = call_594883.call(path_594884, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_594871(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_594872,
    base: "/", url: url_DeleteDomainName_594873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_594916 = ref object of OpenApiRestCall_593421
proc url_PutGatewayResponse_594918(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutGatewayResponse_594917(path: JsonNode; query: JsonNode;
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
  var valid_594919 = path.getOrDefault("response_type")
  valid_594919 = validateParameter(valid_594919, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_594919 != nil:
    section.add "response_type", valid_594919
  var valid_594920 = path.getOrDefault("restapi_id")
  valid_594920 = validateParameter(valid_594920, JString, required = true,
                                 default = nil)
  if valid_594920 != nil:
    section.add "restapi_id", valid_594920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594921 = header.getOrDefault("X-Amz-Date")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Date", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Security-Token")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Security-Token", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Content-Sha256", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-Algorithm")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-Algorithm", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Signature")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Signature", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-SignedHeaders", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Credential")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Credential", valid_594927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594929: Call_PutGatewayResponse_594916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_594929.validator(path, query, header, formData, body)
  let scheme = call_594929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594929.url(scheme.get, call_594929.host, call_594929.base,
                         call_594929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594929, url, valid)

proc call*(call_594930: Call_PutGatewayResponse_594916; body: JsonNode;
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
  var path_594931 = newJObject()
  var body_594932 = newJObject()
  add(path_594931, "response_type", newJString(responseType))
  if body != nil:
    body_594932 = body
  add(path_594931, "restapi_id", newJString(restapiId))
  result = call_594930.call(path_594931, nil, nil, nil, body_594932)

var putGatewayResponse* = Call_PutGatewayResponse_594916(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_594917, base: "/",
    url: url_PutGatewayResponse_594918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_594901 = ref object of OpenApiRestCall_593421
proc url_GetGatewayResponse_594903(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetGatewayResponse_594902(path: JsonNode; query: JsonNode;
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
  var valid_594904 = path.getOrDefault("response_type")
  valid_594904 = validateParameter(valid_594904, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_594904 != nil:
    section.add "response_type", valid_594904
  var valid_594905 = path.getOrDefault("restapi_id")
  valid_594905 = validateParameter(valid_594905, JString, required = true,
                                 default = nil)
  if valid_594905 != nil:
    section.add "restapi_id", valid_594905
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594906 = header.getOrDefault("X-Amz-Date")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Date", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Security-Token")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Security-Token", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Content-Sha256", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Algorithm")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Algorithm", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Signature")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Signature", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-SignedHeaders", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Credential")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Credential", valid_594912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594913: Call_GetGatewayResponse_594901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_594913.validator(path, query, header, formData, body)
  let scheme = call_594913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594913.url(scheme.get, call_594913.host, call_594913.base,
                         call_594913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594913, url, valid)

proc call*(call_594914: Call_GetGatewayResponse_594901; restapiId: string;
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
  var path_594915 = newJObject()
  add(path_594915, "response_type", newJString(responseType))
  add(path_594915, "restapi_id", newJString(restapiId))
  result = call_594914.call(path_594915, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_594901(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_594902, base: "/",
    url: url_GetGatewayResponse_594903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_594948 = ref object of OpenApiRestCall_593421
proc url_UpdateGatewayResponse_594950(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateGatewayResponse_594949(path: JsonNode; query: JsonNode;
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
  var valid_594951 = path.getOrDefault("response_type")
  valid_594951 = validateParameter(valid_594951, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_594951 != nil:
    section.add "response_type", valid_594951
  var valid_594952 = path.getOrDefault("restapi_id")
  valid_594952 = validateParameter(valid_594952, JString, required = true,
                                 default = nil)
  if valid_594952 != nil:
    section.add "restapi_id", valid_594952
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594953 = header.getOrDefault("X-Amz-Date")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Date", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Security-Token")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Security-Token", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Content-Sha256", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Algorithm")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Algorithm", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Signature")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Signature", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-SignedHeaders", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Credential")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Credential", valid_594959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594961: Call_UpdateGatewayResponse_594948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_594961.validator(path, query, header, formData, body)
  let scheme = call_594961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594961.url(scheme.get, call_594961.host, call_594961.base,
                         call_594961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594961, url, valid)

proc call*(call_594962: Call_UpdateGatewayResponse_594948; body: JsonNode;
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
  var path_594963 = newJObject()
  var body_594964 = newJObject()
  add(path_594963, "response_type", newJString(responseType))
  if body != nil:
    body_594964 = body
  add(path_594963, "restapi_id", newJString(restapiId))
  result = call_594962.call(path_594963, nil, nil, nil, body_594964)

var updateGatewayResponse* = Call_UpdateGatewayResponse_594948(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_594949, base: "/",
    url: url_UpdateGatewayResponse_594950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_594933 = ref object of OpenApiRestCall_593421
proc url_DeleteGatewayResponse_594935(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteGatewayResponse_594934(path: JsonNode; query: JsonNode;
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
  var valid_594936 = path.getOrDefault("response_type")
  valid_594936 = validateParameter(valid_594936, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_594936 != nil:
    section.add "response_type", valid_594936
  var valid_594937 = path.getOrDefault("restapi_id")
  valid_594937 = validateParameter(valid_594937, JString, required = true,
                                 default = nil)
  if valid_594937 != nil:
    section.add "restapi_id", valid_594937
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594938 = header.getOrDefault("X-Amz-Date")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Date", valid_594938
  var valid_594939 = header.getOrDefault("X-Amz-Security-Token")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "X-Amz-Security-Token", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Content-Sha256", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Algorithm")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Algorithm", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Signature")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Signature", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-SignedHeaders", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Credential")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Credential", valid_594944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594945: Call_DeleteGatewayResponse_594933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_594945.validator(path, query, header, formData, body)
  let scheme = call_594945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594945.url(scheme.get, call_594945.host, call_594945.base,
                         call_594945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594945, url, valid)

proc call*(call_594946: Call_DeleteGatewayResponse_594933; restapiId: string;
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
  var path_594947 = newJObject()
  add(path_594947, "response_type", newJString(responseType))
  add(path_594947, "restapi_id", newJString(restapiId))
  result = call_594946.call(path_594947, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_594933(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_594934, base: "/",
    url: url_DeleteGatewayResponse_594935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_594981 = ref object of OpenApiRestCall_593421
proc url_PutIntegration_594983(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutIntegration_594982(path: JsonNode; query: JsonNode;
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
  var valid_594984 = path.getOrDefault("http_method")
  valid_594984 = validateParameter(valid_594984, JString, required = true,
                                 default = nil)
  if valid_594984 != nil:
    section.add "http_method", valid_594984
  var valid_594985 = path.getOrDefault("restapi_id")
  valid_594985 = validateParameter(valid_594985, JString, required = true,
                                 default = nil)
  if valid_594985 != nil:
    section.add "restapi_id", valid_594985
  var valid_594986 = path.getOrDefault("resource_id")
  valid_594986 = validateParameter(valid_594986, JString, required = true,
                                 default = nil)
  if valid_594986 != nil:
    section.add "resource_id", valid_594986
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594987 = header.getOrDefault("X-Amz-Date")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Date", valid_594987
  var valid_594988 = header.getOrDefault("X-Amz-Security-Token")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Security-Token", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Content-Sha256", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Algorithm")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Algorithm", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Signature")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Signature", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-SignedHeaders", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Credential")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Credential", valid_594993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594995: Call_PutIntegration_594981; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_594995.validator(path, query, header, formData, body)
  let scheme = call_594995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594995.url(scheme.get, call_594995.host, call_594995.base,
                         call_594995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594995, url, valid)

proc call*(call_594996: Call_PutIntegration_594981; httpMethod: string;
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
  var path_594997 = newJObject()
  var body_594998 = newJObject()
  add(path_594997, "http_method", newJString(httpMethod))
  if body != nil:
    body_594998 = body
  add(path_594997, "restapi_id", newJString(restapiId))
  add(path_594997, "resource_id", newJString(resourceId))
  result = call_594996.call(path_594997, nil, nil, nil, body_594998)

var putIntegration* = Call_PutIntegration_594981(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_594982, base: "/", url: url_PutIntegration_594983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_594965 = ref object of OpenApiRestCall_593421
proc url_GetIntegration_594967(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetIntegration_594966(path: JsonNode; query: JsonNode;
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
  var valid_594968 = path.getOrDefault("http_method")
  valid_594968 = validateParameter(valid_594968, JString, required = true,
                                 default = nil)
  if valid_594968 != nil:
    section.add "http_method", valid_594968
  var valid_594969 = path.getOrDefault("restapi_id")
  valid_594969 = validateParameter(valid_594969, JString, required = true,
                                 default = nil)
  if valid_594969 != nil:
    section.add "restapi_id", valid_594969
  var valid_594970 = path.getOrDefault("resource_id")
  valid_594970 = validateParameter(valid_594970, JString, required = true,
                                 default = nil)
  if valid_594970 != nil:
    section.add "resource_id", valid_594970
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594971 = header.getOrDefault("X-Amz-Date")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Date", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Security-Token")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Security-Token", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Content-Sha256", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Algorithm")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Algorithm", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Signature")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Signature", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-SignedHeaders", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Credential")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Credential", valid_594977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594978: Call_GetIntegration_594965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_594978.validator(path, query, header, formData, body)
  let scheme = call_594978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594978.url(scheme.get, call_594978.host, call_594978.base,
                         call_594978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594978, url, valid)

proc call*(call_594979: Call_GetIntegration_594965; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_594980 = newJObject()
  add(path_594980, "http_method", newJString(httpMethod))
  add(path_594980, "restapi_id", newJString(restapiId))
  add(path_594980, "resource_id", newJString(resourceId))
  result = call_594979.call(path_594980, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_594965(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_594966, base: "/", url: url_GetIntegration_594967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_595015 = ref object of OpenApiRestCall_593421
proc url_UpdateIntegration_595017(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateIntegration_595016(path: JsonNode; query: JsonNode;
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
  var valid_595018 = path.getOrDefault("http_method")
  valid_595018 = validateParameter(valid_595018, JString, required = true,
                                 default = nil)
  if valid_595018 != nil:
    section.add "http_method", valid_595018
  var valid_595019 = path.getOrDefault("restapi_id")
  valid_595019 = validateParameter(valid_595019, JString, required = true,
                                 default = nil)
  if valid_595019 != nil:
    section.add "restapi_id", valid_595019
  var valid_595020 = path.getOrDefault("resource_id")
  valid_595020 = validateParameter(valid_595020, JString, required = true,
                                 default = nil)
  if valid_595020 != nil:
    section.add "resource_id", valid_595020
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595021 = header.getOrDefault("X-Amz-Date")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Date", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Security-Token")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Security-Token", valid_595022
  var valid_595023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "X-Amz-Content-Sha256", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-Algorithm")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Algorithm", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Signature")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Signature", valid_595025
  var valid_595026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "X-Amz-SignedHeaders", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-Credential")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-Credential", valid_595027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595029: Call_UpdateIntegration_595015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_595029.validator(path, query, header, formData, body)
  let scheme = call_595029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595029.url(scheme.get, call_595029.host, call_595029.base,
                         call_595029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595029, url, valid)

proc call*(call_595030: Call_UpdateIntegration_595015; httpMethod: string;
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
  var path_595031 = newJObject()
  var body_595032 = newJObject()
  add(path_595031, "http_method", newJString(httpMethod))
  if body != nil:
    body_595032 = body
  add(path_595031, "restapi_id", newJString(restapiId))
  add(path_595031, "resource_id", newJString(resourceId))
  result = call_595030.call(path_595031, nil, nil, nil, body_595032)

var updateIntegration* = Call_UpdateIntegration_595015(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_595016, base: "/",
    url: url_UpdateIntegration_595017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_594999 = ref object of OpenApiRestCall_593421
proc url_DeleteIntegration_595001(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteIntegration_595000(path: JsonNode; query: JsonNode;
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
  var valid_595002 = path.getOrDefault("http_method")
  valid_595002 = validateParameter(valid_595002, JString, required = true,
                                 default = nil)
  if valid_595002 != nil:
    section.add "http_method", valid_595002
  var valid_595003 = path.getOrDefault("restapi_id")
  valid_595003 = validateParameter(valid_595003, JString, required = true,
                                 default = nil)
  if valid_595003 != nil:
    section.add "restapi_id", valid_595003
  var valid_595004 = path.getOrDefault("resource_id")
  valid_595004 = validateParameter(valid_595004, JString, required = true,
                                 default = nil)
  if valid_595004 != nil:
    section.add "resource_id", valid_595004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595005 = header.getOrDefault("X-Amz-Date")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Date", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Security-Token")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Security-Token", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Content-Sha256", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Algorithm")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Algorithm", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Signature")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Signature", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-SignedHeaders", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Credential")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Credential", valid_595011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595012: Call_DeleteIntegration_594999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_595012.validator(path, query, header, formData, body)
  let scheme = call_595012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595012.url(scheme.get, call_595012.host, call_595012.base,
                         call_595012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595012, url, valid)

proc call*(call_595013: Call_DeleteIntegration_594999; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_595014 = newJObject()
  add(path_595014, "http_method", newJString(httpMethod))
  add(path_595014, "restapi_id", newJString(restapiId))
  add(path_595014, "resource_id", newJString(resourceId))
  result = call_595013.call(path_595014, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_594999(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_595000, base: "/",
    url: url_DeleteIntegration_595001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_595050 = ref object of OpenApiRestCall_593421
proc url_PutIntegrationResponse_595052(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutIntegrationResponse_595051(path: JsonNode; query: JsonNode;
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
  var valid_595053 = path.getOrDefault("http_method")
  valid_595053 = validateParameter(valid_595053, JString, required = true,
                                 default = nil)
  if valid_595053 != nil:
    section.add "http_method", valid_595053
  var valid_595054 = path.getOrDefault("status_code")
  valid_595054 = validateParameter(valid_595054, JString, required = true,
                                 default = nil)
  if valid_595054 != nil:
    section.add "status_code", valid_595054
  var valid_595055 = path.getOrDefault("restapi_id")
  valid_595055 = validateParameter(valid_595055, JString, required = true,
                                 default = nil)
  if valid_595055 != nil:
    section.add "restapi_id", valid_595055
  var valid_595056 = path.getOrDefault("resource_id")
  valid_595056 = validateParameter(valid_595056, JString, required = true,
                                 default = nil)
  if valid_595056 != nil:
    section.add "resource_id", valid_595056
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595057 = header.getOrDefault("X-Amz-Date")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "X-Amz-Date", valid_595057
  var valid_595058 = header.getOrDefault("X-Amz-Security-Token")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "X-Amz-Security-Token", valid_595058
  var valid_595059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "X-Amz-Content-Sha256", valid_595059
  var valid_595060 = header.getOrDefault("X-Amz-Algorithm")
  valid_595060 = validateParameter(valid_595060, JString, required = false,
                                 default = nil)
  if valid_595060 != nil:
    section.add "X-Amz-Algorithm", valid_595060
  var valid_595061 = header.getOrDefault("X-Amz-Signature")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Signature", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-SignedHeaders", valid_595062
  var valid_595063 = header.getOrDefault("X-Amz-Credential")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Credential", valid_595063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595065: Call_PutIntegrationResponse_595050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_595065.validator(path, query, header, formData, body)
  let scheme = call_595065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595065.url(scheme.get, call_595065.host, call_595065.base,
                         call_595065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595065, url, valid)

proc call*(call_595066: Call_PutIntegrationResponse_595050; httpMethod: string;
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
  var path_595067 = newJObject()
  var body_595068 = newJObject()
  add(path_595067, "http_method", newJString(httpMethod))
  add(path_595067, "status_code", newJString(statusCode))
  if body != nil:
    body_595068 = body
  add(path_595067, "restapi_id", newJString(restapiId))
  add(path_595067, "resource_id", newJString(resourceId))
  result = call_595066.call(path_595067, nil, nil, nil, body_595068)

var putIntegrationResponse* = Call_PutIntegrationResponse_595050(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_595051, base: "/",
    url: url_PutIntegrationResponse_595052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_595033 = ref object of OpenApiRestCall_593421
proc url_GetIntegrationResponse_595035(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetIntegrationResponse_595034(path: JsonNode; query: JsonNode;
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
  var valid_595036 = path.getOrDefault("http_method")
  valid_595036 = validateParameter(valid_595036, JString, required = true,
                                 default = nil)
  if valid_595036 != nil:
    section.add "http_method", valid_595036
  var valid_595037 = path.getOrDefault("status_code")
  valid_595037 = validateParameter(valid_595037, JString, required = true,
                                 default = nil)
  if valid_595037 != nil:
    section.add "status_code", valid_595037
  var valid_595038 = path.getOrDefault("restapi_id")
  valid_595038 = validateParameter(valid_595038, JString, required = true,
                                 default = nil)
  if valid_595038 != nil:
    section.add "restapi_id", valid_595038
  var valid_595039 = path.getOrDefault("resource_id")
  valid_595039 = validateParameter(valid_595039, JString, required = true,
                                 default = nil)
  if valid_595039 != nil:
    section.add "resource_id", valid_595039
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595040 = header.getOrDefault("X-Amz-Date")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-Date", valid_595040
  var valid_595041 = header.getOrDefault("X-Amz-Security-Token")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "X-Amz-Security-Token", valid_595041
  var valid_595042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "X-Amz-Content-Sha256", valid_595042
  var valid_595043 = header.getOrDefault("X-Amz-Algorithm")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-Algorithm", valid_595043
  var valid_595044 = header.getOrDefault("X-Amz-Signature")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Signature", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-SignedHeaders", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Credential")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Credential", valid_595046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595047: Call_GetIntegrationResponse_595033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_595047.validator(path, query, header, formData, body)
  let scheme = call_595047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595047.url(scheme.get, call_595047.host, call_595047.base,
                         call_595047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595047, url, valid)

proc call*(call_595048: Call_GetIntegrationResponse_595033; httpMethod: string;
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
  var path_595049 = newJObject()
  add(path_595049, "http_method", newJString(httpMethod))
  add(path_595049, "status_code", newJString(statusCode))
  add(path_595049, "restapi_id", newJString(restapiId))
  add(path_595049, "resource_id", newJString(resourceId))
  result = call_595048.call(path_595049, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_595033(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_595034, base: "/",
    url: url_GetIntegrationResponse_595035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_595086 = ref object of OpenApiRestCall_593421
proc url_UpdateIntegrationResponse_595088(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_595087(path: JsonNode; query: JsonNode;
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
  var valid_595089 = path.getOrDefault("http_method")
  valid_595089 = validateParameter(valid_595089, JString, required = true,
                                 default = nil)
  if valid_595089 != nil:
    section.add "http_method", valid_595089
  var valid_595090 = path.getOrDefault("status_code")
  valid_595090 = validateParameter(valid_595090, JString, required = true,
                                 default = nil)
  if valid_595090 != nil:
    section.add "status_code", valid_595090
  var valid_595091 = path.getOrDefault("restapi_id")
  valid_595091 = validateParameter(valid_595091, JString, required = true,
                                 default = nil)
  if valid_595091 != nil:
    section.add "restapi_id", valid_595091
  var valid_595092 = path.getOrDefault("resource_id")
  valid_595092 = validateParameter(valid_595092, JString, required = true,
                                 default = nil)
  if valid_595092 != nil:
    section.add "resource_id", valid_595092
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595093 = header.getOrDefault("X-Amz-Date")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "X-Amz-Date", valid_595093
  var valid_595094 = header.getOrDefault("X-Amz-Security-Token")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-Security-Token", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Content-Sha256", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Algorithm")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Algorithm", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Signature")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Signature", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-SignedHeaders", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Credential")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Credential", valid_595099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595101: Call_UpdateIntegrationResponse_595086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_595101.validator(path, query, header, formData, body)
  let scheme = call_595101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595101.url(scheme.get, call_595101.host, call_595101.base,
                         call_595101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595101, url, valid)

proc call*(call_595102: Call_UpdateIntegrationResponse_595086; httpMethod: string;
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
  var path_595103 = newJObject()
  var body_595104 = newJObject()
  add(path_595103, "http_method", newJString(httpMethod))
  add(path_595103, "status_code", newJString(statusCode))
  if body != nil:
    body_595104 = body
  add(path_595103, "restapi_id", newJString(restapiId))
  add(path_595103, "resource_id", newJString(resourceId))
  result = call_595102.call(path_595103, nil, nil, nil, body_595104)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_595086(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_595087, base: "/",
    url: url_UpdateIntegrationResponse_595088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_595069 = ref object of OpenApiRestCall_593421
proc url_DeleteIntegrationResponse_595071(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_595070(path: JsonNode; query: JsonNode;
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
  var valid_595072 = path.getOrDefault("http_method")
  valid_595072 = validateParameter(valid_595072, JString, required = true,
                                 default = nil)
  if valid_595072 != nil:
    section.add "http_method", valid_595072
  var valid_595073 = path.getOrDefault("status_code")
  valid_595073 = validateParameter(valid_595073, JString, required = true,
                                 default = nil)
  if valid_595073 != nil:
    section.add "status_code", valid_595073
  var valid_595074 = path.getOrDefault("restapi_id")
  valid_595074 = validateParameter(valid_595074, JString, required = true,
                                 default = nil)
  if valid_595074 != nil:
    section.add "restapi_id", valid_595074
  var valid_595075 = path.getOrDefault("resource_id")
  valid_595075 = validateParameter(valid_595075, JString, required = true,
                                 default = nil)
  if valid_595075 != nil:
    section.add "resource_id", valid_595075
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595076 = header.getOrDefault("X-Amz-Date")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Date", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-Security-Token")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-Security-Token", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Content-Sha256", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-Algorithm")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Algorithm", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Signature")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Signature", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-SignedHeaders", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Credential")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Credential", valid_595082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595083: Call_DeleteIntegrationResponse_595069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_595083.validator(path, query, header, formData, body)
  let scheme = call_595083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595083.url(scheme.get, call_595083.host, call_595083.base,
                         call_595083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595083, url, valid)

proc call*(call_595084: Call_DeleteIntegrationResponse_595069; httpMethod: string;
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
  var path_595085 = newJObject()
  add(path_595085, "http_method", newJString(httpMethod))
  add(path_595085, "status_code", newJString(statusCode))
  add(path_595085, "restapi_id", newJString(restapiId))
  add(path_595085, "resource_id", newJString(resourceId))
  result = call_595084.call(path_595085, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_595069(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_595070, base: "/",
    url: url_DeleteIntegrationResponse_595071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_595121 = ref object of OpenApiRestCall_593421
proc url_PutMethod_595123(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_PutMethod_595122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595124 = path.getOrDefault("http_method")
  valid_595124 = validateParameter(valid_595124, JString, required = true,
                                 default = nil)
  if valid_595124 != nil:
    section.add "http_method", valid_595124
  var valid_595125 = path.getOrDefault("restapi_id")
  valid_595125 = validateParameter(valid_595125, JString, required = true,
                                 default = nil)
  if valid_595125 != nil:
    section.add "restapi_id", valid_595125
  var valid_595126 = path.getOrDefault("resource_id")
  valid_595126 = validateParameter(valid_595126, JString, required = true,
                                 default = nil)
  if valid_595126 != nil:
    section.add "resource_id", valid_595126
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595127 = header.getOrDefault("X-Amz-Date")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Date", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Security-Token")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Security-Token", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-Content-Sha256", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Algorithm")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Algorithm", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Signature")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Signature", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-SignedHeaders", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Credential")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Credential", valid_595133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595135: Call_PutMethod_595121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_595135.validator(path, query, header, formData, body)
  let scheme = call_595135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595135.url(scheme.get, call_595135.host, call_595135.base,
                         call_595135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595135, url, valid)

proc call*(call_595136: Call_PutMethod_595121; httpMethod: string; body: JsonNode;
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
  var path_595137 = newJObject()
  var body_595138 = newJObject()
  add(path_595137, "http_method", newJString(httpMethod))
  if body != nil:
    body_595138 = body
  add(path_595137, "restapi_id", newJString(restapiId))
  add(path_595137, "resource_id", newJString(resourceId))
  result = call_595136.call(path_595137, nil, nil, nil, body_595138)

var putMethod* = Call_PutMethod_595121(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_595122,
                                    base: "/", url: url_PutMethod_595123,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_595139 = ref object of OpenApiRestCall_593421
proc url_TestInvokeMethod_595141(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TestInvokeMethod_595140(path: JsonNode; query: JsonNode;
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
  var valid_595142 = path.getOrDefault("http_method")
  valid_595142 = validateParameter(valid_595142, JString, required = true,
                                 default = nil)
  if valid_595142 != nil:
    section.add "http_method", valid_595142
  var valid_595143 = path.getOrDefault("restapi_id")
  valid_595143 = validateParameter(valid_595143, JString, required = true,
                                 default = nil)
  if valid_595143 != nil:
    section.add "restapi_id", valid_595143
  var valid_595144 = path.getOrDefault("resource_id")
  valid_595144 = validateParameter(valid_595144, JString, required = true,
                                 default = nil)
  if valid_595144 != nil:
    section.add "resource_id", valid_595144
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595145 = header.getOrDefault("X-Amz-Date")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Date", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Security-Token")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Security-Token", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-Content-Sha256", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Algorithm")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Algorithm", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-Signature")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Signature", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-SignedHeaders", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-Credential")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-Credential", valid_595151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595153: Call_TestInvokeMethod_595139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_595153.validator(path, query, header, formData, body)
  let scheme = call_595153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595153.url(scheme.get, call_595153.host, call_595153.base,
                         call_595153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595153, url, valid)

proc call*(call_595154: Call_TestInvokeMethod_595139; httpMethod: string;
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
  var path_595155 = newJObject()
  var body_595156 = newJObject()
  add(path_595155, "http_method", newJString(httpMethod))
  if body != nil:
    body_595156 = body
  add(path_595155, "restapi_id", newJString(restapiId))
  add(path_595155, "resource_id", newJString(resourceId))
  result = call_595154.call(path_595155, nil, nil, nil, body_595156)

var testInvokeMethod* = Call_TestInvokeMethod_595139(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_595140, base: "/",
    url: url_TestInvokeMethod_595141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_595105 = ref object of OpenApiRestCall_593421
proc url_GetMethod_595107(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetMethod_595106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595108 = path.getOrDefault("http_method")
  valid_595108 = validateParameter(valid_595108, JString, required = true,
                                 default = nil)
  if valid_595108 != nil:
    section.add "http_method", valid_595108
  var valid_595109 = path.getOrDefault("restapi_id")
  valid_595109 = validateParameter(valid_595109, JString, required = true,
                                 default = nil)
  if valid_595109 != nil:
    section.add "restapi_id", valid_595109
  var valid_595110 = path.getOrDefault("resource_id")
  valid_595110 = validateParameter(valid_595110, JString, required = true,
                                 default = nil)
  if valid_595110 != nil:
    section.add "resource_id", valid_595110
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595111 = header.getOrDefault("X-Amz-Date")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Date", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Security-Token")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Security-Token", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Content-Sha256", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Algorithm")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Algorithm", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Signature")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Signature", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-SignedHeaders", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-Credential")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Credential", valid_595117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595118: Call_GetMethod_595105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_595118.validator(path, query, header, formData, body)
  let scheme = call_595118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595118.url(scheme.get, call_595118.host, call_595118.base,
                         call_595118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595118, url, valid)

proc call*(call_595119: Call_GetMethod_595105; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_595120 = newJObject()
  add(path_595120, "http_method", newJString(httpMethod))
  add(path_595120, "restapi_id", newJString(restapiId))
  add(path_595120, "resource_id", newJString(resourceId))
  result = call_595119.call(path_595120, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_595105(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_595106,
                                    base: "/", url: url_GetMethod_595107,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_595173 = ref object of OpenApiRestCall_593421
proc url_UpdateMethod_595175(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateMethod_595174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595176 = path.getOrDefault("http_method")
  valid_595176 = validateParameter(valid_595176, JString, required = true,
                                 default = nil)
  if valid_595176 != nil:
    section.add "http_method", valid_595176
  var valid_595177 = path.getOrDefault("restapi_id")
  valid_595177 = validateParameter(valid_595177, JString, required = true,
                                 default = nil)
  if valid_595177 != nil:
    section.add "restapi_id", valid_595177
  var valid_595178 = path.getOrDefault("resource_id")
  valid_595178 = validateParameter(valid_595178, JString, required = true,
                                 default = nil)
  if valid_595178 != nil:
    section.add "resource_id", valid_595178
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595179 = header.getOrDefault("X-Amz-Date")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "X-Amz-Date", valid_595179
  var valid_595180 = header.getOrDefault("X-Amz-Security-Token")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "X-Amz-Security-Token", valid_595180
  var valid_595181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "X-Amz-Content-Sha256", valid_595181
  var valid_595182 = header.getOrDefault("X-Amz-Algorithm")
  valid_595182 = validateParameter(valid_595182, JString, required = false,
                                 default = nil)
  if valid_595182 != nil:
    section.add "X-Amz-Algorithm", valid_595182
  var valid_595183 = header.getOrDefault("X-Amz-Signature")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Signature", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-SignedHeaders", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Credential")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Credential", valid_595185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595187: Call_UpdateMethod_595173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_595187.validator(path, query, header, formData, body)
  let scheme = call_595187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595187.url(scheme.get, call_595187.host, call_595187.base,
                         call_595187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595187, url, valid)

proc call*(call_595188: Call_UpdateMethod_595173; httpMethod: string; body: JsonNode;
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
  var path_595189 = newJObject()
  var body_595190 = newJObject()
  add(path_595189, "http_method", newJString(httpMethod))
  if body != nil:
    body_595190 = body
  add(path_595189, "restapi_id", newJString(restapiId))
  add(path_595189, "resource_id", newJString(resourceId))
  result = call_595188.call(path_595189, nil, nil, nil, body_595190)

var updateMethod* = Call_UpdateMethod_595173(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_595174, base: "/", url: url_UpdateMethod_595175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_595157 = ref object of OpenApiRestCall_593421
proc url_DeleteMethod_595159(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteMethod_595158(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595160 = path.getOrDefault("http_method")
  valid_595160 = validateParameter(valid_595160, JString, required = true,
                                 default = nil)
  if valid_595160 != nil:
    section.add "http_method", valid_595160
  var valid_595161 = path.getOrDefault("restapi_id")
  valid_595161 = validateParameter(valid_595161, JString, required = true,
                                 default = nil)
  if valid_595161 != nil:
    section.add "restapi_id", valid_595161
  var valid_595162 = path.getOrDefault("resource_id")
  valid_595162 = validateParameter(valid_595162, JString, required = true,
                                 default = nil)
  if valid_595162 != nil:
    section.add "resource_id", valid_595162
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595163 = header.getOrDefault("X-Amz-Date")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Date", valid_595163
  var valid_595164 = header.getOrDefault("X-Amz-Security-Token")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "X-Amz-Security-Token", valid_595164
  var valid_595165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "X-Amz-Content-Sha256", valid_595165
  var valid_595166 = header.getOrDefault("X-Amz-Algorithm")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "X-Amz-Algorithm", valid_595166
  var valid_595167 = header.getOrDefault("X-Amz-Signature")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "X-Amz-Signature", valid_595167
  var valid_595168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-SignedHeaders", valid_595168
  var valid_595169 = header.getOrDefault("X-Amz-Credential")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "X-Amz-Credential", valid_595169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595170: Call_DeleteMethod_595157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_595170.validator(path, query, header, formData, body)
  let scheme = call_595170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595170.url(scheme.get, call_595170.host, call_595170.base,
                         call_595170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595170, url, valid)

proc call*(call_595171: Call_DeleteMethod_595157; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_595172 = newJObject()
  add(path_595172, "http_method", newJString(httpMethod))
  add(path_595172, "restapi_id", newJString(restapiId))
  add(path_595172, "resource_id", newJString(resourceId))
  result = call_595171.call(path_595172, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_595157(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_595158, base: "/", url: url_DeleteMethod_595159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_595208 = ref object of OpenApiRestCall_593421
proc url_PutMethodResponse_595210(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PutMethodResponse_595209(path: JsonNode; query: JsonNode;
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
  var valid_595211 = path.getOrDefault("http_method")
  valid_595211 = validateParameter(valid_595211, JString, required = true,
                                 default = nil)
  if valid_595211 != nil:
    section.add "http_method", valid_595211
  var valid_595212 = path.getOrDefault("status_code")
  valid_595212 = validateParameter(valid_595212, JString, required = true,
                                 default = nil)
  if valid_595212 != nil:
    section.add "status_code", valid_595212
  var valid_595213 = path.getOrDefault("restapi_id")
  valid_595213 = validateParameter(valid_595213, JString, required = true,
                                 default = nil)
  if valid_595213 != nil:
    section.add "restapi_id", valid_595213
  var valid_595214 = path.getOrDefault("resource_id")
  valid_595214 = validateParameter(valid_595214, JString, required = true,
                                 default = nil)
  if valid_595214 != nil:
    section.add "resource_id", valid_595214
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595215 = header.getOrDefault("X-Amz-Date")
  valid_595215 = validateParameter(valid_595215, JString, required = false,
                                 default = nil)
  if valid_595215 != nil:
    section.add "X-Amz-Date", valid_595215
  var valid_595216 = header.getOrDefault("X-Amz-Security-Token")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "X-Amz-Security-Token", valid_595216
  var valid_595217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Content-Sha256", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Algorithm")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Algorithm", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Signature")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Signature", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-SignedHeaders", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Credential")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Credential", valid_595221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595223: Call_PutMethodResponse_595208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_595223.validator(path, query, header, formData, body)
  let scheme = call_595223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595223.url(scheme.get, call_595223.host, call_595223.base,
                         call_595223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595223, url, valid)

proc call*(call_595224: Call_PutMethodResponse_595208; httpMethod: string;
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
  var path_595225 = newJObject()
  var body_595226 = newJObject()
  add(path_595225, "http_method", newJString(httpMethod))
  add(path_595225, "status_code", newJString(statusCode))
  if body != nil:
    body_595226 = body
  add(path_595225, "restapi_id", newJString(restapiId))
  add(path_595225, "resource_id", newJString(resourceId))
  result = call_595224.call(path_595225, nil, nil, nil, body_595226)

var putMethodResponse* = Call_PutMethodResponse_595208(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_595209, base: "/",
    url: url_PutMethodResponse_595210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_595191 = ref object of OpenApiRestCall_593421
proc url_GetMethodResponse_595193(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetMethodResponse_595192(path: JsonNode; query: JsonNode;
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
  var valid_595194 = path.getOrDefault("http_method")
  valid_595194 = validateParameter(valid_595194, JString, required = true,
                                 default = nil)
  if valid_595194 != nil:
    section.add "http_method", valid_595194
  var valid_595195 = path.getOrDefault("status_code")
  valid_595195 = validateParameter(valid_595195, JString, required = true,
                                 default = nil)
  if valid_595195 != nil:
    section.add "status_code", valid_595195
  var valid_595196 = path.getOrDefault("restapi_id")
  valid_595196 = validateParameter(valid_595196, JString, required = true,
                                 default = nil)
  if valid_595196 != nil:
    section.add "restapi_id", valid_595196
  var valid_595197 = path.getOrDefault("resource_id")
  valid_595197 = validateParameter(valid_595197, JString, required = true,
                                 default = nil)
  if valid_595197 != nil:
    section.add "resource_id", valid_595197
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595198 = header.getOrDefault("X-Amz-Date")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Date", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Security-Token")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Security-Token", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-Content-Sha256", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Algorithm")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Algorithm", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Signature")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Signature", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-SignedHeaders", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Credential")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Credential", valid_595204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595205: Call_GetMethodResponse_595191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_595205.validator(path, query, header, formData, body)
  let scheme = call_595205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595205.url(scheme.get, call_595205.host, call_595205.base,
                         call_595205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595205, url, valid)

proc call*(call_595206: Call_GetMethodResponse_595191; httpMethod: string;
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
  var path_595207 = newJObject()
  add(path_595207, "http_method", newJString(httpMethod))
  add(path_595207, "status_code", newJString(statusCode))
  add(path_595207, "restapi_id", newJString(restapiId))
  add(path_595207, "resource_id", newJString(resourceId))
  result = call_595206.call(path_595207, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_595191(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_595192, base: "/",
    url: url_GetMethodResponse_595193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_595244 = ref object of OpenApiRestCall_593421
proc url_UpdateMethodResponse_595246(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateMethodResponse_595245(path: JsonNode; query: JsonNode;
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
  var valid_595247 = path.getOrDefault("http_method")
  valid_595247 = validateParameter(valid_595247, JString, required = true,
                                 default = nil)
  if valid_595247 != nil:
    section.add "http_method", valid_595247
  var valid_595248 = path.getOrDefault("status_code")
  valid_595248 = validateParameter(valid_595248, JString, required = true,
                                 default = nil)
  if valid_595248 != nil:
    section.add "status_code", valid_595248
  var valid_595249 = path.getOrDefault("restapi_id")
  valid_595249 = validateParameter(valid_595249, JString, required = true,
                                 default = nil)
  if valid_595249 != nil:
    section.add "restapi_id", valid_595249
  var valid_595250 = path.getOrDefault("resource_id")
  valid_595250 = validateParameter(valid_595250, JString, required = true,
                                 default = nil)
  if valid_595250 != nil:
    section.add "resource_id", valid_595250
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595251 = header.getOrDefault("X-Amz-Date")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Date", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Security-Token")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Security-Token", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Content-Sha256", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Algorithm")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Algorithm", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Signature")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Signature", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-SignedHeaders", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Credential")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Credential", valid_595257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595259: Call_UpdateMethodResponse_595244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_595259.validator(path, query, header, formData, body)
  let scheme = call_595259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595259.url(scheme.get, call_595259.host, call_595259.base,
                         call_595259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595259, url, valid)

proc call*(call_595260: Call_UpdateMethodResponse_595244; httpMethod: string;
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
  var path_595261 = newJObject()
  var body_595262 = newJObject()
  add(path_595261, "http_method", newJString(httpMethod))
  add(path_595261, "status_code", newJString(statusCode))
  if body != nil:
    body_595262 = body
  add(path_595261, "restapi_id", newJString(restapiId))
  add(path_595261, "resource_id", newJString(resourceId))
  result = call_595260.call(path_595261, nil, nil, nil, body_595262)

var updateMethodResponse* = Call_UpdateMethodResponse_595244(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_595245, base: "/",
    url: url_UpdateMethodResponse_595246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_595227 = ref object of OpenApiRestCall_593421
proc url_DeleteMethodResponse_595229(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteMethodResponse_595228(path: JsonNode; query: JsonNode;
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
  var valid_595230 = path.getOrDefault("http_method")
  valid_595230 = validateParameter(valid_595230, JString, required = true,
                                 default = nil)
  if valid_595230 != nil:
    section.add "http_method", valid_595230
  var valid_595231 = path.getOrDefault("status_code")
  valid_595231 = validateParameter(valid_595231, JString, required = true,
                                 default = nil)
  if valid_595231 != nil:
    section.add "status_code", valid_595231
  var valid_595232 = path.getOrDefault("restapi_id")
  valid_595232 = validateParameter(valid_595232, JString, required = true,
                                 default = nil)
  if valid_595232 != nil:
    section.add "restapi_id", valid_595232
  var valid_595233 = path.getOrDefault("resource_id")
  valid_595233 = validateParameter(valid_595233, JString, required = true,
                                 default = nil)
  if valid_595233 != nil:
    section.add "resource_id", valid_595233
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595234 = header.getOrDefault("X-Amz-Date")
  valid_595234 = validateParameter(valid_595234, JString, required = false,
                                 default = nil)
  if valid_595234 != nil:
    section.add "X-Amz-Date", valid_595234
  var valid_595235 = header.getOrDefault("X-Amz-Security-Token")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-Security-Token", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Content-Sha256", valid_595236
  var valid_595237 = header.getOrDefault("X-Amz-Algorithm")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "X-Amz-Algorithm", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-Signature")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Signature", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-SignedHeaders", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Credential")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Credential", valid_595240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595241: Call_DeleteMethodResponse_595227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_595241.validator(path, query, header, formData, body)
  let scheme = call_595241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595241.url(scheme.get, call_595241.host, call_595241.base,
                         call_595241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595241, url, valid)

proc call*(call_595242: Call_DeleteMethodResponse_595227; httpMethod: string;
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
  var path_595243 = newJObject()
  add(path_595243, "http_method", newJString(httpMethod))
  add(path_595243, "status_code", newJString(statusCode))
  add(path_595243, "restapi_id", newJString(restapiId))
  add(path_595243, "resource_id", newJString(resourceId))
  result = call_595242.call(path_595243, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_595227(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_595228, base: "/",
    url: url_DeleteMethodResponse_595229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_595263 = ref object of OpenApiRestCall_593421
proc url_GetModel_595265(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetModel_595264(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595266 = path.getOrDefault("model_name")
  valid_595266 = validateParameter(valid_595266, JString, required = true,
                                 default = nil)
  if valid_595266 != nil:
    section.add "model_name", valid_595266
  var valid_595267 = path.getOrDefault("restapi_id")
  valid_595267 = validateParameter(valid_595267, JString, required = true,
                                 default = nil)
  if valid_595267 != nil:
    section.add "restapi_id", valid_595267
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_595268 = query.getOrDefault("flatten")
  valid_595268 = validateParameter(valid_595268, JBool, required = false, default = nil)
  if valid_595268 != nil:
    section.add "flatten", valid_595268
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595269 = header.getOrDefault("X-Amz-Date")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Date", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Security-Token")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Security-Token", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Content-Sha256", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Algorithm")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Algorithm", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Signature")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Signature", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-SignedHeaders", valid_595274
  var valid_595275 = header.getOrDefault("X-Amz-Credential")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Credential", valid_595275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595276: Call_GetModel_595263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_595276.validator(path, query, header, formData, body)
  let scheme = call_595276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595276.url(scheme.get, call_595276.host, call_595276.base,
                         call_595276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595276, url, valid)

proc call*(call_595277: Call_GetModel_595263; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_595278 = newJObject()
  var query_595279 = newJObject()
  add(query_595279, "flatten", newJBool(flatten))
  add(path_595278, "model_name", newJString(modelName))
  add(path_595278, "restapi_id", newJString(restapiId))
  result = call_595277.call(path_595278, query_595279, nil, nil, nil)

var getModel* = Call_GetModel_595263(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_595264, base: "/",
                                  url: url_GetModel_595265,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_595295 = ref object of OpenApiRestCall_593421
proc url_UpdateModel_595297(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateModel_595296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595298 = path.getOrDefault("model_name")
  valid_595298 = validateParameter(valid_595298, JString, required = true,
                                 default = nil)
  if valid_595298 != nil:
    section.add "model_name", valid_595298
  var valid_595299 = path.getOrDefault("restapi_id")
  valid_595299 = validateParameter(valid_595299, JString, required = true,
                                 default = nil)
  if valid_595299 != nil:
    section.add "restapi_id", valid_595299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595300 = header.getOrDefault("X-Amz-Date")
  valid_595300 = validateParameter(valid_595300, JString, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "X-Amz-Date", valid_595300
  var valid_595301 = header.getOrDefault("X-Amz-Security-Token")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "X-Amz-Security-Token", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Content-Sha256", valid_595302
  var valid_595303 = header.getOrDefault("X-Amz-Algorithm")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "X-Amz-Algorithm", valid_595303
  var valid_595304 = header.getOrDefault("X-Amz-Signature")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "X-Amz-Signature", valid_595304
  var valid_595305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "X-Amz-SignedHeaders", valid_595305
  var valid_595306 = header.getOrDefault("X-Amz-Credential")
  valid_595306 = validateParameter(valid_595306, JString, required = false,
                                 default = nil)
  if valid_595306 != nil:
    section.add "X-Amz-Credential", valid_595306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595308: Call_UpdateModel_595295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_595308.validator(path, query, header, formData, body)
  let scheme = call_595308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595308.url(scheme.get, call_595308.host, call_595308.base,
                         call_595308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595308, url, valid)

proc call*(call_595309: Call_UpdateModel_595295; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595310 = newJObject()
  var body_595311 = newJObject()
  add(path_595310, "model_name", newJString(modelName))
  if body != nil:
    body_595311 = body
  add(path_595310, "restapi_id", newJString(restapiId))
  result = call_595309.call(path_595310, nil, nil, nil, body_595311)

var updateModel* = Call_UpdateModel_595295(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_595296,
                                        base: "/", url: url_UpdateModel_595297,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_595280 = ref object of OpenApiRestCall_593421
proc url_DeleteModel_595282(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteModel_595281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595283 = path.getOrDefault("model_name")
  valid_595283 = validateParameter(valid_595283, JString, required = true,
                                 default = nil)
  if valid_595283 != nil:
    section.add "model_name", valid_595283
  var valid_595284 = path.getOrDefault("restapi_id")
  valid_595284 = validateParameter(valid_595284, JString, required = true,
                                 default = nil)
  if valid_595284 != nil:
    section.add "restapi_id", valid_595284
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595285 = header.getOrDefault("X-Amz-Date")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Date", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Security-Token")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Security-Token", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Content-Sha256", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Algorithm")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Algorithm", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Signature")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Signature", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-SignedHeaders", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-Credential")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-Credential", valid_595291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595292: Call_DeleteModel_595280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_595292.validator(path, query, header, formData, body)
  let scheme = call_595292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595292.url(scheme.get, call_595292.host, call_595292.base,
                         call_595292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595292, url, valid)

proc call*(call_595293: Call_DeleteModel_595280; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595294 = newJObject()
  add(path_595294, "model_name", newJString(modelName))
  add(path_595294, "restapi_id", newJString(restapiId))
  result = call_595293.call(path_595294, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_595280(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_595281,
                                        base: "/", url: url_DeleteModel_595282,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_595312 = ref object of OpenApiRestCall_593421
proc url_GetRequestValidator_595314(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetRequestValidator_595313(path: JsonNode; query: JsonNode;
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
  var valid_595315 = path.getOrDefault("requestvalidator_id")
  valid_595315 = validateParameter(valid_595315, JString, required = true,
                                 default = nil)
  if valid_595315 != nil:
    section.add "requestvalidator_id", valid_595315
  var valid_595316 = path.getOrDefault("restapi_id")
  valid_595316 = validateParameter(valid_595316, JString, required = true,
                                 default = nil)
  if valid_595316 != nil:
    section.add "restapi_id", valid_595316
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595317 = header.getOrDefault("X-Amz-Date")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Date", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-Security-Token")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-Security-Token", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-Content-Sha256", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Algorithm")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Algorithm", valid_595320
  var valid_595321 = header.getOrDefault("X-Amz-Signature")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Signature", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-SignedHeaders", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Credential")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Credential", valid_595323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595324: Call_GetRequestValidator_595312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_595324.validator(path, query, header, formData, body)
  let scheme = call_595324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595324.url(scheme.get, call_595324.host, call_595324.base,
                         call_595324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595324, url, valid)

proc call*(call_595325: Call_GetRequestValidator_595312;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595326 = newJObject()
  add(path_595326, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_595326, "restapi_id", newJString(restapiId))
  result = call_595325.call(path_595326, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_595312(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_595313, base: "/",
    url: url_GetRequestValidator_595314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_595342 = ref object of OpenApiRestCall_593421
proc url_UpdateRequestValidator_595344(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateRequestValidator_595343(path: JsonNode; query: JsonNode;
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
  var valid_595345 = path.getOrDefault("requestvalidator_id")
  valid_595345 = validateParameter(valid_595345, JString, required = true,
                                 default = nil)
  if valid_595345 != nil:
    section.add "requestvalidator_id", valid_595345
  var valid_595346 = path.getOrDefault("restapi_id")
  valid_595346 = validateParameter(valid_595346, JString, required = true,
                                 default = nil)
  if valid_595346 != nil:
    section.add "restapi_id", valid_595346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595347 = header.getOrDefault("X-Amz-Date")
  valid_595347 = validateParameter(valid_595347, JString, required = false,
                                 default = nil)
  if valid_595347 != nil:
    section.add "X-Amz-Date", valid_595347
  var valid_595348 = header.getOrDefault("X-Amz-Security-Token")
  valid_595348 = validateParameter(valid_595348, JString, required = false,
                                 default = nil)
  if valid_595348 != nil:
    section.add "X-Amz-Security-Token", valid_595348
  var valid_595349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595349 = validateParameter(valid_595349, JString, required = false,
                                 default = nil)
  if valid_595349 != nil:
    section.add "X-Amz-Content-Sha256", valid_595349
  var valid_595350 = header.getOrDefault("X-Amz-Algorithm")
  valid_595350 = validateParameter(valid_595350, JString, required = false,
                                 default = nil)
  if valid_595350 != nil:
    section.add "X-Amz-Algorithm", valid_595350
  var valid_595351 = header.getOrDefault("X-Amz-Signature")
  valid_595351 = validateParameter(valid_595351, JString, required = false,
                                 default = nil)
  if valid_595351 != nil:
    section.add "X-Amz-Signature", valid_595351
  var valid_595352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "X-Amz-SignedHeaders", valid_595352
  var valid_595353 = header.getOrDefault("X-Amz-Credential")
  valid_595353 = validateParameter(valid_595353, JString, required = false,
                                 default = nil)
  if valid_595353 != nil:
    section.add "X-Amz-Credential", valid_595353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595355: Call_UpdateRequestValidator_595342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_595355.validator(path, query, header, formData, body)
  let scheme = call_595355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595355.url(scheme.get, call_595355.host, call_595355.base,
                         call_595355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595355, url, valid)

proc call*(call_595356: Call_UpdateRequestValidator_595342;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595357 = newJObject()
  var body_595358 = newJObject()
  add(path_595357, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_595358 = body
  add(path_595357, "restapi_id", newJString(restapiId))
  result = call_595356.call(path_595357, nil, nil, nil, body_595358)

var updateRequestValidator* = Call_UpdateRequestValidator_595342(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_595343, base: "/",
    url: url_UpdateRequestValidator_595344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_595327 = ref object of OpenApiRestCall_593421
proc url_DeleteRequestValidator_595329(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteRequestValidator_595328(path: JsonNode; query: JsonNode;
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
  var valid_595330 = path.getOrDefault("requestvalidator_id")
  valid_595330 = validateParameter(valid_595330, JString, required = true,
                                 default = nil)
  if valid_595330 != nil:
    section.add "requestvalidator_id", valid_595330
  var valid_595331 = path.getOrDefault("restapi_id")
  valid_595331 = validateParameter(valid_595331, JString, required = true,
                                 default = nil)
  if valid_595331 != nil:
    section.add "restapi_id", valid_595331
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595332 = header.getOrDefault("X-Amz-Date")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Date", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-Security-Token")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-Security-Token", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-Content-Sha256", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Algorithm")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Algorithm", valid_595335
  var valid_595336 = header.getOrDefault("X-Amz-Signature")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "X-Amz-Signature", valid_595336
  var valid_595337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "X-Amz-SignedHeaders", valid_595337
  var valid_595338 = header.getOrDefault("X-Amz-Credential")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Credential", valid_595338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595339: Call_DeleteRequestValidator_595327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_595339.validator(path, query, header, formData, body)
  let scheme = call_595339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595339.url(scheme.get, call_595339.host, call_595339.base,
                         call_595339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595339, url, valid)

proc call*(call_595340: Call_DeleteRequestValidator_595327;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595341 = newJObject()
  add(path_595341, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_595341, "restapi_id", newJString(restapiId))
  result = call_595340.call(path_595341, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_595327(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_595328, base: "/",
    url: url_DeleteRequestValidator_595329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_595359 = ref object of OpenApiRestCall_593421
proc url_GetResource_595361(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetResource_595360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595362 = path.getOrDefault("restapi_id")
  valid_595362 = validateParameter(valid_595362, JString, required = true,
                                 default = nil)
  if valid_595362 != nil:
    section.add "restapi_id", valid_595362
  var valid_595363 = path.getOrDefault("resource_id")
  valid_595363 = validateParameter(valid_595363, JString, required = true,
                                 default = nil)
  if valid_595363 != nil:
    section.add "resource_id", valid_595363
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_595364 = query.getOrDefault("embed")
  valid_595364 = validateParameter(valid_595364, JArray, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "embed", valid_595364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595365 = header.getOrDefault("X-Amz-Date")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Date", valid_595365
  var valid_595366 = header.getOrDefault("X-Amz-Security-Token")
  valid_595366 = validateParameter(valid_595366, JString, required = false,
                                 default = nil)
  if valid_595366 != nil:
    section.add "X-Amz-Security-Token", valid_595366
  var valid_595367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595367 = validateParameter(valid_595367, JString, required = false,
                                 default = nil)
  if valid_595367 != nil:
    section.add "X-Amz-Content-Sha256", valid_595367
  var valid_595368 = header.getOrDefault("X-Amz-Algorithm")
  valid_595368 = validateParameter(valid_595368, JString, required = false,
                                 default = nil)
  if valid_595368 != nil:
    section.add "X-Amz-Algorithm", valid_595368
  var valid_595369 = header.getOrDefault("X-Amz-Signature")
  valid_595369 = validateParameter(valid_595369, JString, required = false,
                                 default = nil)
  if valid_595369 != nil:
    section.add "X-Amz-Signature", valid_595369
  var valid_595370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595370 = validateParameter(valid_595370, JString, required = false,
                                 default = nil)
  if valid_595370 != nil:
    section.add "X-Amz-SignedHeaders", valid_595370
  var valid_595371 = header.getOrDefault("X-Amz-Credential")
  valid_595371 = validateParameter(valid_595371, JString, required = false,
                                 default = nil)
  if valid_595371 != nil:
    section.add "X-Amz-Credential", valid_595371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595372: Call_GetResource_595359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_595372.validator(path, query, header, formData, body)
  let scheme = call_595372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595372.url(scheme.get, call_595372.host, call_595372.base,
                         call_595372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595372, url, valid)

proc call*(call_595373: Call_GetResource_595359; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_595374 = newJObject()
  var query_595375 = newJObject()
  if embed != nil:
    query_595375.add "embed", embed
  add(path_595374, "restapi_id", newJString(restapiId))
  add(path_595374, "resource_id", newJString(resourceId))
  result = call_595373.call(path_595374, query_595375, nil, nil, nil)

var getResource* = Call_GetResource_595359(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_595360,
                                        base: "/", url: url_GetResource_595361,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_595391 = ref object of OpenApiRestCall_593421
proc url_UpdateResource_595393(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateResource_595392(path: JsonNode; query: JsonNode;
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
  var valid_595394 = path.getOrDefault("restapi_id")
  valid_595394 = validateParameter(valid_595394, JString, required = true,
                                 default = nil)
  if valid_595394 != nil:
    section.add "restapi_id", valid_595394
  var valid_595395 = path.getOrDefault("resource_id")
  valid_595395 = validateParameter(valid_595395, JString, required = true,
                                 default = nil)
  if valid_595395 != nil:
    section.add "resource_id", valid_595395
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595396 = header.getOrDefault("X-Amz-Date")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "X-Amz-Date", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Security-Token")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Security-Token", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Content-Sha256", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-Algorithm")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-Algorithm", valid_595399
  var valid_595400 = header.getOrDefault("X-Amz-Signature")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-Signature", valid_595400
  var valid_595401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "X-Amz-SignedHeaders", valid_595401
  var valid_595402 = header.getOrDefault("X-Amz-Credential")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "X-Amz-Credential", valid_595402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595404: Call_UpdateResource_595391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_595404.validator(path, query, header, formData, body)
  let scheme = call_595404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595404.url(scheme.get, call_595404.host, call_595404.base,
                         call_595404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595404, url, valid)

proc call*(call_595405: Call_UpdateResource_595391; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_595406 = newJObject()
  var body_595407 = newJObject()
  if body != nil:
    body_595407 = body
  add(path_595406, "restapi_id", newJString(restapiId))
  add(path_595406, "resource_id", newJString(resourceId))
  result = call_595405.call(path_595406, nil, nil, nil, body_595407)

var updateResource* = Call_UpdateResource_595391(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_595392, base: "/", url: url_UpdateResource_595393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_595376 = ref object of OpenApiRestCall_593421
proc url_DeleteResource_595378(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteResource_595377(path: JsonNode; query: JsonNode;
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
  var valid_595379 = path.getOrDefault("restapi_id")
  valid_595379 = validateParameter(valid_595379, JString, required = true,
                                 default = nil)
  if valid_595379 != nil:
    section.add "restapi_id", valid_595379
  var valid_595380 = path.getOrDefault("resource_id")
  valid_595380 = validateParameter(valid_595380, JString, required = true,
                                 default = nil)
  if valid_595380 != nil:
    section.add "resource_id", valid_595380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595381 = header.getOrDefault("X-Amz-Date")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "X-Amz-Date", valid_595381
  var valid_595382 = header.getOrDefault("X-Amz-Security-Token")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "X-Amz-Security-Token", valid_595382
  var valid_595383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595383 = validateParameter(valid_595383, JString, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "X-Amz-Content-Sha256", valid_595383
  var valid_595384 = header.getOrDefault("X-Amz-Algorithm")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "X-Amz-Algorithm", valid_595384
  var valid_595385 = header.getOrDefault("X-Amz-Signature")
  valid_595385 = validateParameter(valid_595385, JString, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "X-Amz-Signature", valid_595385
  var valid_595386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595386 = validateParameter(valid_595386, JString, required = false,
                                 default = nil)
  if valid_595386 != nil:
    section.add "X-Amz-SignedHeaders", valid_595386
  var valid_595387 = header.getOrDefault("X-Amz-Credential")
  valid_595387 = validateParameter(valid_595387, JString, required = false,
                                 default = nil)
  if valid_595387 != nil:
    section.add "X-Amz-Credential", valid_595387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595388: Call_DeleteResource_595376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_595388.validator(path, query, header, formData, body)
  let scheme = call_595388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595388.url(scheme.get, call_595388.host, call_595388.base,
                         call_595388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595388, url, valid)

proc call*(call_595389: Call_DeleteResource_595376; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_595390 = newJObject()
  add(path_595390, "restapi_id", newJString(restapiId))
  add(path_595390, "resource_id", newJString(resourceId))
  result = call_595389.call(path_595390, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_595376(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_595377, base: "/", url: url_DeleteResource_595378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_595422 = ref object of OpenApiRestCall_593421
proc url_PutRestApi_595424(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_PutRestApi_595423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595425 = path.getOrDefault("restapi_id")
  valid_595425 = validateParameter(valid_595425, JString, required = true,
                                 default = nil)
  if valid_595425 != nil:
    section.add "restapi_id", valid_595425
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
  var valid_595426 = query.getOrDefault("parameters.0.value")
  valid_595426 = validateParameter(valid_595426, JString, required = false,
                                 default = nil)
  if valid_595426 != nil:
    section.add "parameters.0.value", valid_595426
  var valid_595427 = query.getOrDefault("parameters.2.value")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "parameters.2.value", valid_595427
  var valid_595428 = query.getOrDefault("parameters.1.key")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "parameters.1.key", valid_595428
  var valid_595429 = query.getOrDefault("mode")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = newJString("merge"))
  if valid_595429 != nil:
    section.add "mode", valid_595429
  var valid_595430 = query.getOrDefault("parameters.0.key")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "parameters.0.key", valid_595430
  var valid_595431 = query.getOrDefault("parameters.2.key")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "parameters.2.key", valid_595431
  var valid_595432 = query.getOrDefault("failonwarnings")
  valid_595432 = validateParameter(valid_595432, JBool, required = false, default = nil)
  if valid_595432 != nil:
    section.add "failonwarnings", valid_595432
  var valid_595433 = query.getOrDefault("parameters.1.value")
  valid_595433 = validateParameter(valid_595433, JString, required = false,
                                 default = nil)
  if valid_595433 != nil:
    section.add "parameters.1.value", valid_595433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595434 = header.getOrDefault("X-Amz-Date")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "X-Amz-Date", valid_595434
  var valid_595435 = header.getOrDefault("X-Amz-Security-Token")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "X-Amz-Security-Token", valid_595435
  var valid_595436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595436 = validateParameter(valid_595436, JString, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "X-Amz-Content-Sha256", valid_595436
  var valid_595437 = header.getOrDefault("X-Amz-Algorithm")
  valid_595437 = validateParameter(valid_595437, JString, required = false,
                                 default = nil)
  if valid_595437 != nil:
    section.add "X-Amz-Algorithm", valid_595437
  var valid_595438 = header.getOrDefault("X-Amz-Signature")
  valid_595438 = validateParameter(valid_595438, JString, required = false,
                                 default = nil)
  if valid_595438 != nil:
    section.add "X-Amz-Signature", valid_595438
  var valid_595439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595439 = validateParameter(valid_595439, JString, required = false,
                                 default = nil)
  if valid_595439 != nil:
    section.add "X-Amz-SignedHeaders", valid_595439
  var valid_595440 = header.getOrDefault("X-Amz-Credential")
  valid_595440 = validateParameter(valid_595440, JString, required = false,
                                 default = nil)
  if valid_595440 != nil:
    section.add "X-Amz-Credential", valid_595440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595442: Call_PutRestApi_595422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_595442.validator(path, query, header, formData, body)
  let scheme = call_595442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595442.url(scheme.get, call_595442.host, call_595442.base,
                         call_595442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595442, url, valid)

proc call*(call_595443: Call_PutRestApi_595422; body: JsonNode; restapiId: string;
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
  var path_595444 = newJObject()
  var query_595445 = newJObject()
  var body_595446 = newJObject()
  add(query_595445, "parameters.0.value", newJString(parameters0Value))
  add(query_595445, "parameters.2.value", newJString(parameters2Value))
  add(query_595445, "parameters.1.key", newJString(parameters1Key))
  add(query_595445, "mode", newJString(mode))
  add(query_595445, "parameters.0.key", newJString(parameters0Key))
  add(query_595445, "parameters.2.key", newJString(parameters2Key))
  add(query_595445, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_595446 = body
  add(query_595445, "parameters.1.value", newJString(parameters1Value))
  add(path_595444, "restapi_id", newJString(restapiId))
  result = call_595443.call(path_595444, query_595445, nil, nil, body_595446)

var putRestApi* = Call_PutRestApi_595422(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_595423,
                                      base: "/", url: url_PutRestApi_595424,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_595408 = ref object of OpenApiRestCall_593421
proc url_GetRestApi_595410(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetRestApi_595409(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595411 = path.getOrDefault("restapi_id")
  valid_595411 = validateParameter(valid_595411, JString, required = true,
                                 default = nil)
  if valid_595411 != nil:
    section.add "restapi_id", valid_595411
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595412 = header.getOrDefault("X-Amz-Date")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Date", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-Security-Token")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-Security-Token", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-Content-Sha256", valid_595414
  var valid_595415 = header.getOrDefault("X-Amz-Algorithm")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-Algorithm", valid_595415
  var valid_595416 = header.getOrDefault("X-Amz-Signature")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Signature", valid_595416
  var valid_595417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "X-Amz-SignedHeaders", valid_595417
  var valid_595418 = header.getOrDefault("X-Amz-Credential")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "X-Amz-Credential", valid_595418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595419: Call_GetRestApi_595408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_595419.validator(path, query, header, formData, body)
  let scheme = call_595419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595419.url(scheme.get, call_595419.host, call_595419.base,
                         call_595419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595419, url, valid)

proc call*(call_595420: Call_GetRestApi_595408; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595421 = newJObject()
  add(path_595421, "restapi_id", newJString(restapiId))
  result = call_595420.call(path_595421, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_595408(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_595409,
                                      base: "/", url: url_GetRestApi_595410,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_595461 = ref object of OpenApiRestCall_593421
proc url_UpdateRestApi_595463(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateRestApi_595462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595464 = path.getOrDefault("restapi_id")
  valid_595464 = validateParameter(valid_595464, JString, required = true,
                                 default = nil)
  if valid_595464 != nil:
    section.add "restapi_id", valid_595464
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595465 = header.getOrDefault("X-Amz-Date")
  valid_595465 = validateParameter(valid_595465, JString, required = false,
                                 default = nil)
  if valid_595465 != nil:
    section.add "X-Amz-Date", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Security-Token")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Security-Token", valid_595466
  var valid_595467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Content-Sha256", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Algorithm")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Algorithm", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Signature")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Signature", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-SignedHeaders", valid_595470
  var valid_595471 = header.getOrDefault("X-Amz-Credential")
  valid_595471 = validateParameter(valid_595471, JString, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "X-Amz-Credential", valid_595471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595473: Call_UpdateRestApi_595461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_595473.validator(path, query, header, formData, body)
  let scheme = call_595473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595473.url(scheme.get, call_595473.host, call_595473.base,
                         call_595473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595473, url, valid)

proc call*(call_595474: Call_UpdateRestApi_595461; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595475 = newJObject()
  var body_595476 = newJObject()
  if body != nil:
    body_595476 = body
  add(path_595475, "restapi_id", newJString(restapiId))
  result = call_595474.call(path_595475, nil, nil, nil, body_595476)

var updateRestApi* = Call_UpdateRestApi_595461(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_595462,
    base: "/", url: url_UpdateRestApi_595463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_595447 = ref object of OpenApiRestCall_593421
proc url_DeleteRestApi_595449(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteRestApi_595448(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595450 = path.getOrDefault("restapi_id")
  valid_595450 = validateParameter(valid_595450, JString, required = true,
                                 default = nil)
  if valid_595450 != nil:
    section.add "restapi_id", valid_595450
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595451 = header.getOrDefault("X-Amz-Date")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Date", valid_595451
  var valid_595452 = header.getOrDefault("X-Amz-Security-Token")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Security-Token", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-Content-Sha256", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-Algorithm")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Algorithm", valid_595454
  var valid_595455 = header.getOrDefault("X-Amz-Signature")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "X-Amz-Signature", valid_595455
  var valid_595456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595456 = validateParameter(valid_595456, JString, required = false,
                                 default = nil)
  if valid_595456 != nil:
    section.add "X-Amz-SignedHeaders", valid_595456
  var valid_595457 = header.getOrDefault("X-Amz-Credential")
  valid_595457 = validateParameter(valid_595457, JString, required = false,
                                 default = nil)
  if valid_595457 != nil:
    section.add "X-Amz-Credential", valid_595457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595458: Call_DeleteRestApi_595447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_595458.validator(path, query, header, formData, body)
  let scheme = call_595458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595458.url(scheme.get, call_595458.host, call_595458.base,
                         call_595458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595458, url, valid)

proc call*(call_595459: Call_DeleteRestApi_595447; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595460 = newJObject()
  add(path_595460, "restapi_id", newJString(restapiId))
  result = call_595459.call(path_595460, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_595447(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_595448,
    base: "/", url: url_DeleteRestApi_595449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_595477 = ref object of OpenApiRestCall_593421
proc url_GetStage_595479(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetStage_595478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595480 = path.getOrDefault("stage_name")
  valid_595480 = validateParameter(valid_595480, JString, required = true,
                                 default = nil)
  if valid_595480 != nil:
    section.add "stage_name", valid_595480
  var valid_595481 = path.getOrDefault("restapi_id")
  valid_595481 = validateParameter(valid_595481, JString, required = true,
                                 default = nil)
  if valid_595481 != nil:
    section.add "restapi_id", valid_595481
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595482 = header.getOrDefault("X-Amz-Date")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "X-Amz-Date", valid_595482
  var valid_595483 = header.getOrDefault("X-Amz-Security-Token")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "X-Amz-Security-Token", valid_595483
  var valid_595484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Content-Sha256", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Algorithm")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Algorithm", valid_595485
  var valid_595486 = header.getOrDefault("X-Amz-Signature")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-Signature", valid_595486
  var valid_595487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "X-Amz-SignedHeaders", valid_595487
  var valid_595488 = header.getOrDefault("X-Amz-Credential")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "X-Amz-Credential", valid_595488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595489: Call_GetStage_595477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_595489.validator(path, query, header, formData, body)
  let scheme = call_595489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595489.url(scheme.get, call_595489.host, call_595489.base,
                         call_595489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595489, url, valid)

proc call*(call_595490: Call_GetStage_595477; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595491 = newJObject()
  add(path_595491, "stage_name", newJString(stageName))
  add(path_595491, "restapi_id", newJString(restapiId))
  result = call_595490.call(path_595491, nil, nil, nil, nil)

var getStage* = Call_GetStage_595477(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_595478, base: "/",
                                  url: url_GetStage_595479,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_595507 = ref object of OpenApiRestCall_593421
proc url_UpdateStage_595509(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateStage_595508(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595510 = path.getOrDefault("stage_name")
  valid_595510 = validateParameter(valid_595510, JString, required = true,
                                 default = nil)
  if valid_595510 != nil:
    section.add "stage_name", valid_595510
  var valid_595511 = path.getOrDefault("restapi_id")
  valid_595511 = validateParameter(valid_595511, JString, required = true,
                                 default = nil)
  if valid_595511 != nil:
    section.add "restapi_id", valid_595511
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595512 = header.getOrDefault("X-Amz-Date")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-Date", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Security-Token")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Security-Token", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-Content-Sha256", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Algorithm")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Algorithm", valid_595515
  var valid_595516 = header.getOrDefault("X-Amz-Signature")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "X-Amz-Signature", valid_595516
  var valid_595517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-SignedHeaders", valid_595517
  var valid_595518 = header.getOrDefault("X-Amz-Credential")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-Credential", valid_595518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595520: Call_UpdateStage_595507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_595520.validator(path, query, header, formData, body)
  let scheme = call_595520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595520.url(scheme.get, call_595520.host, call_595520.base,
                         call_595520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595520, url, valid)

proc call*(call_595521: Call_UpdateStage_595507; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595522 = newJObject()
  var body_595523 = newJObject()
  if body != nil:
    body_595523 = body
  add(path_595522, "stage_name", newJString(stageName))
  add(path_595522, "restapi_id", newJString(restapiId))
  result = call_595521.call(path_595522, nil, nil, nil, body_595523)

var updateStage* = Call_UpdateStage_595507(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_595508,
                                        base: "/", url: url_UpdateStage_595509,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_595492 = ref object of OpenApiRestCall_593421
proc url_DeleteStage_595494(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteStage_595493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595495 = path.getOrDefault("stage_name")
  valid_595495 = validateParameter(valid_595495, JString, required = true,
                                 default = nil)
  if valid_595495 != nil:
    section.add "stage_name", valid_595495
  var valid_595496 = path.getOrDefault("restapi_id")
  valid_595496 = validateParameter(valid_595496, JString, required = true,
                                 default = nil)
  if valid_595496 != nil:
    section.add "restapi_id", valid_595496
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595497 = header.getOrDefault("X-Amz-Date")
  valid_595497 = validateParameter(valid_595497, JString, required = false,
                                 default = nil)
  if valid_595497 != nil:
    section.add "X-Amz-Date", valid_595497
  var valid_595498 = header.getOrDefault("X-Amz-Security-Token")
  valid_595498 = validateParameter(valid_595498, JString, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "X-Amz-Security-Token", valid_595498
  var valid_595499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-Content-Sha256", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Algorithm")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Algorithm", valid_595500
  var valid_595501 = header.getOrDefault("X-Amz-Signature")
  valid_595501 = validateParameter(valid_595501, JString, required = false,
                                 default = nil)
  if valid_595501 != nil:
    section.add "X-Amz-Signature", valid_595501
  var valid_595502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-SignedHeaders", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-Credential")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Credential", valid_595503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595504: Call_DeleteStage_595492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_595504.validator(path, query, header, formData, body)
  let scheme = call_595504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595504.url(scheme.get, call_595504.host, call_595504.base,
                         call_595504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595504, url, valid)

proc call*(call_595505: Call_DeleteStage_595492; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595506 = newJObject()
  add(path_595506, "stage_name", newJString(stageName))
  add(path_595506, "restapi_id", newJString(restapiId))
  result = call_595505.call(path_595506, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_595492(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_595493,
                                        base: "/", url: url_DeleteStage_595494,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_595524 = ref object of OpenApiRestCall_593421
proc url_GetUsagePlan_595526(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUsagePlan_595525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595527 = path.getOrDefault("usageplanId")
  valid_595527 = validateParameter(valid_595527, JString, required = true,
                                 default = nil)
  if valid_595527 != nil:
    section.add "usageplanId", valid_595527
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595528 = header.getOrDefault("X-Amz-Date")
  valid_595528 = validateParameter(valid_595528, JString, required = false,
                                 default = nil)
  if valid_595528 != nil:
    section.add "X-Amz-Date", valid_595528
  var valid_595529 = header.getOrDefault("X-Amz-Security-Token")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Security-Token", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Content-Sha256", valid_595530
  var valid_595531 = header.getOrDefault("X-Amz-Algorithm")
  valid_595531 = validateParameter(valid_595531, JString, required = false,
                                 default = nil)
  if valid_595531 != nil:
    section.add "X-Amz-Algorithm", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Signature")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Signature", valid_595532
  var valid_595533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595533 = validateParameter(valid_595533, JString, required = false,
                                 default = nil)
  if valid_595533 != nil:
    section.add "X-Amz-SignedHeaders", valid_595533
  var valid_595534 = header.getOrDefault("X-Amz-Credential")
  valid_595534 = validateParameter(valid_595534, JString, required = false,
                                 default = nil)
  if valid_595534 != nil:
    section.add "X-Amz-Credential", valid_595534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595535: Call_GetUsagePlan_595524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_595535.validator(path, query, header, formData, body)
  let scheme = call_595535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595535.url(scheme.get, call_595535.host, call_595535.base,
                         call_595535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595535, url, valid)

proc call*(call_595536: Call_GetUsagePlan_595524; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_595537 = newJObject()
  add(path_595537, "usageplanId", newJString(usageplanId))
  result = call_595536.call(path_595537, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_595524(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_595525,
    base: "/", url: url_GetUsagePlan_595526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_595552 = ref object of OpenApiRestCall_593421
proc url_UpdateUsagePlan_595554(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateUsagePlan_595553(path: JsonNode; query: JsonNode;
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
  var valid_595555 = path.getOrDefault("usageplanId")
  valid_595555 = validateParameter(valid_595555, JString, required = true,
                                 default = nil)
  if valid_595555 != nil:
    section.add "usageplanId", valid_595555
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595556 = header.getOrDefault("X-Amz-Date")
  valid_595556 = validateParameter(valid_595556, JString, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "X-Amz-Date", valid_595556
  var valid_595557 = header.getOrDefault("X-Amz-Security-Token")
  valid_595557 = validateParameter(valid_595557, JString, required = false,
                                 default = nil)
  if valid_595557 != nil:
    section.add "X-Amz-Security-Token", valid_595557
  var valid_595558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595558 = validateParameter(valid_595558, JString, required = false,
                                 default = nil)
  if valid_595558 != nil:
    section.add "X-Amz-Content-Sha256", valid_595558
  var valid_595559 = header.getOrDefault("X-Amz-Algorithm")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Algorithm", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Signature")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Signature", valid_595560
  var valid_595561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "X-Amz-SignedHeaders", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-Credential")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-Credential", valid_595562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595564: Call_UpdateUsagePlan_595552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_595564.validator(path, query, header, formData, body)
  let scheme = call_595564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595564.url(scheme.get, call_595564.host, call_595564.base,
                         call_595564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595564, url, valid)

proc call*(call_595565: Call_UpdateUsagePlan_595552; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_595566 = newJObject()
  var body_595567 = newJObject()
  add(path_595566, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_595567 = body
  result = call_595565.call(path_595566, nil, nil, nil, body_595567)

var updateUsagePlan* = Call_UpdateUsagePlan_595552(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_595553,
    base: "/", url: url_UpdateUsagePlan_595554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_595538 = ref object of OpenApiRestCall_593421
proc url_DeleteUsagePlan_595540(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteUsagePlan_595539(path: JsonNode; query: JsonNode;
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
  var valid_595541 = path.getOrDefault("usageplanId")
  valid_595541 = validateParameter(valid_595541, JString, required = true,
                                 default = nil)
  if valid_595541 != nil:
    section.add "usageplanId", valid_595541
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595542 = header.getOrDefault("X-Amz-Date")
  valid_595542 = validateParameter(valid_595542, JString, required = false,
                                 default = nil)
  if valid_595542 != nil:
    section.add "X-Amz-Date", valid_595542
  var valid_595543 = header.getOrDefault("X-Amz-Security-Token")
  valid_595543 = validateParameter(valid_595543, JString, required = false,
                                 default = nil)
  if valid_595543 != nil:
    section.add "X-Amz-Security-Token", valid_595543
  var valid_595544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Content-Sha256", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Algorithm")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Algorithm", valid_595545
  var valid_595546 = header.getOrDefault("X-Amz-Signature")
  valid_595546 = validateParameter(valid_595546, JString, required = false,
                                 default = nil)
  if valid_595546 != nil:
    section.add "X-Amz-Signature", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-SignedHeaders", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Credential")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Credential", valid_595548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595549: Call_DeleteUsagePlan_595538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_595549.validator(path, query, header, formData, body)
  let scheme = call_595549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595549.url(scheme.get, call_595549.host, call_595549.base,
                         call_595549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595549, url, valid)

proc call*(call_595550: Call_DeleteUsagePlan_595538; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_595551 = newJObject()
  add(path_595551, "usageplanId", newJString(usageplanId))
  result = call_595550.call(path_595551, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_595538(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_595539,
    base: "/", url: url_DeleteUsagePlan_595540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_595568 = ref object of OpenApiRestCall_593421
proc url_GetUsagePlanKey_595570(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUsagePlanKey_595569(path: JsonNode; query: JsonNode;
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
  var valid_595571 = path.getOrDefault("keyId")
  valid_595571 = validateParameter(valid_595571, JString, required = true,
                                 default = nil)
  if valid_595571 != nil:
    section.add "keyId", valid_595571
  var valid_595572 = path.getOrDefault("usageplanId")
  valid_595572 = validateParameter(valid_595572, JString, required = true,
                                 default = nil)
  if valid_595572 != nil:
    section.add "usageplanId", valid_595572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595573 = header.getOrDefault("X-Amz-Date")
  valid_595573 = validateParameter(valid_595573, JString, required = false,
                                 default = nil)
  if valid_595573 != nil:
    section.add "X-Amz-Date", valid_595573
  var valid_595574 = header.getOrDefault("X-Amz-Security-Token")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "X-Amz-Security-Token", valid_595574
  var valid_595575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595575 = validateParameter(valid_595575, JString, required = false,
                                 default = nil)
  if valid_595575 != nil:
    section.add "X-Amz-Content-Sha256", valid_595575
  var valid_595576 = header.getOrDefault("X-Amz-Algorithm")
  valid_595576 = validateParameter(valid_595576, JString, required = false,
                                 default = nil)
  if valid_595576 != nil:
    section.add "X-Amz-Algorithm", valid_595576
  var valid_595577 = header.getOrDefault("X-Amz-Signature")
  valid_595577 = validateParameter(valid_595577, JString, required = false,
                                 default = nil)
  if valid_595577 != nil:
    section.add "X-Amz-Signature", valid_595577
  var valid_595578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595578 = validateParameter(valid_595578, JString, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "X-Amz-SignedHeaders", valid_595578
  var valid_595579 = header.getOrDefault("X-Amz-Credential")
  valid_595579 = validateParameter(valid_595579, JString, required = false,
                                 default = nil)
  if valid_595579 != nil:
    section.add "X-Amz-Credential", valid_595579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595580: Call_GetUsagePlanKey_595568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_595580.validator(path, query, header, formData, body)
  let scheme = call_595580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595580.url(scheme.get, call_595580.host, call_595580.base,
                         call_595580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595580, url, valid)

proc call*(call_595581: Call_GetUsagePlanKey_595568; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_595582 = newJObject()
  add(path_595582, "keyId", newJString(keyId))
  add(path_595582, "usageplanId", newJString(usageplanId))
  result = call_595581.call(path_595582, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_595568(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_595569, base: "/", url: url_GetUsagePlanKey_595570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_595583 = ref object of OpenApiRestCall_593421
proc url_DeleteUsagePlanKey_595585(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteUsagePlanKey_595584(path: JsonNode; query: JsonNode;
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
  var valid_595586 = path.getOrDefault("keyId")
  valid_595586 = validateParameter(valid_595586, JString, required = true,
                                 default = nil)
  if valid_595586 != nil:
    section.add "keyId", valid_595586
  var valid_595587 = path.getOrDefault("usageplanId")
  valid_595587 = validateParameter(valid_595587, JString, required = true,
                                 default = nil)
  if valid_595587 != nil:
    section.add "usageplanId", valid_595587
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595588 = header.getOrDefault("X-Amz-Date")
  valid_595588 = validateParameter(valid_595588, JString, required = false,
                                 default = nil)
  if valid_595588 != nil:
    section.add "X-Amz-Date", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Security-Token")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Security-Token", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Content-Sha256", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Algorithm")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Algorithm", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-Signature")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-Signature", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-SignedHeaders", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-Credential")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-Credential", valid_595594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595595: Call_DeleteUsagePlanKey_595583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_595595.validator(path, query, header, formData, body)
  let scheme = call_595595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595595.url(scheme.get, call_595595.host, call_595595.base,
                         call_595595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595595, url, valid)

proc call*(call_595596: Call_DeleteUsagePlanKey_595583; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_595597 = newJObject()
  add(path_595597, "keyId", newJString(keyId))
  add(path_595597, "usageplanId", newJString(usageplanId))
  result = call_595596.call(path_595597, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_595583(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_595584, base: "/",
    url: url_DeleteUsagePlanKey_595585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_595598 = ref object of OpenApiRestCall_593421
proc url_GetVpcLink_595600(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetVpcLink_595599(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595601 = path.getOrDefault("vpclink_id")
  valid_595601 = validateParameter(valid_595601, JString, required = true,
                                 default = nil)
  if valid_595601 != nil:
    section.add "vpclink_id", valid_595601
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595602 = header.getOrDefault("X-Amz-Date")
  valid_595602 = validateParameter(valid_595602, JString, required = false,
                                 default = nil)
  if valid_595602 != nil:
    section.add "X-Amz-Date", valid_595602
  var valid_595603 = header.getOrDefault("X-Amz-Security-Token")
  valid_595603 = validateParameter(valid_595603, JString, required = false,
                                 default = nil)
  if valid_595603 != nil:
    section.add "X-Amz-Security-Token", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Content-Sha256", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-Algorithm")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Algorithm", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Signature")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Signature", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-SignedHeaders", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-Credential")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Credential", valid_595608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595609: Call_GetVpcLink_595598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_595609.validator(path, query, header, formData, body)
  let scheme = call_595609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595609.url(scheme.get, call_595609.host, call_595609.base,
                         call_595609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595609, url, valid)

proc call*(call_595610: Call_GetVpcLink_595598; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_595611 = newJObject()
  add(path_595611, "vpclink_id", newJString(vpclinkId))
  result = call_595610.call(path_595611, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_595598(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_595599,
                                      base: "/", url: url_GetVpcLink_595600,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_595626 = ref object of OpenApiRestCall_593421
proc url_UpdateVpcLink_595628(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateVpcLink_595627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595629 = path.getOrDefault("vpclink_id")
  valid_595629 = validateParameter(valid_595629, JString, required = true,
                                 default = nil)
  if valid_595629 != nil:
    section.add "vpclink_id", valid_595629
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595630 = header.getOrDefault("X-Amz-Date")
  valid_595630 = validateParameter(valid_595630, JString, required = false,
                                 default = nil)
  if valid_595630 != nil:
    section.add "X-Amz-Date", valid_595630
  var valid_595631 = header.getOrDefault("X-Amz-Security-Token")
  valid_595631 = validateParameter(valid_595631, JString, required = false,
                                 default = nil)
  if valid_595631 != nil:
    section.add "X-Amz-Security-Token", valid_595631
  var valid_595632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595632 = validateParameter(valid_595632, JString, required = false,
                                 default = nil)
  if valid_595632 != nil:
    section.add "X-Amz-Content-Sha256", valid_595632
  var valid_595633 = header.getOrDefault("X-Amz-Algorithm")
  valid_595633 = validateParameter(valid_595633, JString, required = false,
                                 default = nil)
  if valid_595633 != nil:
    section.add "X-Amz-Algorithm", valid_595633
  var valid_595634 = header.getOrDefault("X-Amz-Signature")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Signature", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-SignedHeaders", valid_595635
  var valid_595636 = header.getOrDefault("X-Amz-Credential")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Credential", valid_595636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595638: Call_UpdateVpcLink_595626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_595638.validator(path, query, header, formData, body)
  let scheme = call_595638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595638.url(scheme.get, call_595638.host, call_595638.base,
                         call_595638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595638, url, valid)

proc call*(call_595639: Call_UpdateVpcLink_595626; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_595640 = newJObject()
  var body_595641 = newJObject()
  if body != nil:
    body_595641 = body
  add(path_595640, "vpclink_id", newJString(vpclinkId))
  result = call_595639.call(path_595640, nil, nil, nil, body_595641)

var updateVpcLink* = Call_UpdateVpcLink_595626(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_595627,
    base: "/", url: url_UpdateVpcLink_595628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_595612 = ref object of OpenApiRestCall_593421
proc url_DeleteVpcLink_595614(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteVpcLink_595613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595615 = path.getOrDefault("vpclink_id")
  valid_595615 = validateParameter(valid_595615, JString, required = true,
                                 default = nil)
  if valid_595615 != nil:
    section.add "vpclink_id", valid_595615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595616 = header.getOrDefault("X-Amz-Date")
  valid_595616 = validateParameter(valid_595616, JString, required = false,
                                 default = nil)
  if valid_595616 != nil:
    section.add "X-Amz-Date", valid_595616
  var valid_595617 = header.getOrDefault("X-Amz-Security-Token")
  valid_595617 = validateParameter(valid_595617, JString, required = false,
                                 default = nil)
  if valid_595617 != nil:
    section.add "X-Amz-Security-Token", valid_595617
  var valid_595618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595618 = validateParameter(valid_595618, JString, required = false,
                                 default = nil)
  if valid_595618 != nil:
    section.add "X-Amz-Content-Sha256", valid_595618
  var valid_595619 = header.getOrDefault("X-Amz-Algorithm")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "X-Amz-Algorithm", valid_595619
  var valid_595620 = header.getOrDefault("X-Amz-Signature")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "X-Amz-Signature", valid_595620
  var valid_595621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "X-Amz-SignedHeaders", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-Credential")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-Credential", valid_595622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595623: Call_DeleteVpcLink_595612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_595623.validator(path, query, header, formData, body)
  let scheme = call_595623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595623.url(scheme.get, call_595623.host, call_595623.base,
                         call_595623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595623, url, valid)

proc call*(call_595624: Call_DeleteVpcLink_595612; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_595625 = newJObject()
  add(path_595625, "vpclink_id", newJString(vpclinkId))
  result = call_595624.call(path_595625, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_595612(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_595613,
    base: "/", url: url_DeleteVpcLink_595614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_595642 = ref object of OpenApiRestCall_593421
proc url_FlushStageAuthorizersCache_595644(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_FlushStageAuthorizersCache_595643(path: JsonNode; query: JsonNode;
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
  var valid_595645 = path.getOrDefault("stage_name")
  valid_595645 = validateParameter(valid_595645, JString, required = true,
                                 default = nil)
  if valid_595645 != nil:
    section.add "stage_name", valid_595645
  var valid_595646 = path.getOrDefault("restapi_id")
  valid_595646 = validateParameter(valid_595646, JString, required = true,
                                 default = nil)
  if valid_595646 != nil:
    section.add "restapi_id", valid_595646
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595647 = header.getOrDefault("X-Amz-Date")
  valid_595647 = validateParameter(valid_595647, JString, required = false,
                                 default = nil)
  if valid_595647 != nil:
    section.add "X-Amz-Date", valid_595647
  var valid_595648 = header.getOrDefault("X-Amz-Security-Token")
  valid_595648 = validateParameter(valid_595648, JString, required = false,
                                 default = nil)
  if valid_595648 != nil:
    section.add "X-Amz-Security-Token", valid_595648
  var valid_595649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595649 = validateParameter(valid_595649, JString, required = false,
                                 default = nil)
  if valid_595649 != nil:
    section.add "X-Amz-Content-Sha256", valid_595649
  var valid_595650 = header.getOrDefault("X-Amz-Algorithm")
  valid_595650 = validateParameter(valid_595650, JString, required = false,
                                 default = nil)
  if valid_595650 != nil:
    section.add "X-Amz-Algorithm", valid_595650
  var valid_595651 = header.getOrDefault("X-Amz-Signature")
  valid_595651 = validateParameter(valid_595651, JString, required = false,
                                 default = nil)
  if valid_595651 != nil:
    section.add "X-Amz-Signature", valid_595651
  var valid_595652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595652 = validateParameter(valid_595652, JString, required = false,
                                 default = nil)
  if valid_595652 != nil:
    section.add "X-Amz-SignedHeaders", valid_595652
  var valid_595653 = header.getOrDefault("X-Amz-Credential")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "X-Amz-Credential", valid_595653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595654: Call_FlushStageAuthorizersCache_595642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_595654.validator(path, query, header, formData, body)
  let scheme = call_595654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595654.url(scheme.get, call_595654.host, call_595654.base,
                         call_595654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595654, url, valid)

proc call*(call_595655: Call_FlushStageAuthorizersCache_595642; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_595656 = newJObject()
  add(path_595656, "stage_name", newJString(stageName))
  add(path_595656, "restapi_id", newJString(restapiId))
  result = call_595655.call(path_595656, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_595642(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_595643, base: "/",
    url: url_FlushStageAuthorizersCache_595644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_595657 = ref object of OpenApiRestCall_593421
proc url_FlushStageCache_595659(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_FlushStageCache_595658(path: JsonNode; query: JsonNode;
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
  var valid_595660 = path.getOrDefault("stage_name")
  valid_595660 = validateParameter(valid_595660, JString, required = true,
                                 default = nil)
  if valid_595660 != nil:
    section.add "stage_name", valid_595660
  var valid_595661 = path.getOrDefault("restapi_id")
  valid_595661 = validateParameter(valid_595661, JString, required = true,
                                 default = nil)
  if valid_595661 != nil:
    section.add "restapi_id", valid_595661
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595662 = header.getOrDefault("X-Amz-Date")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Date", valid_595662
  var valid_595663 = header.getOrDefault("X-Amz-Security-Token")
  valid_595663 = validateParameter(valid_595663, JString, required = false,
                                 default = nil)
  if valid_595663 != nil:
    section.add "X-Amz-Security-Token", valid_595663
  var valid_595664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "X-Amz-Content-Sha256", valid_595664
  var valid_595665 = header.getOrDefault("X-Amz-Algorithm")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "X-Amz-Algorithm", valid_595665
  var valid_595666 = header.getOrDefault("X-Amz-Signature")
  valid_595666 = validateParameter(valid_595666, JString, required = false,
                                 default = nil)
  if valid_595666 != nil:
    section.add "X-Amz-Signature", valid_595666
  var valid_595667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "X-Amz-SignedHeaders", valid_595667
  var valid_595668 = header.getOrDefault("X-Amz-Credential")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "X-Amz-Credential", valid_595668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595669: Call_FlushStageCache_595657; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_595669.validator(path, query, header, formData, body)
  let scheme = call_595669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595669.url(scheme.get, call_595669.host, call_595669.base,
                         call_595669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595669, url, valid)

proc call*(call_595670: Call_FlushStageCache_595657; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595671 = newJObject()
  add(path_595671, "stage_name", newJString(stageName))
  add(path_595671, "restapi_id", newJString(restapiId))
  result = call_595670.call(path_595671, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_595657(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_595658, base: "/", url: url_FlushStageCache_595659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_595687 = ref object of OpenApiRestCall_593421
proc url_GenerateClientCertificate_595689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateClientCertificate_595688(path: JsonNode; query: JsonNode;
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
  var valid_595690 = header.getOrDefault("X-Amz-Date")
  valid_595690 = validateParameter(valid_595690, JString, required = false,
                                 default = nil)
  if valid_595690 != nil:
    section.add "X-Amz-Date", valid_595690
  var valid_595691 = header.getOrDefault("X-Amz-Security-Token")
  valid_595691 = validateParameter(valid_595691, JString, required = false,
                                 default = nil)
  if valid_595691 != nil:
    section.add "X-Amz-Security-Token", valid_595691
  var valid_595692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595692 = validateParameter(valid_595692, JString, required = false,
                                 default = nil)
  if valid_595692 != nil:
    section.add "X-Amz-Content-Sha256", valid_595692
  var valid_595693 = header.getOrDefault("X-Amz-Algorithm")
  valid_595693 = validateParameter(valid_595693, JString, required = false,
                                 default = nil)
  if valid_595693 != nil:
    section.add "X-Amz-Algorithm", valid_595693
  var valid_595694 = header.getOrDefault("X-Amz-Signature")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Signature", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-SignedHeaders", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Credential")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Credential", valid_595696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595698: Call_GenerateClientCertificate_595687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_595698.validator(path, query, header, formData, body)
  let scheme = call_595698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595698.url(scheme.get, call_595698.host, call_595698.base,
                         call_595698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595698, url, valid)

proc call*(call_595699: Call_GenerateClientCertificate_595687; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_595700 = newJObject()
  if body != nil:
    body_595700 = body
  result = call_595699.call(nil, nil, nil, nil, body_595700)

var generateClientCertificate* = Call_GenerateClientCertificate_595687(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_595688, base: "/",
    url: url_GenerateClientCertificate_595689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_595672 = ref object of OpenApiRestCall_593421
proc url_GetClientCertificates_595674(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClientCertificates_595673(path: JsonNode; query: JsonNode;
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
  var valid_595675 = query.getOrDefault("position")
  valid_595675 = validateParameter(valid_595675, JString, required = false,
                                 default = nil)
  if valid_595675 != nil:
    section.add "position", valid_595675
  var valid_595676 = query.getOrDefault("limit")
  valid_595676 = validateParameter(valid_595676, JInt, required = false, default = nil)
  if valid_595676 != nil:
    section.add "limit", valid_595676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595677 = header.getOrDefault("X-Amz-Date")
  valid_595677 = validateParameter(valid_595677, JString, required = false,
                                 default = nil)
  if valid_595677 != nil:
    section.add "X-Amz-Date", valid_595677
  var valid_595678 = header.getOrDefault("X-Amz-Security-Token")
  valid_595678 = validateParameter(valid_595678, JString, required = false,
                                 default = nil)
  if valid_595678 != nil:
    section.add "X-Amz-Security-Token", valid_595678
  var valid_595679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Content-Sha256", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Algorithm")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Algorithm", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Signature")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Signature", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-SignedHeaders", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Credential")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Credential", valid_595683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595684: Call_GetClientCertificates_595672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_595684.validator(path, query, header, formData, body)
  let scheme = call_595684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595684.url(scheme.get, call_595684.host, call_595684.base,
                         call_595684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595684, url, valid)

proc call*(call_595685: Call_GetClientCertificates_595672; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_595686 = newJObject()
  add(query_595686, "position", newJString(position))
  add(query_595686, "limit", newJInt(limit))
  result = call_595685.call(nil, query_595686, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_595672(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_595673, base: "/",
    url: url_GetClientCertificates_595674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_595701 = ref object of OpenApiRestCall_593421
proc url_GetAccount_595703(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccount_595702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595704 = header.getOrDefault("X-Amz-Date")
  valid_595704 = validateParameter(valid_595704, JString, required = false,
                                 default = nil)
  if valid_595704 != nil:
    section.add "X-Amz-Date", valid_595704
  var valid_595705 = header.getOrDefault("X-Amz-Security-Token")
  valid_595705 = validateParameter(valid_595705, JString, required = false,
                                 default = nil)
  if valid_595705 != nil:
    section.add "X-Amz-Security-Token", valid_595705
  var valid_595706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595706 = validateParameter(valid_595706, JString, required = false,
                                 default = nil)
  if valid_595706 != nil:
    section.add "X-Amz-Content-Sha256", valid_595706
  var valid_595707 = header.getOrDefault("X-Amz-Algorithm")
  valid_595707 = validateParameter(valid_595707, JString, required = false,
                                 default = nil)
  if valid_595707 != nil:
    section.add "X-Amz-Algorithm", valid_595707
  var valid_595708 = header.getOrDefault("X-Amz-Signature")
  valid_595708 = validateParameter(valid_595708, JString, required = false,
                                 default = nil)
  if valid_595708 != nil:
    section.add "X-Amz-Signature", valid_595708
  var valid_595709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "X-Amz-SignedHeaders", valid_595709
  var valid_595710 = header.getOrDefault("X-Amz-Credential")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "X-Amz-Credential", valid_595710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595711: Call_GetAccount_595701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_595711.validator(path, query, header, formData, body)
  let scheme = call_595711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595711.url(scheme.get, call_595711.host, call_595711.base,
                         call_595711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595711, url, valid)

proc call*(call_595712: Call_GetAccount_595701): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_595712.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_595701(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_595702,
                                      base: "/", url: url_GetAccount_595703,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_595713 = ref object of OpenApiRestCall_593421
proc url_UpdateAccount_595715(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAccount_595714(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595716 = header.getOrDefault("X-Amz-Date")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "X-Amz-Date", valid_595716
  var valid_595717 = header.getOrDefault("X-Amz-Security-Token")
  valid_595717 = validateParameter(valid_595717, JString, required = false,
                                 default = nil)
  if valid_595717 != nil:
    section.add "X-Amz-Security-Token", valid_595717
  var valid_595718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595718 = validateParameter(valid_595718, JString, required = false,
                                 default = nil)
  if valid_595718 != nil:
    section.add "X-Amz-Content-Sha256", valid_595718
  var valid_595719 = header.getOrDefault("X-Amz-Algorithm")
  valid_595719 = validateParameter(valid_595719, JString, required = false,
                                 default = nil)
  if valid_595719 != nil:
    section.add "X-Amz-Algorithm", valid_595719
  var valid_595720 = header.getOrDefault("X-Amz-Signature")
  valid_595720 = validateParameter(valid_595720, JString, required = false,
                                 default = nil)
  if valid_595720 != nil:
    section.add "X-Amz-Signature", valid_595720
  var valid_595721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595721 = validateParameter(valid_595721, JString, required = false,
                                 default = nil)
  if valid_595721 != nil:
    section.add "X-Amz-SignedHeaders", valid_595721
  var valid_595722 = header.getOrDefault("X-Amz-Credential")
  valid_595722 = validateParameter(valid_595722, JString, required = false,
                                 default = nil)
  if valid_595722 != nil:
    section.add "X-Amz-Credential", valid_595722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595724: Call_UpdateAccount_595713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_595724.validator(path, query, header, formData, body)
  let scheme = call_595724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595724.url(scheme.get, call_595724.host, call_595724.base,
                         call_595724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595724, url, valid)

proc call*(call_595725: Call_UpdateAccount_595713; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_595726 = newJObject()
  if body != nil:
    body_595726 = body
  result = call_595725.call(nil, nil, nil, nil, body_595726)

var updateAccount* = Call_UpdateAccount_595713(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_595714, base: "/", url: url_UpdateAccount_595715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_595727 = ref object of OpenApiRestCall_593421
proc url_GetExport_595729(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetExport_595728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595730 = path.getOrDefault("export_type")
  valid_595730 = validateParameter(valid_595730, JString, required = true,
                                 default = nil)
  if valid_595730 != nil:
    section.add "export_type", valid_595730
  var valid_595731 = path.getOrDefault("stage_name")
  valid_595731 = validateParameter(valid_595731, JString, required = true,
                                 default = nil)
  if valid_595731 != nil:
    section.add "stage_name", valid_595731
  var valid_595732 = path.getOrDefault("restapi_id")
  valid_595732 = validateParameter(valid_595732, JString, required = true,
                                 default = nil)
  if valid_595732 != nil:
    section.add "restapi_id", valid_595732
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_595733 = query.getOrDefault("parameters.0.value")
  valid_595733 = validateParameter(valid_595733, JString, required = false,
                                 default = nil)
  if valid_595733 != nil:
    section.add "parameters.0.value", valid_595733
  var valid_595734 = query.getOrDefault("parameters.2.value")
  valid_595734 = validateParameter(valid_595734, JString, required = false,
                                 default = nil)
  if valid_595734 != nil:
    section.add "parameters.2.value", valid_595734
  var valid_595735 = query.getOrDefault("parameters.1.key")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "parameters.1.key", valid_595735
  var valid_595736 = query.getOrDefault("parameters.0.key")
  valid_595736 = validateParameter(valid_595736, JString, required = false,
                                 default = nil)
  if valid_595736 != nil:
    section.add "parameters.0.key", valid_595736
  var valid_595737 = query.getOrDefault("parameters.2.key")
  valid_595737 = validateParameter(valid_595737, JString, required = false,
                                 default = nil)
  if valid_595737 != nil:
    section.add "parameters.2.key", valid_595737
  var valid_595738 = query.getOrDefault("parameters.1.value")
  valid_595738 = validateParameter(valid_595738, JString, required = false,
                                 default = nil)
  if valid_595738 != nil:
    section.add "parameters.1.value", valid_595738
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
  var valid_595739 = header.getOrDefault("X-Amz-Date")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Date", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Security-Token")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Security-Token", valid_595740
  var valid_595741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595741 = validateParameter(valid_595741, JString, required = false,
                                 default = nil)
  if valid_595741 != nil:
    section.add "X-Amz-Content-Sha256", valid_595741
  var valid_595742 = header.getOrDefault("X-Amz-Algorithm")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "X-Amz-Algorithm", valid_595742
  var valid_595743 = header.getOrDefault("X-Amz-Signature")
  valid_595743 = validateParameter(valid_595743, JString, required = false,
                                 default = nil)
  if valid_595743 != nil:
    section.add "X-Amz-Signature", valid_595743
  var valid_595744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "X-Amz-SignedHeaders", valid_595744
  var valid_595745 = header.getOrDefault("Accept")
  valid_595745 = validateParameter(valid_595745, JString, required = false,
                                 default = nil)
  if valid_595745 != nil:
    section.add "Accept", valid_595745
  var valid_595746 = header.getOrDefault("X-Amz-Credential")
  valid_595746 = validateParameter(valid_595746, JString, required = false,
                                 default = nil)
  if valid_595746 != nil:
    section.add "X-Amz-Credential", valid_595746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595747: Call_GetExport_595727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_595747.validator(path, query, header, formData, body)
  let scheme = call_595747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595747.url(scheme.get, call_595747.host, call_595747.base,
                         call_595747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595747, url, valid)

proc call*(call_595748: Call_GetExport_595727; exportType: string; stageName: string;
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
  var path_595749 = newJObject()
  var query_595750 = newJObject()
  add(query_595750, "parameters.0.value", newJString(parameters0Value))
  add(query_595750, "parameters.2.value", newJString(parameters2Value))
  add(query_595750, "parameters.1.key", newJString(parameters1Key))
  add(query_595750, "parameters.0.key", newJString(parameters0Key))
  add(path_595749, "export_type", newJString(exportType))
  add(query_595750, "parameters.2.key", newJString(parameters2Key))
  add(path_595749, "stage_name", newJString(stageName))
  add(query_595750, "parameters.1.value", newJString(parameters1Value))
  add(path_595749, "restapi_id", newJString(restapiId))
  result = call_595748.call(path_595749, query_595750, nil, nil, nil)

var getExport* = Call_GetExport_595727(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_595728,
                                    base: "/", url: url_GetExport_595729,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_595751 = ref object of OpenApiRestCall_593421
proc url_GetGatewayResponses_595753(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetGatewayResponses_595752(path: JsonNode; query: JsonNode;
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
  var valid_595754 = path.getOrDefault("restapi_id")
  valid_595754 = validateParameter(valid_595754, JString, required = true,
                                 default = nil)
  if valid_595754 != nil:
    section.add "restapi_id", valid_595754
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_595755 = query.getOrDefault("position")
  valid_595755 = validateParameter(valid_595755, JString, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "position", valid_595755
  var valid_595756 = query.getOrDefault("limit")
  valid_595756 = validateParameter(valid_595756, JInt, required = false, default = nil)
  if valid_595756 != nil:
    section.add "limit", valid_595756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595757 = header.getOrDefault("X-Amz-Date")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-Date", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-Security-Token")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-Security-Token", valid_595758
  var valid_595759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595759 = validateParameter(valid_595759, JString, required = false,
                                 default = nil)
  if valid_595759 != nil:
    section.add "X-Amz-Content-Sha256", valid_595759
  var valid_595760 = header.getOrDefault("X-Amz-Algorithm")
  valid_595760 = validateParameter(valid_595760, JString, required = false,
                                 default = nil)
  if valid_595760 != nil:
    section.add "X-Amz-Algorithm", valid_595760
  var valid_595761 = header.getOrDefault("X-Amz-Signature")
  valid_595761 = validateParameter(valid_595761, JString, required = false,
                                 default = nil)
  if valid_595761 != nil:
    section.add "X-Amz-Signature", valid_595761
  var valid_595762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595762 = validateParameter(valid_595762, JString, required = false,
                                 default = nil)
  if valid_595762 != nil:
    section.add "X-Amz-SignedHeaders", valid_595762
  var valid_595763 = header.getOrDefault("X-Amz-Credential")
  valid_595763 = validateParameter(valid_595763, JString, required = false,
                                 default = nil)
  if valid_595763 != nil:
    section.add "X-Amz-Credential", valid_595763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595764: Call_GetGatewayResponses_595751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_595764.validator(path, query, header, formData, body)
  let scheme = call_595764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595764.url(scheme.get, call_595764.host, call_595764.base,
                         call_595764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595764, url, valid)

proc call*(call_595765: Call_GetGatewayResponses_595751; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595766 = newJObject()
  var query_595767 = newJObject()
  add(query_595767, "position", newJString(position))
  add(query_595767, "limit", newJInt(limit))
  add(path_595766, "restapi_id", newJString(restapiId))
  result = call_595765.call(path_595766, query_595767, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_595751(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_595752, base: "/",
    url: url_GetGatewayResponses_595753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_595768 = ref object of OpenApiRestCall_593421
proc url_GetModelTemplate_595770(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetModelTemplate_595769(path: JsonNode; query: JsonNode;
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
  var valid_595771 = path.getOrDefault("model_name")
  valid_595771 = validateParameter(valid_595771, JString, required = true,
                                 default = nil)
  if valid_595771 != nil:
    section.add "model_name", valid_595771
  var valid_595772 = path.getOrDefault("restapi_id")
  valid_595772 = validateParameter(valid_595772, JString, required = true,
                                 default = nil)
  if valid_595772 != nil:
    section.add "restapi_id", valid_595772
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595773 = header.getOrDefault("X-Amz-Date")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Date", valid_595773
  var valid_595774 = header.getOrDefault("X-Amz-Security-Token")
  valid_595774 = validateParameter(valid_595774, JString, required = false,
                                 default = nil)
  if valid_595774 != nil:
    section.add "X-Amz-Security-Token", valid_595774
  var valid_595775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595775 = validateParameter(valid_595775, JString, required = false,
                                 default = nil)
  if valid_595775 != nil:
    section.add "X-Amz-Content-Sha256", valid_595775
  var valid_595776 = header.getOrDefault("X-Amz-Algorithm")
  valid_595776 = validateParameter(valid_595776, JString, required = false,
                                 default = nil)
  if valid_595776 != nil:
    section.add "X-Amz-Algorithm", valid_595776
  var valid_595777 = header.getOrDefault("X-Amz-Signature")
  valid_595777 = validateParameter(valid_595777, JString, required = false,
                                 default = nil)
  if valid_595777 != nil:
    section.add "X-Amz-Signature", valid_595777
  var valid_595778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595778 = validateParameter(valid_595778, JString, required = false,
                                 default = nil)
  if valid_595778 != nil:
    section.add "X-Amz-SignedHeaders", valid_595778
  var valid_595779 = header.getOrDefault("X-Amz-Credential")
  valid_595779 = validateParameter(valid_595779, JString, required = false,
                                 default = nil)
  if valid_595779 != nil:
    section.add "X-Amz-Credential", valid_595779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595780: Call_GetModelTemplate_595768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_595780.validator(path, query, header, formData, body)
  let scheme = call_595780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595780.url(scheme.get, call_595780.host, call_595780.base,
                         call_595780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595780, url, valid)

proc call*(call_595781: Call_GetModelTemplate_595768; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_595782 = newJObject()
  add(path_595782, "model_name", newJString(modelName))
  add(path_595782, "restapi_id", newJString(restapiId))
  result = call_595781.call(path_595782, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_595768(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_595769, base: "/",
    url: url_GetModelTemplate_595770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_595783 = ref object of OpenApiRestCall_593421
proc url_GetResources_595785(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetResources_595784(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595786 = path.getOrDefault("restapi_id")
  valid_595786 = validateParameter(valid_595786, JString, required = true,
                                 default = nil)
  if valid_595786 != nil:
    section.add "restapi_id", valid_595786
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_595787 = query.getOrDefault("embed")
  valid_595787 = validateParameter(valid_595787, JArray, required = false,
                                 default = nil)
  if valid_595787 != nil:
    section.add "embed", valid_595787
  var valid_595788 = query.getOrDefault("position")
  valid_595788 = validateParameter(valid_595788, JString, required = false,
                                 default = nil)
  if valid_595788 != nil:
    section.add "position", valid_595788
  var valid_595789 = query.getOrDefault("limit")
  valid_595789 = validateParameter(valid_595789, JInt, required = false, default = nil)
  if valid_595789 != nil:
    section.add "limit", valid_595789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595790 = header.getOrDefault("X-Amz-Date")
  valid_595790 = validateParameter(valid_595790, JString, required = false,
                                 default = nil)
  if valid_595790 != nil:
    section.add "X-Amz-Date", valid_595790
  var valid_595791 = header.getOrDefault("X-Amz-Security-Token")
  valid_595791 = validateParameter(valid_595791, JString, required = false,
                                 default = nil)
  if valid_595791 != nil:
    section.add "X-Amz-Security-Token", valid_595791
  var valid_595792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595792 = validateParameter(valid_595792, JString, required = false,
                                 default = nil)
  if valid_595792 != nil:
    section.add "X-Amz-Content-Sha256", valid_595792
  var valid_595793 = header.getOrDefault("X-Amz-Algorithm")
  valid_595793 = validateParameter(valid_595793, JString, required = false,
                                 default = nil)
  if valid_595793 != nil:
    section.add "X-Amz-Algorithm", valid_595793
  var valid_595794 = header.getOrDefault("X-Amz-Signature")
  valid_595794 = validateParameter(valid_595794, JString, required = false,
                                 default = nil)
  if valid_595794 != nil:
    section.add "X-Amz-Signature", valid_595794
  var valid_595795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595795 = validateParameter(valid_595795, JString, required = false,
                                 default = nil)
  if valid_595795 != nil:
    section.add "X-Amz-SignedHeaders", valid_595795
  var valid_595796 = header.getOrDefault("X-Amz-Credential")
  valid_595796 = validateParameter(valid_595796, JString, required = false,
                                 default = nil)
  if valid_595796 != nil:
    section.add "X-Amz-Credential", valid_595796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595797: Call_GetResources_595783; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_595797.validator(path, query, header, formData, body)
  let scheme = call_595797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595797.url(scheme.get, call_595797.host, call_595797.base,
                         call_595797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595797, url, valid)

proc call*(call_595798: Call_GetResources_595783; restapiId: string;
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
  var path_595799 = newJObject()
  var query_595800 = newJObject()
  if embed != nil:
    query_595800.add "embed", embed
  add(query_595800, "position", newJString(position))
  add(query_595800, "limit", newJInt(limit))
  add(path_595799, "restapi_id", newJString(restapiId))
  result = call_595798.call(path_595799, query_595800, nil, nil, nil)

var getResources* = Call_GetResources_595783(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_595784,
    base: "/", url: url_GetResources_595785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_595801 = ref object of OpenApiRestCall_593421
proc url_GetSdk_595803(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetSdk_595802(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595804 = path.getOrDefault("sdk_type")
  valid_595804 = validateParameter(valid_595804, JString, required = true,
                                 default = nil)
  if valid_595804 != nil:
    section.add "sdk_type", valid_595804
  var valid_595805 = path.getOrDefault("stage_name")
  valid_595805 = validateParameter(valid_595805, JString, required = true,
                                 default = nil)
  if valid_595805 != nil:
    section.add "stage_name", valid_595805
  var valid_595806 = path.getOrDefault("restapi_id")
  valid_595806 = validateParameter(valid_595806, JString, required = true,
                                 default = nil)
  if valid_595806 != nil:
    section.add "restapi_id", valid_595806
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_595807 = query.getOrDefault("parameters.0.value")
  valid_595807 = validateParameter(valid_595807, JString, required = false,
                                 default = nil)
  if valid_595807 != nil:
    section.add "parameters.0.value", valid_595807
  var valid_595808 = query.getOrDefault("parameters.2.value")
  valid_595808 = validateParameter(valid_595808, JString, required = false,
                                 default = nil)
  if valid_595808 != nil:
    section.add "parameters.2.value", valid_595808
  var valid_595809 = query.getOrDefault("parameters.1.key")
  valid_595809 = validateParameter(valid_595809, JString, required = false,
                                 default = nil)
  if valid_595809 != nil:
    section.add "parameters.1.key", valid_595809
  var valid_595810 = query.getOrDefault("parameters.0.key")
  valid_595810 = validateParameter(valid_595810, JString, required = false,
                                 default = nil)
  if valid_595810 != nil:
    section.add "parameters.0.key", valid_595810
  var valid_595811 = query.getOrDefault("parameters.2.key")
  valid_595811 = validateParameter(valid_595811, JString, required = false,
                                 default = nil)
  if valid_595811 != nil:
    section.add "parameters.2.key", valid_595811
  var valid_595812 = query.getOrDefault("parameters.1.value")
  valid_595812 = validateParameter(valid_595812, JString, required = false,
                                 default = nil)
  if valid_595812 != nil:
    section.add "parameters.1.value", valid_595812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595813 = header.getOrDefault("X-Amz-Date")
  valid_595813 = validateParameter(valid_595813, JString, required = false,
                                 default = nil)
  if valid_595813 != nil:
    section.add "X-Amz-Date", valid_595813
  var valid_595814 = header.getOrDefault("X-Amz-Security-Token")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Security-Token", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Content-Sha256", valid_595815
  var valid_595816 = header.getOrDefault("X-Amz-Algorithm")
  valid_595816 = validateParameter(valid_595816, JString, required = false,
                                 default = nil)
  if valid_595816 != nil:
    section.add "X-Amz-Algorithm", valid_595816
  var valid_595817 = header.getOrDefault("X-Amz-Signature")
  valid_595817 = validateParameter(valid_595817, JString, required = false,
                                 default = nil)
  if valid_595817 != nil:
    section.add "X-Amz-Signature", valid_595817
  var valid_595818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595818 = validateParameter(valid_595818, JString, required = false,
                                 default = nil)
  if valid_595818 != nil:
    section.add "X-Amz-SignedHeaders", valid_595818
  var valid_595819 = header.getOrDefault("X-Amz-Credential")
  valid_595819 = validateParameter(valid_595819, JString, required = false,
                                 default = nil)
  if valid_595819 != nil:
    section.add "X-Amz-Credential", valid_595819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595820: Call_GetSdk_595801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_595820.validator(path, query, header, formData, body)
  let scheme = call_595820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595820.url(scheme.get, call_595820.host, call_595820.base,
                         call_595820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595820, url, valid)

proc call*(call_595821: Call_GetSdk_595801; sdkType: string; stageName: string;
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
  var path_595822 = newJObject()
  var query_595823 = newJObject()
  add(path_595822, "sdk_type", newJString(sdkType))
  add(query_595823, "parameters.0.value", newJString(parameters0Value))
  add(query_595823, "parameters.2.value", newJString(parameters2Value))
  add(query_595823, "parameters.1.key", newJString(parameters1Key))
  add(query_595823, "parameters.0.key", newJString(parameters0Key))
  add(query_595823, "parameters.2.key", newJString(parameters2Key))
  add(path_595822, "stage_name", newJString(stageName))
  add(query_595823, "parameters.1.value", newJString(parameters1Value))
  add(path_595822, "restapi_id", newJString(restapiId))
  result = call_595821.call(path_595822, query_595823, nil, nil, nil)

var getSdk* = Call_GetSdk_595801(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_595802, base: "/",
                              url: url_GetSdk_595803,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_595824 = ref object of OpenApiRestCall_593421
proc url_GetSdkType_595826(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetSdkType_595825(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_595827 = path.getOrDefault("sdktype_id")
  valid_595827 = validateParameter(valid_595827, JString, required = true,
                                 default = nil)
  if valid_595827 != nil:
    section.add "sdktype_id", valid_595827
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595828 = header.getOrDefault("X-Amz-Date")
  valid_595828 = validateParameter(valid_595828, JString, required = false,
                                 default = nil)
  if valid_595828 != nil:
    section.add "X-Amz-Date", valid_595828
  var valid_595829 = header.getOrDefault("X-Amz-Security-Token")
  valid_595829 = validateParameter(valid_595829, JString, required = false,
                                 default = nil)
  if valid_595829 != nil:
    section.add "X-Amz-Security-Token", valid_595829
  var valid_595830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595830 = validateParameter(valid_595830, JString, required = false,
                                 default = nil)
  if valid_595830 != nil:
    section.add "X-Amz-Content-Sha256", valid_595830
  var valid_595831 = header.getOrDefault("X-Amz-Algorithm")
  valid_595831 = validateParameter(valid_595831, JString, required = false,
                                 default = nil)
  if valid_595831 != nil:
    section.add "X-Amz-Algorithm", valid_595831
  var valid_595832 = header.getOrDefault("X-Amz-Signature")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "X-Amz-Signature", valid_595832
  var valid_595833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595833 = validateParameter(valid_595833, JString, required = false,
                                 default = nil)
  if valid_595833 != nil:
    section.add "X-Amz-SignedHeaders", valid_595833
  var valid_595834 = header.getOrDefault("X-Amz-Credential")
  valid_595834 = validateParameter(valid_595834, JString, required = false,
                                 default = nil)
  if valid_595834 != nil:
    section.add "X-Amz-Credential", valid_595834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595835: Call_GetSdkType_595824; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595835.validator(path, query, header, formData, body)
  let scheme = call_595835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595835.url(scheme.get, call_595835.host, call_595835.base,
                         call_595835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595835, url, valid)

proc call*(call_595836: Call_GetSdkType_595824; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_595837 = newJObject()
  add(path_595837, "sdktype_id", newJString(sdktypeId))
  result = call_595836.call(path_595837, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_595824(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_595825,
                                      base: "/", url: url_GetSdkType_595826,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_595838 = ref object of OpenApiRestCall_593421
proc url_GetSdkTypes_595840(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSdkTypes_595839(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595841 = query.getOrDefault("position")
  valid_595841 = validateParameter(valid_595841, JString, required = false,
                                 default = nil)
  if valid_595841 != nil:
    section.add "position", valid_595841
  var valid_595842 = query.getOrDefault("limit")
  valid_595842 = validateParameter(valid_595842, JInt, required = false, default = nil)
  if valid_595842 != nil:
    section.add "limit", valid_595842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595843 = header.getOrDefault("X-Amz-Date")
  valid_595843 = validateParameter(valid_595843, JString, required = false,
                                 default = nil)
  if valid_595843 != nil:
    section.add "X-Amz-Date", valid_595843
  var valid_595844 = header.getOrDefault("X-Amz-Security-Token")
  valid_595844 = validateParameter(valid_595844, JString, required = false,
                                 default = nil)
  if valid_595844 != nil:
    section.add "X-Amz-Security-Token", valid_595844
  var valid_595845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595845 = validateParameter(valid_595845, JString, required = false,
                                 default = nil)
  if valid_595845 != nil:
    section.add "X-Amz-Content-Sha256", valid_595845
  var valid_595846 = header.getOrDefault("X-Amz-Algorithm")
  valid_595846 = validateParameter(valid_595846, JString, required = false,
                                 default = nil)
  if valid_595846 != nil:
    section.add "X-Amz-Algorithm", valid_595846
  var valid_595847 = header.getOrDefault("X-Amz-Signature")
  valid_595847 = validateParameter(valid_595847, JString, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "X-Amz-Signature", valid_595847
  var valid_595848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-SignedHeaders", valid_595848
  var valid_595849 = header.getOrDefault("X-Amz-Credential")
  valid_595849 = validateParameter(valid_595849, JString, required = false,
                                 default = nil)
  if valid_595849 != nil:
    section.add "X-Amz-Credential", valid_595849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595850: Call_GetSdkTypes_595838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595850.validator(path, query, header, formData, body)
  let scheme = call_595850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595850.url(scheme.get, call_595850.host, call_595850.base,
                         call_595850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595850, url, valid)

proc call*(call_595851: Call_GetSdkTypes_595838; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_595852 = newJObject()
  add(query_595852, "position", newJString(position))
  add(query_595852, "limit", newJInt(limit))
  result = call_595851.call(nil, query_595852, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_595838(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_595839,
                                        base: "/", url: url_GetSdkTypes_595840,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_595870 = ref object of OpenApiRestCall_593421
proc url_TagResource_595872(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_595871(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595873 = path.getOrDefault("resource_arn")
  valid_595873 = validateParameter(valid_595873, JString, required = true,
                                 default = nil)
  if valid_595873 != nil:
    section.add "resource_arn", valid_595873
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595874 = header.getOrDefault("X-Amz-Date")
  valid_595874 = validateParameter(valid_595874, JString, required = false,
                                 default = nil)
  if valid_595874 != nil:
    section.add "X-Amz-Date", valid_595874
  var valid_595875 = header.getOrDefault("X-Amz-Security-Token")
  valid_595875 = validateParameter(valid_595875, JString, required = false,
                                 default = nil)
  if valid_595875 != nil:
    section.add "X-Amz-Security-Token", valid_595875
  var valid_595876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595876 = validateParameter(valid_595876, JString, required = false,
                                 default = nil)
  if valid_595876 != nil:
    section.add "X-Amz-Content-Sha256", valid_595876
  var valid_595877 = header.getOrDefault("X-Amz-Algorithm")
  valid_595877 = validateParameter(valid_595877, JString, required = false,
                                 default = nil)
  if valid_595877 != nil:
    section.add "X-Amz-Algorithm", valid_595877
  var valid_595878 = header.getOrDefault("X-Amz-Signature")
  valid_595878 = validateParameter(valid_595878, JString, required = false,
                                 default = nil)
  if valid_595878 != nil:
    section.add "X-Amz-Signature", valid_595878
  var valid_595879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595879 = validateParameter(valid_595879, JString, required = false,
                                 default = nil)
  if valid_595879 != nil:
    section.add "X-Amz-SignedHeaders", valid_595879
  var valid_595880 = header.getOrDefault("X-Amz-Credential")
  valid_595880 = validateParameter(valid_595880, JString, required = false,
                                 default = nil)
  if valid_595880 != nil:
    section.add "X-Amz-Credential", valid_595880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595882: Call_TagResource_595870; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_595882.validator(path, query, header, formData, body)
  let scheme = call_595882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595882.url(scheme.get, call_595882.host, call_595882.base,
                         call_595882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595882, url, valid)

proc call*(call_595883: Call_TagResource_595870; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_595884 = newJObject()
  var body_595885 = newJObject()
  add(path_595884, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_595885 = body
  result = call_595883.call(path_595884, nil, nil, nil, body_595885)

var tagResource* = Call_TagResource_595870(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_595871,
                                        base: "/", url: url_TagResource_595872,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_595853 = ref object of OpenApiRestCall_593421
proc url_GetTags_595855(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetTags_595854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595856 = path.getOrDefault("resource_arn")
  valid_595856 = validateParameter(valid_595856, JString, required = true,
                                 default = nil)
  if valid_595856 != nil:
    section.add "resource_arn", valid_595856
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_595857 = query.getOrDefault("position")
  valid_595857 = validateParameter(valid_595857, JString, required = false,
                                 default = nil)
  if valid_595857 != nil:
    section.add "position", valid_595857
  var valid_595858 = query.getOrDefault("limit")
  valid_595858 = validateParameter(valid_595858, JInt, required = false, default = nil)
  if valid_595858 != nil:
    section.add "limit", valid_595858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595859 = header.getOrDefault("X-Amz-Date")
  valid_595859 = validateParameter(valid_595859, JString, required = false,
                                 default = nil)
  if valid_595859 != nil:
    section.add "X-Amz-Date", valid_595859
  var valid_595860 = header.getOrDefault("X-Amz-Security-Token")
  valid_595860 = validateParameter(valid_595860, JString, required = false,
                                 default = nil)
  if valid_595860 != nil:
    section.add "X-Amz-Security-Token", valid_595860
  var valid_595861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595861 = validateParameter(valid_595861, JString, required = false,
                                 default = nil)
  if valid_595861 != nil:
    section.add "X-Amz-Content-Sha256", valid_595861
  var valid_595862 = header.getOrDefault("X-Amz-Algorithm")
  valid_595862 = validateParameter(valid_595862, JString, required = false,
                                 default = nil)
  if valid_595862 != nil:
    section.add "X-Amz-Algorithm", valid_595862
  var valid_595863 = header.getOrDefault("X-Amz-Signature")
  valid_595863 = validateParameter(valid_595863, JString, required = false,
                                 default = nil)
  if valid_595863 != nil:
    section.add "X-Amz-Signature", valid_595863
  var valid_595864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595864 = validateParameter(valid_595864, JString, required = false,
                                 default = nil)
  if valid_595864 != nil:
    section.add "X-Amz-SignedHeaders", valid_595864
  var valid_595865 = header.getOrDefault("X-Amz-Credential")
  valid_595865 = validateParameter(valid_595865, JString, required = false,
                                 default = nil)
  if valid_595865 != nil:
    section.add "X-Amz-Credential", valid_595865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595866: Call_GetTags_595853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_595866.validator(path, query, header, formData, body)
  let scheme = call_595866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595866.url(scheme.get, call_595866.host, call_595866.base,
                         call_595866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595866, url, valid)

proc call*(call_595867: Call_GetTags_595853; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_595868 = newJObject()
  var query_595869 = newJObject()
  add(path_595868, "resource_arn", newJString(resourceArn))
  add(query_595869, "position", newJString(position))
  add(query_595869, "limit", newJInt(limit))
  result = call_595867.call(path_595868, query_595869, nil, nil, nil)

var getTags* = Call_GetTags_595853(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_595854, base: "/",
                                url: url_GetTags_595855,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_595886 = ref object of OpenApiRestCall_593421
proc url_GetUsage_595888(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetUsage_595887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595889 = path.getOrDefault("usageplanId")
  valid_595889 = validateParameter(valid_595889, JString, required = true,
                                 default = nil)
  if valid_595889 != nil:
    section.add "usageplanId", valid_595889
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
  var valid_595890 = query.getOrDefault("endDate")
  valid_595890 = validateParameter(valid_595890, JString, required = true,
                                 default = nil)
  if valid_595890 != nil:
    section.add "endDate", valid_595890
  var valid_595891 = query.getOrDefault("startDate")
  valid_595891 = validateParameter(valid_595891, JString, required = true,
                                 default = nil)
  if valid_595891 != nil:
    section.add "startDate", valid_595891
  var valid_595892 = query.getOrDefault("keyId")
  valid_595892 = validateParameter(valid_595892, JString, required = false,
                                 default = nil)
  if valid_595892 != nil:
    section.add "keyId", valid_595892
  var valid_595893 = query.getOrDefault("position")
  valid_595893 = validateParameter(valid_595893, JString, required = false,
                                 default = nil)
  if valid_595893 != nil:
    section.add "position", valid_595893
  var valid_595894 = query.getOrDefault("limit")
  valid_595894 = validateParameter(valid_595894, JInt, required = false, default = nil)
  if valid_595894 != nil:
    section.add "limit", valid_595894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595895 = header.getOrDefault("X-Amz-Date")
  valid_595895 = validateParameter(valid_595895, JString, required = false,
                                 default = nil)
  if valid_595895 != nil:
    section.add "X-Amz-Date", valid_595895
  var valid_595896 = header.getOrDefault("X-Amz-Security-Token")
  valid_595896 = validateParameter(valid_595896, JString, required = false,
                                 default = nil)
  if valid_595896 != nil:
    section.add "X-Amz-Security-Token", valid_595896
  var valid_595897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595897 = validateParameter(valid_595897, JString, required = false,
                                 default = nil)
  if valid_595897 != nil:
    section.add "X-Amz-Content-Sha256", valid_595897
  var valid_595898 = header.getOrDefault("X-Amz-Algorithm")
  valid_595898 = validateParameter(valid_595898, JString, required = false,
                                 default = nil)
  if valid_595898 != nil:
    section.add "X-Amz-Algorithm", valid_595898
  var valid_595899 = header.getOrDefault("X-Amz-Signature")
  valid_595899 = validateParameter(valid_595899, JString, required = false,
                                 default = nil)
  if valid_595899 != nil:
    section.add "X-Amz-Signature", valid_595899
  var valid_595900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595900 = validateParameter(valid_595900, JString, required = false,
                                 default = nil)
  if valid_595900 != nil:
    section.add "X-Amz-SignedHeaders", valid_595900
  var valid_595901 = header.getOrDefault("X-Amz-Credential")
  valid_595901 = validateParameter(valid_595901, JString, required = false,
                                 default = nil)
  if valid_595901 != nil:
    section.add "X-Amz-Credential", valid_595901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595902: Call_GetUsage_595886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_595902.validator(path, query, header, formData, body)
  let scheme = call_595902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595902.url(scheme.get, call_595902.host, call_595902.base,
                         call_595902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595902, url, valid)

proc call*(call_595903: Call_GetUsage_595886; endDate: string; startDate: string;
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
  var path_595904 = newJObject()
  var query_595905 = newJObject()
  add(query_595905, "endDate", newJString(endDate))
  add(query_595905, "startDate", newJString(startDate))
  add(path_595904, "usageplanId", newJString(usageplanId))
  add(query_595905, "keyId", newJString(keyId))
  add(query_595905, "position", newJString(position))
  add(query_595905, "limit", newJInt(limit))
  result = call_595903.call(path_595904, query_595905, nil, nil, nil)

var getUsage* = Call_GetUsage_595886(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_595887, base: "/",
                                  url: url_GetUsage_595888,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_595906 = ref object of OpenApiRestCall_593421
proc url_ImportApiKeys_595908(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportApiKeys_595907(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595909 = query.getOrDefault("mode")
  valid_595909 = validateParameter(valid_595909, JString, required = true,
                                 default = newJString("import"))
  if valid_595909 != nil:
    section.add "mode", valid_595909
  var valid_595910 = query.getOrDefault("failonwarnings")
  valid_595910 = validateParameter(valid_595910, JBool, required = false, default = nil)
  if valid_595910 != nil:
    section.add "failonwarnings", valid_595910
  var valid_595911 = query.getOrDefault("format")
  valid_595911 = validateParameter(valid_595911, JString, required = true,
                                 default = newJString("csv"))
  if valid_595911 != nil:
    section.add "format", valid_595911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595912 = header.getOrDefault("X-Amz-Date")
  valid_595912 = validateParameter(valid_595912, JString, required = false,
                                 default = nil)
  if valid_595912 != nil:
    section.add "X-Amz-Date", valid_595912
  var valid_595913 = header.getOrDefault("X-Amz-Security-Token")
  valid_595913 = validateParameter(valid_595913, JString, required = false,
                                 default = nil)
  if valid_595913 != nil:
    section.add "X-Amz-Security-Token", valid_595913
  var valid_595914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595914 = validateParameter(valid_595914, JString, required = false,
                                 default = nil)
  if valid_595914 != nil:
    section.add "X-Amz-Content-Sha256", valid_595914
  var valid_595915 = header.getOrDefault("X-Amz-Algorithm")
  valid_595915 = validateParameter(valid_595915, JString, required = false,
                                 default = nil)
  if valid_595915 != nil:
    section.add "X-Amz-Algorithm", valid_595915
  var valid_595916 = header.getOrDefault("X-Amz-Signature")
  valid_595916 = validateParameter(valid_595916, JString, required = false,
                                 default = nil)
  if valid_595916 != nil:
    section.add "X-Amz-Signature", valid_595916
  var valid_595917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595917 = validateParameter(valid_595917, JString, required = false,
                                 default = nil)
  if valid_595917 != nil:
    section.add "X-Amz-SignedHeaders", valid_595917
  var valid_595918 = header.getOrDefault("X-Amz-Credential")
  valid_595918 = validateParameter(valid_595918, JString, required = false,
                                 default = nil)
  if valid_595918 != nil:
    section.add "X-Amz-Credential", valid_595918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595920: Call_ImportApiKeys_595906; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_595920.validator(path, query, header, formData, body)
  let scheme = call_595920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595920.url(scheme.get, call_595920.host, call_595920.base,
                         call_595920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595920, url, valid)

proc call*(call_595921: Call_ImportApiKeys_595906; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_595922 = newJObject()
  var body_595923 = newJObject()
  add(query_595922, "mode", newJString(mode))
  add(query_595922, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_595923 = body
  add(query_595922, "format", newJString(format))
  result = call_595921.call(nil, query_595922, nil, nil, body_595923)

var importApiKeys* = Call_ImportApiKeys_595906(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_595907,
    base: "/", url: url_ImportApiKeys_595908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_595924 = ref object of OpenApiRestCall_593421
proc url_ImportRestApi_595926(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportRestApi_595925(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595927 = query.getOrDefault("parameters.0.value")
  valid_595927 = validateParameter(valid_595927, JString, required = false,
                                 default = nil)
  if valid_595927 != nil:
    section.add "parameters.0.value", valid_595927
  var valid_595928 = query.getOrDefault("parameters.2.value")
  valid_595928 = validateParameter(valid_595928, JString, required = false,
                                 default = nil)
  if valid_595928 != nil:
    section.add "parameters.2.value", valid_595928
  var valid_595929 = query.getOrDefault("parameters.1.key")
  valid_595929 = validateParameter(valid_595929, JString, required = false,
                                 default = nil)
  if valid_595929 != nil:
    section.add "parameters.1.key", valid_595929
  var valid_595930 = query.getOrDefault("parameters.0.key")
  valid_595930 = validateParameter(valid_595930, JString, required = false,
                                 default = nil)
  if valid_595930 != nil:
    section.add "parameters.0.key", valid_595930
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_595931 = query.getOrDefault("mode")
  valid_595931 = validateParameter(valid_595931, JString, required = true,
                                 default = newJString("import"))
  if valid_595931 != nil:
    section.add "mode", valid_595931
  var valid_595932 = query.getOrDefault("parameters.2.key")
  valid_595932 = validateParameter(valid_595932, JString, required = false,
                                 default = nil)
  if valid_595932 != nil:
    section.add "parameters.2.key", valid_595932
  var valid_595933 = query.getOrDefault("failonwarnings")
  valid_595933 = validateParameter(valid_595933, JBool, required = false, default = nil)
  if valid_595933 != nil:
    section.add "failonwarnings", valid_595933
  var valid_595934 = query.getOrDefault("parameters.1.value")
  valid_595934 = validateParameter(valid_595934, JString, required = false,
                                 default = nil)
  if valid_595934 != nil:
    section.add "parameters.1.value", valid_595934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595935 = header.getOrDefault("X-Amz-Date")
  valid_595935 = validateParameter(valid_595935, JString, required = false,
                                 default = nil)
  if valid_595935 != nil:
    section.add "X-Amz-Date", valid_595935
  var valid_595936 = header.getOrDefault("X-Amz-Security-Token")
  valid_595936 = validateParameter(valid_595936, JString, required = false,
                                 default = nil)
  if valid_595936 != nil:
    section.add "X-Amz-Security-Token", valid_595936
  var valid_595937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595937 = validateParameter(valid_595937, JString, required = false,
                                 default = nil)
  if valid_595937 != nil:
    section.add "X-Amz-Content-Sha256", valid_595937
  var valid_595938 = header.getOrDefault("X-Amz-Algorithm")
  valid_595938 = validateParameter(valid_595938, JString, required = false,
                                 default = nil)
  if valid_595938 != nil:
    section.add "X-Amz-Algorithm", valid_595938
  var valid_595939 = header.getOrDefault("X-Amz-Signature")
  valid_595939 = validateParameter(valid_595939, JString, required = false,
                                 default = nil)
  if valid_595939 != nil:
    section.add "X-Amz-Signature", valid_595939
  var valid_595940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595940 = validateParameter(valid_595940, JString, required = false,
                                 default = nil)
  if valid_595940 != nil:
    section.add "X-Amz-SignedHeaders", valid_595940
  var valid_595941 = header.getOrDefault("X-Amz-Credential")
  valid_595941 = validateParameter(valid_595941, JString, required = false,
                                 default = nil)
  if valid_595941 != nil:
    section.add "X-Amz-Credential", valid_595941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595943: Call_ImportRestApi_595924; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_595943.validator(path, query, header, formData, body)
  let scheme = call_595943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595943.url(scheme.get, call_595943.host, call_595943.base,
                         call_595943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595943, url, valid)

proc call*(call_595944: Call_ImportRestApi_595924; body: JsonNode;
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
  var query_595945 = newJObject()
  var body_595946 = newJObject()
  add(query_595945, "parameters.0.value", newJString(parameters0Value))
  add(query_595945, "parameters.2.value", newJString(parameters2Value))
  add(query_595945, "parameters.1.key", newJString(parameters1Key))
  add(query_595945, "parameters.0.key", newJString(parameters0Key))
  add(query_595945, "mode", newJString(mode))
  add(query_595945, "parameters.2.key", newJString(parameters2Key))
  add(query_595945, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_595946 = body
  add(query_595945, "parameters.1.value", newJString(parameters1Value))
  result = call_595944.call(nil, query_595945, nil, nil, body_595946)

var importRestApi* = Call_ImportRestApi_595924(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_595925,
    base: "/", url: url_ImportRestApi_595926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_595947 = ref object of OpenApiRestCall_593421
proc url_UntagResource_595949(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_595948(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595950 = path.getOrDefault("resource_arn")
  valid_595950 = validateParameter(valid_595950, JString, required = true,
                                 default = nil)
  if valid_595950 != nil:
    section.add "resource_arn", valid_595950
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_595951 = query.getOrDefault("tagKeys")
  valid_595951 = validateParameter(valid_595951, JArray, required = true, default = nil)
  if valid_595951 != nil:
    section.add "tagKeys", valid_595951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595952 = header.getOrDefault("X-Amz-Date")
  valid_595952 = validateParameter(valid_595952, JString, required = false,
                                 default = nil)
  if valid_595952 != nil:
    section.add "X-Amz-Date", valid_595952
  var valid_595953 = header.getOrDefault("X-Amz-Security-Token")
  valid_595953 = validateParameter(valid_595953, JString, required = false,
                                 default = nil)
  if valid_595953 != nil:
    section.add "X-Amz-Security-Token", valid_595953
  var valid_595954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595954 = validateParameter(valid_595954, JString, required = false,
                                 default = nil)
  if valid_595954 != nil:
    section.add "X-Amz-Content-Sha256", valid_595954
  var valid_595955 = header.getOrDefault("X-Amz-Algorithm")
  valid_595955 = validateParameter(valid_595955, JString, required = false,
                                 default = nil)
  if valid_595955 != nil:
    section.add "X-Amz-Algorithm", valid_595955
  var valid_595956 = header.getOrDefault("X-Amz-Signature")
  valid_595956 = validateParameter(valid_595956, JString, required = false,
                                 default = nil)
  if valid_595956 != nil:
    section.add "X-Amz-Signature", valid_595956
  var valid_595957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595957 = validateParameter(valid_595957, JString, required = false,
                                 default = nil)
  if valid_595957 != nil:
    section.add "X-Amz-SignedHeaders", valid_595957
  var valid_595958 = header.getOrDefault("X-Amz-Credential")
  valid_595958 = validateParameter(valid_595958, JString, required = false,
                                 default = nil)
  if valid_595958 != nil:
    section.add "X-Amz-Credential", valid_595958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595959: Call_UntagResource_595947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_595959.validator(path, query, header, formData, body)
  let scheme = call_595959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595959.url(scheme.get, call_595959.host, call_595959.base,
                         call_595959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595959, url, valid)

proc call*(call_595960: Call_UntagResource_595947; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_595961 = newJObject()
  var query_595962 = newJObject()
  add(path_595961, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_595962.add "tagKeys", tagKeys
  result = call_595960.call(path_595961, query_595962, nil, nil, nil)

var untagResource* = Call_UntagResource_595947(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_595948,
    base: "/", url: url_UntagResource_595949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_595963 = ref object of OpenApiRestCall_593421
proc url_UpdateUsage_595965(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateUsage_595964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595966 = path.getOrDefault("keyId")
  valid_595966 = validateParameter(valid_595966, JString, required = true,
                                 default = nil)
  if valid_595966 != nil:
    section.add "keyId", valid_595966
  var valid_595967 = path.getOrDefault("usageplanId")
  valid_595967 = validateParameter(valid_595967, JString, required = true,
                                 default = nil)
  if valid_595967 != nil:
    section.add "usageplanId", valid_595967
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595968 = header.getOrDefault("X-Amz-Date")
  valid_595968 = validateParameter(valid_595968, JString, required = false,
                                 default = nil)
  if valid_595968 != nil:
    section.add "X-Amz-Date", valid_595968
  var valid_595969 = header.getOrDefault("X-Amz-Security-Token")
  valid_595969 = validateParameter(valid_595969, JString, required = false,
                                 default = nil)
  if valid_595969 != nil:
    section.add "X-Amz-Security-Token", valid_595969
  var valid_595970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595970 = validateParameter(valid_595970, JString, required = false,
                                 default = nil)
  if valid_595970 != nil:
    section.add "X-Amz-Content-Sha256", valid_595970
  var valid_595971 = header.getOrDefault("X-Amz-Algorithm")
  valid_595971 = validateParameter(valid_595971, JString, required = false,
                                 default = nil)
  if valid_595971 != nil:
    section.add "X-Amz-Algorithm", valid_595971
  var valid_595972 = header.getOrDefault("X-Amz-Signature")
  valid_595972 = validateParameter(valid_595972, JString, required = false,
                                 default = nil)
  if valid_595972 != nil:
    section.add "X-Amz-Signature", valid_595972
  var valid_595973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595973 = validateParameter(valid_595973, JString, required = false,
                                 default = nil)
  if valid_595973 != nil:
    section.add "X-Amz-SignedHeaders", valid_595973
  var valid_595974 = header.getOrDefault("X-Amz-Credential")
  valid_595974 = validateParameter(valid_595974, JString, required = false,
                                 default = nil)
  if valid_595974 != nil:
    section.add "X-Amz-Credential", valid_595974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595976: Call_UpdateUsage_595963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_595976.validator(path, query, header, formData, body)
  let scheme = call_595976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595976.url(scheme.get, call_595976.host, call_595976.base,
                         call_595976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595976, url, valid)

proc call*(call_595977: Call_UpdateUsage_595963; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_595978 = newJObject()
  var body_595979 = newJObject()
  add(path_595978, "keyId", newJString(keyId))
  add(path_595978, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_595979 = body
  result = call_595977.call(path_595978, nil, nil, nil, body_595979)

var updateUsage* = Call_UpdateUsage_595963(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_595964,
                                        base: "/", url: url_UpdateUsage_595965,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
