
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_592947 = ref object of OpenApiRestCall_592348
proc url_CreateApiKey_592949(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApiKey_592948(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592950 = header.getOrDefault("X-Amz-Signature")
  valid_592950 = validateParameter(valid_592950, JString, required = false,
                                 default = nil)
  if valid_592950 != nil:
    section.add "X-Amz-Signature", valid_592950
  var valid_592951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592951 = validateParameter(valid_592951, JString, required = false,
                                 default = nil)
  if valid_592951 != nil:
    section.add "X-Amz-Content-Sha256", valid_592951
  var valid_592952 = header.getOrDefault("X-Amz-Date")
  valid_592952 = validateParameter(valid_592952, JString, required = false,
                                 default = nil)
  if valid_592952 != nil:
    section.add "X-Amz-Date", valid_592952
  var valid_592953 = header.getOrDefault("X-Amz-Credential")
  valid_592953 = validateParameter(valid_592953, JString, required = false,
                                 default = nil)
  if valid_592953 != nil:
    section.add "X-Amz-Credential", valid_592953
  var valid_592954 = header.getOrDefault("X-Amz-Security-Token")
  valid_592954 = validateParameter(valid_592954, JString, required = false,
                                 default = nil)
  if valid_592954 != nil:
    section.add "X-Amz-Security-Token", valid_592954
  var valid_592955 = header.getOrDefault("X-Amz-Algorithm")
  valid_592955 = validateParameter(valid_592955, JString, required = false,
                                 default = nil)
  if valid_592955 != nil:
    section.add "X-Amz-Algorithm", valid_592955
  var valid_592956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592956 = validateParameter(valid_592956, JString, required = false,
                                 default = nil)
  if valid_592956 != nil:
    section.add "X-Amz-SignedHeaders", valid_592956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592958: Call_CreateApiKey_592947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_592958.validator(path, query, header, formData, body)
  let scheme = call_592958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592958.url(scheme.get, call_592958.host, call_592958.base,
                         call_592958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592958, url, valid)

proc call*(call_592959: Call_CreateApiKey_592947; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_592960 = newJObject()
  if body != nil:
    body_592960 = body
  result = call_592959.call(nil, nil, nil, nil, body_592960)

var createApiKey* = Call_CreateApiKey_592947(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_592948, base: "/", url: url_CreateApiKey_592949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_592687 = ref object of OpenApiRestCall_592348
proc url_GetApiKeys_592689(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApiKeys_592688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592801 = query.getOrDefault("name")
  valid_592801 = validateParameter(valid_592801, JString, required = false,
                                 default = nil)
  if valid_592801 != nil:
    section.add "name", valid_592801
  var valid_592802 = query.getOrDefault("limit")
  valid_592802 = validateParameter(valid_592802, JInt, required = false, default = nil)
  if valid_592802 != nil:
    section.add "limit", valid_592802
  var valid_592803 = query.getOrDefault("position")
  valid_592803 = validateParameter(valid_592803, JString, required = false,
                                 default = nil)
  if valid_592803 != nil:
    section.add "position", valid_592803
  var valid_592804 = query.getOrDefault("includeValues")
  valid_592804 = validateParameter(valid_592804, JBool, required = false, default = nil)
  if valid_592804 != nil:
    section.add "includeValues", valid_592804
  var valid_592805 = query.getOrDefault("customerId")
  valid_592805 = validateParameter(valid_592805, JString, required = false,
                                 default = nil)
  if valid_592805 != nil:
    section.add "customerId", valid_592805
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592806 = header.getOrDefault("X-Amz-Signature")
  valid_592806 = validateParameter(valid_592806, JString, required = false,
                                 default = nil)
  if valid_592806 != nil:
    section.add "X-Amz-Signature", valid_592806
  var valid_592807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592807 = validateParameter(valid_592807, JString, required = false,
                                 default = nil)
  if valid_592807 != nil:
    section.add "X-Amz-Content-Sha256", valid_592807
  var valid_592808 = header.getOrDefault("X-Amz-Date")
  valid_592808 = validateParameter(valid_592808, JString, required = false,
                                 default = nil)
  if valid_592808 != nil:
    section.add "X-Amz-Date", valid_592808
  var valid_592809 = header.getOrDefault("X-Amz-Credential")
  valid_592809 = validateParameter(valid_592809, JString, required = false,
                                 default = nil)
  if valid_592809 != nil:
    section.add "X-Amz-Credential", valid_592809
  var valid_592810 = header.getOrDefault("X-Amz-Security-Token")
  valid_592810 = validateParameter(valid_592810, JString, required = false,
                                 default = nil)
  if valid_592810 != nil:
    section.add "X-Amz-Security-Token", valid_592810
  var valid_592811 = header.getOrDefault("X-Amz-Algorithm")
  valid_592811 = validateParameter(valid_592811, JString, required = false,
                                 default = nil)
  if valid_592811 != nil:
    section.add "X-Amz-Algorithm", valid_592811
  var valid_592812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592812 = validateParameter(valid_592812, JString, required = false,
                                 default = nil)
  if valid_592812 != nil:
    section.add "X-Amz-SignedHeaders", valid_592812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592835: Call_GetApiKeys_592687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_592835.validator(path, query, header, formData, body)
  let scheme = call_592835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592835.url(scheme.get, call_592835.host, call_592835.base,
                         call_592835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592835, url, valid)

proc call*(call_592906: Call_GetApiKeys_592687; name: string = ""; limit: int = 0;
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
  var query_592907 = newJObject()
  add(query_592907, "name", newJString(name))
  add(query_592907, "limit", newJInt(limit))
  add(query_592907, "position", newJString(position))
  add(query_592907, "includeValues", newJBool(includeValues))
  add(query_592907, "customerId", newJString(customerId))
  result = call_592906.call(nil, query_592907, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_592687(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_592688,
                                      base: "/", url: url_GetApiKeys_592689,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_592992 = ref object of OpenApiRestCall_592348
proc url_CreateAuthorizer_592994(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_592993(path: JsonNode; query: JsonNode;
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
  var valid_592995 = path.getOrDefault("restapi_id")
  valid_592995 = validateParameter(valid_592995, JString, required = true,
                                 default = nil)
  if valid_592995 != nil:
    section.add "restapi_id", valid_592995
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592996 = header.getOrDefault("X-Amz-Signature")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Signature", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Content-Sha256", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Date")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Date", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Credential")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Credential", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Security-Token")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Security-Token", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Algorithm")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Algorithm", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-SignedHeaders", valid_593002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_CreateAuthorizer_592992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_CreateAuthorizer_592992; restapiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593006 = newJObject()
  var body_593007 = newJObject()
  add(path_593006, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593007 = body
  result = call_593005.call(path_593006, nil, nil, nil, body_593007)

var createAuthorizer* = Call_CreateAuthorizer_592992(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_592993, base: "/",
    url: url_CreateAuthorizer_592994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_592961 = ref object of OpenApiRestCall_592348
proc url_GetAuthorizers_592963(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_592962(path: JsonNode; query: JsonNode;
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
  var valid_592978 = path.getOrDefault("restapi_id")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = nil)
  if valid_592978 != nil:
    section.add "restapi_id", valid_592978
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_592979 = query.getOrDefault("limit")
  valid_592979 = validateParameter(valid_592979, JInt, required = false, default = nil)
  if valid_592979 != nil:
    section.add "limit", valid_592979
  var valid_592980 = query.getOrDefault("position")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "position", valid_592980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592981 = header.getOrDefault("X-Amz-Signature")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Signature", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Content-Sha256", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Date")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Date", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Credential")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Credential", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Security-Token")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Security-Token", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Algorithm")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Algorithm", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-SignedHeaders", valid_592987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592988: Call_GetAuthorizers_592961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_592988.validator(path, query, header, formData, body)
  let scheme = call_592988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592988.url(scheme.get, call_592988.host, call_592988.base,
                         call_592988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592988, url, valid)

proc call*(call_592989: Call_GetAuthorizers_592961; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_592990 = newJObject()
  var query_592991 = newJObject()
  add(query_592991, "limit", newJInt(limit))
  add(query_592991, "position", newJString(position))
  add(path_592990, "restapi_id", newJString(restapiId))
  result = call_592989.call(path_592990, query_592991, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_592961(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_592962, base: "/", url: url_GetAuthorizers_592963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_593025 = ref object of OpenApiRestCall_592348
proc url_CreateBasePathMapping_593027(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_593026(path: JsonNode; query: JsonNode;
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
  var valid_593028 = path.getOrDefault("domain_name")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "domain_name", valid_593028
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593029 = header.getOrDefault("X-Amz-Signature")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Signature", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Content-Sha256", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Date")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Date", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Credential")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Credential", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Security-Token")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Security-Token", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Algorithm")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Algorithm", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-SignedHeaders", valid_593035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_CreateBasePathMapping_593025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_CreateBasePathMapping_593025; body: JsonNode;
          domainName: string): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  var path_593039 = newJObject()
  var body_593040 = newJObject()
  if body != nil:
    body_593040 = body
  add(path_593039, "domain_name", newJString(domainName))
  result = call_593038.call(path_593039, nil, nil, nil, body_593040)

var createBasePathMapping* = Call_CreateBasePathMapping_593025(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_593026, base: "/",
    url: url_CreateBasePathMapping_593027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_593008 = ref object of OpenApiRestCall_592348
proc url_GetBasePathMappings_593010(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_593009(path: JsonNode; query: JsonNode;
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
  var valid_593011 = path.getOrDefault("domain_name")
  valid_593011 = validateParameter(valid_593011, JString, required = true,
                                 default = nil)
  if valid_593011 != nil:
    section.add "domain_name", valid_593011
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593012 = query.getOrDefault("limit")
  valid_593012 = validateParameter(valid_593012, JInt, required = false, default = nil)
  if valid_593012 != nil:
    section.add "limit", valid_593012
  var valid_593013 = query.getOrDefault("position")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "position", valid_593013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593014 = header.getOrDefault("X-Amz-Signature")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Signature", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Content-Sha256", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Date")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Date", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Credential")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Credential", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Security-Token")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Security-Token", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Algorithm")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Algorithm", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-SignedHeaders", valid_593020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593021: Call_GetBasePathMappings_593008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_593021.validator(path, query, header, formData, body)
  let scheme = call_593021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593021.url(scheme.get, call_593021.host, call_593021.base,
                         call_593021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593021, url, valid)

proc call*(call_593022: Call_GetBasePathMappings_593008; domainName: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  var path_593023 = newJObject()
  var query_593024 = newJObject()
  add(query_593024, "limit", newJInt(limit))
  add(query_593024, "position", newJString(position))
  add(path_593023, "domain_name", newJString(domainName))
  result = call_593022.call(path_593023, query_593024, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_593008(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_593009, base: "/",
    url: url_GetBasePathMappings_593010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_593058 = ref object of OpenApiRestCall_592348
proc url_CreateDeployment_593060(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_593059(path: JsonNode; query: JsonNode;
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
  var valid_593061 = path.getOrDefault("restapi_id")
  valid_593061 = validateParameter(valid_593061, JString, required = true,
                                 default = nil)
  if valid_593061 != nil:
    section.add "restapi_id", valid_593061
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593062 = header.getOrDefault("X-Amz-Signature")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Signature", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Content-Sha256", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Date")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Date", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Credential")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Credential", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Security-Token")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Security-Token", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Algorithm")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Algorithm", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-SignedHeaders", valid_593068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593070: Call_CreateDeployment_593058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_593070.validator(path, query, header, formData, body)
  let scheme = call_593070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593070.url(scheme.get, call_593070.host, call_593070.base,
                         call_593070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593070, url, valid)

proc call*(call_593071: Call_CreateDeployment_593058; restapiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593072 = newJObject()
  var body_593073 = newJObject()
  add(path_593072, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593073 = body
  result = call_593071.call(path_593072, nil, nil, nil, body_593073)

var createDeployment* = Call_CreateDeployment_593058(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_593059, base: "/",
    url: url_CreateDeployment_593060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_593041 = ref object of OpenApiRestCall_592348
proc url_GetDeployments_593043(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_593042(path: JsonNode; query: JsonNode;
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
  var valid_593044 = path.getOrDefault("restapi_id")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "restapi_id", valid_593044
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593045 = query.getOrDefault("limit")
  valid_593045 = validateParameter(valid_593045, JInt, required = false, default = nil)
  if valid_593045 != nil:
    section.add "limit", valid_593045
  var valid_593046 = query.getOrDefault("position")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "position", valid_593046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593047 = header.getOrDefault("X-Amz-Signature")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Signature", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Content-Sha256", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Date")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Date", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Credential")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Credential", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Security-Token")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Security-Token", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Algorithm")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Algorithm", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-SignedHeaders", valid_593053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593054: Call_GetDeployments_593041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_593054.validator(path, query, header, formData, body)
  let scheme = call_593054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593054.url(scheme.get, call_593054.host, call_593054.base,
                         call_593054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593054, url, valid)

proc call*(call_593055: Call_GetDeployments_593041; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593056 = newJObject()
  var query_593057 = newJObject()
  add(query_593057, "limit", newJInt(limit))
  add(query_593057, "position", newJString(position))
  add(path_593056, "restapi_id", newJString(restapiId))
  result = call_593055.call(path_593056, query_593057, nil, nil, nil)

var getDeployments* = Call_GetDeployments_593041(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_593042, base: "/", url: url_GetDeployments_593043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_593108 = ref object of OpenApiRestCall_592348
proc url_ImportDocumentationParts_593110(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_593109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_593111 = path.getOrDefault("restapi_id")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "restapi_id", valid_593111
  result.add "path", section
  ## parameters in `query` object:
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  section = newJObject()
  var valid_593112 = query.getOrDefault("failonwarnings")
  valid_593112 = validateParameter(valid_593112, JBool, required = false, default = nil)
  if valid_593112 != nil:
    section.add "failonwarnings", valid_593112
  var valid_593113 = query.getOrDefault("mode")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = newJString("merge"))
  if valid_593113 != nil:
    section.add "mode", valid_593113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593114 = header.getOrDefault("X-Amz-Signature")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Signature", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Content-Sha256", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Date")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Date", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Credential")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Credential", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Security-Token")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Security-Token", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Algorithm")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Algorithm", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-SignedHeaders", valid_593120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593122: Call_ImportDocumentationParts_593108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593122.validator(path, query, header, formData, body)
  let scheme = call_593122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593122.url(scheme.get, call_593122.host, call_593122.base,
                         call_593122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593122, url, valid)

proc call*(call_593123: Call_ImportDocumentationParts_593108; restapiId: string;
          body: JsonNode; failonwarnings: bool = false; mode: string = "merge"): Recallable =
  ## importDocumentationParts
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593124 = newJObject()
  var query_593125 = newJObject()
  var body_593126 = newJObject()
  add(query_593125, "failonwarnings", newJBool(failonwarnings))
  add(query_593125, "mode", newJString(mode))
  add(path_593124, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593126 = body
  result = call_593123.call(path_593124, query_593125, nil, nil, body_593126)

var importDocumentationParts* = Call_ImportDocumentationParts_593108(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_593109, base: "/",
    url: url_ImportDocumentationParts_593110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_593127 = ref object of OpenApiRestCall_592348
proc url_CreateDocumentationPart_593129(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_593128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_593130 = path.getOrDefault("restapi_id")
  valid_593130 = validateParameter(valid_593130, JString, required = true,
                                 default = nil)
  if valid_593130 != nil:
    section.add "restapi_id", valid_593130
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593131 = header.getOrDefault("X-Amz-Signature")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Signature", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Content-Sha256", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Date")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Date", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Credential")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Credential", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Security-Token")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Security-Token", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Algorithm")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Algorithm", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-SignedHeaders", valid_593137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593139: Call_CreateDocumentationPart_593127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593139.validator(path, query, header, formData, body)
  let scheme = call_593139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593139.url(scheme.get, call_593139.host, call_593139.base,
                         call_593139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593139, url, valid)

proc call*(call_593140: Call_CreateDocumentationPart_593127; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationPart
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593141 = newJObject()
  var body_593142 = newJObject()
  add(path_593141, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593142 = body
  result = call_593140.call(path_593141, nil, nil, nil, body_593142)

var createDocumentationPart* = Call_CreateDocumentationPart_593127(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_593128, base: "/",
    url: url_CreateDocumentationPart_593129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_593074 = ref object of OpenApiRestCall_592348
proc url_GetDocumentationParts_593076(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_593075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_593077 = path.getOrDefault("restapi_id")
  valid_593077 = validateParameter(valid_593077, JString, required = true,
                                 default = nil)
  if valid_593077 != nil:
    section.add "restapi_id", valid_593077
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
  var valid_593078 = query.getOrDefault("name")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "name", valid_593078
  var valid_593079 = query.getOrDefault("limit")
  valid_593079 = validateParameter(valid_593079, JInt, required = false, default = nil)
  if valid_593079 != nil:
    section.add "limit", valid_593079
  var valid_593093 = query.getOrDefault("locationStatus")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_593093 != nil:
    section.add "locationStatus", valid_593093
  var valid_593094 = query.getOrDefault("path")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "path", valid_593094
  var valid_593095 = query.getOrDefault("position")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "position", valid_593095
  var valid_593096 = query.getOrDefault("type")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = newJString("API"))
  if valid_593096 != nil:
    section.add "type", valid_593096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_GetDocumentationParts_593074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_GetDocumentationParts_593074; restapiId: string;
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
  var path_593106 = newJObject()
  var query_593107 = newJObject()
  add(query_593107, "name", newJString(name))
  add(query_593107, "limit", newJInt(limit))
  add(query_593107, "locationStatus", newJString(locationStatus))
  add(query_593107, "path", newJString(path))
  add(query_593107, "position", newJString(position))
  add(query_593107, "type", newJString(`type`))
  add(path_593106, "restapi_id", newJString(restapiId))
  result = call_593105.call(path_593106, query_593107, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_593074(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_593075, base: "/",
    url: url_GetDocumentationParts_593076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_593160 = ref object of OpenApiRestCall_592348
proc url_CreateDocumentationVersion_593162(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_593161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_593163 = path.getOrDefault("restapi_id")
  valid_593163 = validateParameter(valid_593163, JString, required = true,
                                 default = nil)
  if valid_593163 != nil:
    section.add "restapi_id", valid_593163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593164 = header.getOrDefault("X-Amz-Signature")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Signature", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Content-Sha256", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Date")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Date", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Credential")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Credential", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Security-Token")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Security-Token", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Algorithm")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Algorithm", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-SignedHeaders", valid_593170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_CreateDocumentationVersion_593160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_CreateDocumentationVersion_593160; restapiId: string;
          body: JsonNode): Recallable =
  ## createDocumentationVersion
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593174 = newJObject()
  var body_593175 = newJObject()
  add(path_593174, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593175 = body
  result = call_593173.call(path_593174, nil, nil, nil, body_593175)

var createDocumentationVersion* = Call_CreateDocumentationVersion_593160(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_593161, base: "/",
    url: url_CreateDocumentationVersion_593162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_593143 = ref object of OpenApiRestCall_592348
proc url_GetDocumentationVersions_593145(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_593144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_593146 = path.getOrDefault("restapi_id")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = nil)
  if valid_593146 != nil:
    section.add "restapi_id", valid_593146
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593147 = query.getOrDefault("limit")
  valid_593147 = validateParameter(valid_593147, JInt, required = false, default = nil)
  if valid_593147 != nil:
    section.add "limit", valid_593147
  var valid_593148 = query.getOrDefault("position")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "position", valid_593148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593149 = header.getOrDefault("X-Amz-Signature")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Signature", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Content-Sha256", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Date")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Date", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Credential")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Credential", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Security-Token")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Security-Token", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Algorithm")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Algorithm", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-SignedHeaders", valid_593155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593156: Call_GetDocumentationVersions_593143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593156.validator(path, query, header, formData, body)
  let scheme = call_593156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593156.url(scheme.get, call_593156.host, call_593156.base,
                         call_593156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593156, url, valid)

proc call*(call_593157: Call_GetDocumentationVersions_593143; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getDocumentationVersions
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593158 = newJObject()
  var query_593159 = newJObject()
  add(query_593159, "limit", newJInt(limit))
  add(query_593159, "position", newJString(position))
  add(path_593158, "restapi_id", newJString(restapiId))
  result = call_593157.call(path_593158, query_593159, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_593143(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_593144, base: "/",
    url: url_GetDocumentationVersions_593145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_593191 = ref object of OpenApiRestCall_592348
proc url_CreateDomainName_593193(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainName_593192(path: JsonNode; query: JsonNode;
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
  var valid_593194 = header.getOrDefault("X-Amz-Signature")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Signature", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Content-Sha256", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Date")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Date", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Credential")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Credential", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Security-Token")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Security-Token", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Algorithm")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Algorithm", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-SignedHeaders", valid_593200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593202: Call_CreateDomainName_593191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_593202.validator(path, query, header, formData, body)
  let scheme = call_593202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593202.url(scheme.get, call_593202.host, call_593202.base,
                         call_593202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593202, url, valid)

proc call*(call_593203: Call_CreateDomainName_593191; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_593204 = newJObject()
  if body != nil:
    body_593204 = body
  result = call_593203.call(nil, nil, nil, nil, body_593204)

var createDomainName* = Call_CreateDomainName_593191(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_593192, base: "/",
    url: url_CreateDomainName_593193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_593176 = ref object of OpenApiRestCall_592348
proc url_GetDomainNames_593178(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainNames_593177(path: JsonNode; query: JsonNode;
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
  var valid_593179 = query.getOrDefault("limit")
  valid_593179 = validateParameter(valid_593179, JInt, required = false, default = nil)
  if valid_593179 != nil:
    section.add "limit", valid_593179
  var valid_593180 = query.getOrDefault("position")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "position", valid_593180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593181 = header.getOrDefault("X-Amz-Signature")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Signature", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Content-Sha256", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Date")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Date", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Credential")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Credential", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Security-Token")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Security-Token", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Algorithm")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Algorithm", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-SignedHeaders", valid_593187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593188: Call_GetDomainNames_593176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_593188.validator(path, query, header, formData, body)
  let scheme = call_593188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593188.url(scheme.get, call_593188.host, call_593188.base,
                         call_593188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593188, url, valid)

proc call*(call_593189: Call_GetDomainNames_593176; limit: int = 0;
          position: string = ""): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_593190 = newJObject()
  add(query_593190, "limit", newJInt(limit))
  add(query_593190, "position", newJString(position))
  result = call_593189.call(nil, query_593190, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_593176(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_593177, base: "/",
    url: url_GetDomainNames_593178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_593222 = ref object of OpenApiRestCall_592348
proc url_CreateModel_593224(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_593223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593225 = path.getOrDefault("restapi_id")
  valid_593225 = validateParameter(valid_593225, JString, required = true,
                                 default = nil)
  if valid_593225 != nil:
    section.add "restapi_id", valid_593225
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593226 = header.getOrDefault("X-Amz-Signature")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Signature", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Content-Sha256", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Date")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Date", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Credential")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Credential", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Security-Token")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Security-Token", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Algorithm")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Algorithm", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-SignedHeaders", valid_593232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593234: Call_CreateModel_593222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_593234.validator(path, query, header, formData, body)
  let scheme = call_593234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593234.url(scheme.get, call_593234.host, call_593234.base,
                         call_593234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593234, url, valid)

proc call*(call_593235: Call_CreateModel_593222; restapiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  ##   body: JObject (required)
  var path_593236 = newJObject()
  var body_593237 = newJObject()
  add(path_593236, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593237 = body
  result = call_593235.call(path_593236, nil, nil, nil, body_593237)

var createModel* = Call_CreateModel_593222(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_593223,
                                        base: "/", url: url_CreateModel_593224,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_593205 = ref object of OpenApiRestCall_592348
proc url_GetModels_593207(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_593206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593208 = path.getOrDefault("restapi_id")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "restapi_id", valid_593208
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593209 = query.getOrDefault("limit")
  valid_593209 = validateParameter(valid_593209, JInt, required = false, default = nil)
  if valid_593209 != nil:
    section.add "limit", valid_593209
  var valid_593210 = query.getOrDefault("position")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "position", valid_593210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593211 = header.getOrDefault("X-Amz-Signature")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Signature", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Content-Sha256", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Date")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Date", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Credential")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Credential", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Security-Token")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Security-Token", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Algorithm")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Algorithm", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-SignedHeaders", valid_593217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593218: Call_GetModels_593205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_593218.validator(path, query, header, formData, body)
  let scheme = call_593218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593218.url(scheme.get, call_593218.host, call_593218.base,
                         call_593218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593218, url, valid)

proc call*(call_593219: Call_GetModels_593205; restapiId: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593220 = newJObject()
  var query_593221 = newJObject()
  add(query_593221, "limit", newJInt(limit))
  add(query_593221, "position", newJString(position))
  add(path_593220, "restapi_id", newJString(restapiId))
  result = call_593219.call(path_593220, query_593221, nil, nil, nil)

var getModels* = Call_GetModels_593205(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_593206,
                                    base: "/", url: url_GetModels_593207,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_593255 = ref object of OpenApiRestCall_592348
proc url_CreateRequestValidator_593257(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_593256(path: JsonNode; query: JsonNode;
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
  var valid_593258 = path.getOrDefault("restapi_id")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = nil)
  if valid_593258 != nil:
    section.add "restapi_id", valid_593258
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593259 = header.getOrDefault("X-Amz-Signature")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Signature", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Content-Sha256", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Date")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Date", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Credential")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Credential", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Security-Token")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Security-Token", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Algorithm")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Algorithm", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-SignedHeaders", valid_593265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_CreateRequestValidator_593255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_CreateRequestValidator_593255; restapiId: string;
          body: JsonNode): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593269 = newJObject()
  var body_593270 = newJObject()
  add(path_593269, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593270 = body
  result = call_593268.call(path_593269, nil, nil, nil, body_593270)

var createRequestValidator* = Call_CreateRequestValidator_593255(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_593256, base: "/",
    url: url_CreateRequestValidator_593257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_593238 = ref object of OpenApiRestCall_592348
proc url_GetRequestValidators_593240(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_593239(path: JsonNode; query: JsonNode;
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
  var valid_593241 = path.getOrDefault("restapi_id")
  valid_593241 = validateParameter(valid_593241, JString, required = true,
                                 default = nil)
  if valid_593241 != nil:
    section.add "restapi_id", valid_593241
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593242 = query.getOrDefault("limit")
  valid_593242 = validateParameter(valid_593242, JInt, required = false, default = nil)
  if valid_593242 != nil:
    section.add "limit", valid_593242
  var valid_593243 = query.getOrDefault("position")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "position", valid_593243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593244 = header.getOrDefault("X-Amz-Signature")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Signature", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Content-Sha256", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Date")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Date", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Credential")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Credential", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Security-Token")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Security-Token", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Algorithm")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Algorithm", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-SignedHeaders", valid_593250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593251: Call_GetRequestValidators_593238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_593251.validator(path, query, header, formData, body)
  let scheme = call_593251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593251.url(scheme.get, call_593251.host, call_593251.base,
                         call_593251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593251, url, valid)

proc call*(call_593252: Call_GetRequestValidators_593238; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593253 = newJObject()
  var query_593254 = newJObject()
  add(query_593254, "limit", newJInt(limit))
  add(query_593254, "position", newJString(position))
  add(path_593253, "restapi_id", newJString(restapiId))
  result = call_593252.call(path_593253, query_593254, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_593238(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_593239, base: "/",
    url: url_GetRequestValidators_593240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_593271 = ref object of OpenApiRestCall_592348
proc url_CreateResource_593273(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_593272(path: JsonNode; query: JsonNode;
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
  var valid_593274 = path.getOrDefault("restapi_id")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = nil)
  if valid_593274 != nil:
    section.add "restapi_id", valid_593274
  var valid_593275 = path.getOrDefault("parent_id")
  valid_593275 = validateParameter(valid_593275, JString, required = true,
                                 default = nil)
  if valid_593275 != nil:
    section.add "parent_id", valid_593275
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_CreateResource_593271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_CreateResource_593271; restapiId: string;
          body: JsonNode; parentId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  var path_593286 = newJObject()
  var body_593287 = newJObject()
  add(path_593286, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593287 = body
  add(path_593286, "parent_id", newJString(parentId))
  result = call_593285.call(path_593286, nil, nil, nil, body_593287)

var createResource* = Call_CreateResource_593271(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_593272, base: "/", url: url_CreateResource_593273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_593303 = ref object of OpenApiRestCall_592348
proc url_CreateRestApi_593305(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRestApi_593304(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_CreateRestApi_593303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_CreateRestApi_593303; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var createRestApi* = Call_CreateRestApi_593303(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_593304, base: "/", url: url_CreateRestApi_593305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_593288 = ref object of OpenApiRestCall_592348
proc url_GetRestApis_593290(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestApis_593289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593291 = query.getOrDefault("limit")
  valid_593291 = validateParameter(valid_593291, JInt, required = false, default = nil)
  if valid_593291 != nil:
    section.add "limit", valid_593291
  var valid_593292 = query.getOrDefault("position")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "position", valid_593292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593293 = header.getOrDefault("X-Amz-Signature")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Signature", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Content-Sha256", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Date")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Date", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Credential")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Credential", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Security-Token")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Security-Token", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Algorithm")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Algorithm", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-SignedHeaders", valid_593299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593300: Call_GetRestApis_593288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_593300.validator(path, query, header, formData, body)
  let scheme = call_593300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593300.url(scheme.get, call_593300.host, call_593300.base,
                         call_593300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593300, url, valid)

proc call*(call_593301: Call_GetRestApis_593288; limit: int = 0; position: string = ""): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_593302 = newJObject()
  add(query_593302, "limit", newJInt(limit))
  add(query_593302, "position", newJString(position))
  result = call_593301.call(nil, query_593302, nil, nil, nil)

var getRestApis* = Call_GetRestApis_593288(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_593289,
                                        base: "/", url: url_GetRestApis_593290,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_593333 = ref object of OpenApiRestCall_592348
proc url_CreateStage_593335(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_593334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593336 = path.getOrDefault("restapi_id")
  valid_593336 = validateParameter(valid_593336, JString, required = true,
                                 default = nil)
  if valid_593336 != nil:
    section.add "restapi_id", valid_593336
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593337 = header.getOrDefault("X-Amz-Signature")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Signature", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Content-Sha256", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Date")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Date", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Credential")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Credential", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Security-Token")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Security-Token", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Algorithm")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Algorithm", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-SignedHeaders", valid_593343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593345: Call_CreateStage_593333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_593345.validator(path, query, header, formData, body)
  let scheme = call_593345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593345.url(scheme.get, call_593345.host, call_593345.base,
                         call_593345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593345, url, valid)

proc call*(call_593346: Call_CreateStage_593333; restapiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593347 = newJObject()
  var body_593348 = newJObject()
  add(path_593347, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593348 = body
  result = call_593346.call(path_593347, nil, nil, nil, body_593348)

var createStage* = Call_CreateStage_593333(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_593334,
                                        base: "/", url: url_CreateStage_593335,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_593317 = ref object of OpenApiRestCall_592348
proc url_GetStages_593319(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_593318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593320 = path.getOrDefault("restapi_id")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = nil)
  if valid_593320 != nil:
    section.add "restapi_id", valid_593320
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_593321 = query.getOrDefault("deploymentId")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "deploymentId", valid_593321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593322 = header.getOrDefault("X-Amz-Signature")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Signature", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Content-Sha256", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Date")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Date", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Credential")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Credential", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Security-Token")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Security-Token", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Algorithm")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Algorithm", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-SignedHeaders", valid_593328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_GetStages_593317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_GetStages_593317; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  var path_593331 = newJObject()
  var query_593332 = newJObject()
  add(path_593331, "restapi_id", newJString(restapiId))
  add(query_593332, "deploymentId", newJString(deploymentId))
  result = call_593330.call(path_593331, query_593332, nil, nil, nil)

var getStages* = Call_GetStages_593317(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_593318,
                                    base: "/", url: url_GetStages_593319,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_593365 = ref object of OpenApiRestCall_592348
proc url_CreateUsagePlan_593367(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUsagePlan_593366(path: JsonNode; query: JsonNode;
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
  var valid_593368 = header.getOrDefault("X-Amz-Signature")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Signature", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Content-Sha256", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Date")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Date", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Credential")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Credential", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Security-Token")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Security-Token", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Algorithm")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Algorithm", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-SignedHeaders", valid_593374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593376: Call_CreateUsagePlan_593365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_593376.validator(path, query, header, formData, body)
  let scheme = call_593376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593376.url(scheme.get, call_593376.host, call_593376.base,
                         call_593376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593376, url, valid)

proc call*(call_593377: Call_CreateUsagePlan_593365; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_593378 = newJObject()
  if body != nil:
    body_593378 = body
  result = call_593377.call(nil, nil, nil, nil, body_593378)

var createUsagePlan* = Call_CreateUsagePlan_593365(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_593366, base: "/",
    url: url_CreateUsagePlan_593367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_593349 = ref object of OpenApiRestCall_592348
proc url_GetUsagePlans_593351(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUsagePlans_593350(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593352 = query.getOrDefault("limit")
  valid_593352 = validateParameter(valid_593352, JInt, required = false, default = nil)
  if valid_593352 != nil:
    section.add "limit", valid_593352
  var valid_593353 = query.getOrDefault("position")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "position", valid_593353
  var valid_593354 = query.getOrDefault("keyId")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "keyId", valid_593354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593355 = header.getOrDefault("X-Amz-Signature")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Signature", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Content-Sha256", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Date")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Date", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Credential")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Credential", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Security-Token")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Security-Token", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Algorithm")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Algorithm", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-SignedHeaders", valid_593361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593362: Call_GetUsagePlans_593349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_593362.validator(path, query, header, formData, body)
  let scheme = call_593362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593362.url(scheme.get, call_593362.host, call_593362.base,
                         call_593362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593362, url, valid)

proc call*(call_593363: Call_GetUsagePlans_593349; limit: int = 0;
          position: string = ""; keyId: string = ""): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  var query_593364 = newJObject()
  add(query_593364, "limit", newJInt(limit))
  add(query_593364, "position", newJString(position))
  add(query_593364, "keyId", newJString(keyId))
  result = call_593363.call(nil, query_593364, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_593349(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_593350, base: "/",
    url: url_GetUsagePlans_593351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_593397 = ref object of OpenApiRestCall_592348
proc url_CreateUsagePlanKey_593399(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_593398(path: JsonNode; query: JsonNode;
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
  var valid_593400 = path.getOrDefault("usageplanId")
  valid_593400 = validateParameter(valid_593400, JString, required = true,
                                 default = nil)
  if valid_593400 != nil:
    section.add "usageplanId", valid_593400
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593401 = header.getOrDefault("X-Amz-Signature")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Signature", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Content-Sha256", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Date")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Date", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Credential")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Credential", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Security-Token")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Security-Token", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Algorithm")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Algorithm", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-SignedHeaders", valid_593407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593409: Call_CreateUsagePlanKey_593397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_593409.validator(path, query, header, formData, body)
  let scheme = call_593409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593409.url(scheme.get, call_593409.host, call_593409.base,
                         call_593409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593409, url, valid)

proc call*(call_593410: Call_CreateUsagePlanKey_593397; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_593411 = newJObject()
  var body_593412 = newJObject()
  add(path_593411, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_593412 = body
  result = call_593410.call(path_593411, nil, nil, nil, body_593412)

var createUsagePlanKey* = Call_CreateUsagePlanKey_593397(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_593398, base: "/",
    url: url_CreateUsagePlanKey_593399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_593379 = ref object of OpenApiRestCall_592348
proc url_GetUsagePlanKeys_593381(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_593380(path: JsonNode; query: JsonNode;
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
  var valid_593382 = path.getOrDefault("usageplanId")
  valid_593382 = validateParameter(valid_593382, JString, required = true,
                                 default = nil)
  if valid_593382 != nil:
    section.add "usageplanId", valid_593382
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  section = newJObject()
  var valid_593383 = query.getOrDefault("name")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "name", valid_593383
  var valid_593384 = query.getOrDefault("limit")
  valid_593384 = validateParameter(valid_593384, JInt, required = false, default = nil)
  if valid_593384 != nil:
    section.add "limit", valid_593384
  var valid_593385 = query.getOrDefault("position")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "position", valid_593385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593386 = header.getOrDefault("X-Amz-Signature")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Signature", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Content-Sha256", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Date")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Date", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Credential")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Credential", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Security-Token")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Security-Token", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Algorithm")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Algorithm", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-SignedHeaders", valid_593392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593393: Call_GetUsagePlanKeys_593379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_593393.validator(path, query, header, formData, body)
  let scheme = call_593393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593393.url(scheme.get, call_593393.host, call_593393.base,
                         call_593393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593393, url, valid)

proc call*(call_593394: Call_GetUsagePlanKeys_593379; usageplanId: string;
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
  var path_593395 = newJObject()
  var query_593396 = newJObject()
  add(query_593396, "name", newJString(name))
  add(path_593395, "usageplanId", newJString(usageplanId))
  add(query_593396, "limit", newJInt(limit))
  add(query_593396, "position", newJString(position))
  result = call_593394.call(path_593395, query_593396, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_593379(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_593380,
    base: "/", url: url_GetUsagePlanKeys_593381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_593428 = ref object of OpenApiRestCall_592348
proc url_CreateVpcLink_593430(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVpcLink_593429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593431 = header.getOrDefault("X-Amz-Signature")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Signature", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Content-Sha256", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Date")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Date", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Credential")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Credential", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Security-Token")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Security-Token", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Algorithm")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Algorithm", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-SignedHeaders", valid_593437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593439: Call_CreateVpcLink_593428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_593439.validator(path, query, header, formData, body)
  let scheme = call_593439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593439.url(scheme.get, call_593439.host, call_593439.base,
                         call_593439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593439, url, valid)

proc call*(call_593440: Call_CreateVpcLink_593428; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_593441 = newJObject()
  if body != nil:
    body_593441 = body
  result = call_593440.call(nil, nil, nil, nil, body_593441)

var createVpcLink* = Call_CreateVpcLink_593428(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_593429, base: "/", url: url_CreateVpcLink_593430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_593413 = ref object of OpenApiRestCall_592348
proc url_GetVpcLinks_593415(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVpcLinks_593414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593416 = query.getOrDefault("limit")
  valid_593416 = validateParameter(valid_593416, JInt, required = false, default = nil)
  if valid_593416 != nil:
    section.add "limit", valid_593416
  var valid_593417 = query.getOrDefault("position")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "position", valid_593417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593418 = header.getOrDefault("X-Amz-Signature")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Signature", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Content-Sha256", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Date")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Date", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Credential")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Credential", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Security-Token")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Security-Token", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Algorithm")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Algorithm", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-SignedHeaders", valid_593424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593425: Call_GetVpcLinks_593413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_593425.validator(path, query, header, formData, body)
  let scheme = call_593425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593425.url(scheme.get, call_593425.host, call_593425.base,
                         call_593425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593425, url, valid)

proc call*(call_593426: Call_GetVpcLinks_593413; limit: int = 0; position: string = ""): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_593427 = newJObject()
  add(query_593427, "limit", newJInt(limit))
  add(query_593427, "position", newJString(position))
  result = call_593426.call(nil, query_593427, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_593413(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_593414,
                                        base: "/", url: url_GetVpcLinks_593415,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_593442 = ref object of OpenApiRestCall_592348
proc url_GetApiKey_593444(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_593443(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593445 = path.getOrDefault("api_Key")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = nil)
  if valid_593445 != nil:
    section.add "api_Key", valid_593445
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_593446 = query.getOrDefault("includeValue")
  valid_593446 = validateParameter(valid_593446, JBool, required = false, default = nil)
  if valid_593446 != nil:
    section.add "includeValue", valid_593446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593447 = header.getOrDefault("X-Amz-Signature")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Signature", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Content-Sha256", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Date")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Date", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Credential")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Credential", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Security-Token")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Security-Token", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Algorithm")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Algorithm", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-SignedHeaders", valid_593453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593454: Call_GetApiKey_593442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_593454.validator(path, query, header, formData, body)
  let scheme = call_593454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593454.url(scheme.get, call_593454.host, call_593454.base,
                         call_593454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593454, url, valid)

proc call*(call_593455: Call_GetApiKey_593442; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_593456 = newJObject()
  var query_593457 = newJObject()
  add(query_593457, "includeValue", newJBool(includeValue))
  add(path_593456, "api_Key", newJString(apiKey))
  result = call_593455.call(path_593456, query_593457, nil, nil, nil)

var getApiKey* = Call_GetApiKey_593442(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_593443,
                                    base: "/", url: url_GetApiKey_593444,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_593472 = ref object of OpenApiRestCall_592348
proc url_UpdateApiKey_593474(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_593473(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593475 = path.getOrDefault("api_Key")
  valid_593475 = validateParameter(valid_593475, JString, required = true,
                                 default = nil)
  if valid_593475 != nil:
    section.add "api_Key", valid_593475
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593476 = header.getOrDefault("X-Amz-Signature")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Signature", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Content-Sha256", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Date")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Date", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Credential")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Credential", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Security-Token")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Security-Token", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Algorithm")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Algorithm", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-SignedHeaders", valid_593482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593484: Call_UpdateApiKey_593472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_593484.validator(path, query, header, formData, body)
  let scheme = call_593484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593484.url(scheme.get, call_593484.host, call_593484.base,
                         call_593484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593484, url, valid)

proc call*(call_593485: Call_UpdateApiKey_593472; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_593486 = newJObject()
  var body_593487 = newJObject()
  add(path_593486, "api_Key", newJString(apiKey))
  if body != nil:
    body_593487 = body
  result = call_593485.call(path_593486, nil, nil, nil, body_593487)

var updateApiKey* = Call_UpdateApiKey_593472(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_593473, base: "/",
    url: url_UpdateApiKey_593474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_593458 = ref object of OpenApiRestCall_592348
proc url_DeleteApiKey_593460(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_593459(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593461 = path.getOrDefault("api_Key")
  valid_593461 = validateParameter(valid_593461, JString, required = true,
                                 default = nil)
  if valid_593461 != nil:
    section.add "api_Key", valid_593461
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593462 = header.getOrDefault("X-Amz-Signature")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Signature", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Content-Sha256", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Date")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Date", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Credential")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Credential", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Security-Token")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Security-Token", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Algorithm")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Algorithm", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-SignedHeaders", valid_593468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593469: Call_DeleteApiKey_593458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_593469.validator(path, query, header, formData, body)
  let scheme = call_593469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593469.url(scheme.get, call_593469.host, call_593469.base,
                         call_593469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593469, url, valid)

proc call*(call_593470: Call_DeleteApiKey_593458; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_593471 = newJObject()
  add(path_593471, "api_Key", newJString(apiKey))
  result = call_593470.call(path_593471, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_593458(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_593459, base: "/",
    url: url_DeleteApiKey_593460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_593503 = ref object of OpenApiRestCall_592348
proc url_TestInvokeAuthorizer_593505(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_593504(path: JsonNode; query: JsonNode;
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
  var valid_593506 = path.getOrDefault("restapi_id")
  valid_593506 = validateParameter(valid_593506, JString, required = true,
                                 default = nil)
  if valid_593506 != nil:
    section.add "restapi_id", valid_593506
  var valid_593507 = path.getOrDefault("authorizer_id")
  valid_593507 = validateParameter(valid_593507, JString, required = true,
                                 default = nil)
  if valid_593507 != nil:
    section.add "authorizer_id", valid_593507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593508 = header.getOrDefault("X-Amz-Signature")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Signature", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Content-Sha256", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Date")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Date", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Credential")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Credential", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-Security-Token")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-Security-Token", valid_593512
  var valid_593513 = header.getOrDefault("X-Amz-Algorithm")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Algorithm", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-SignedHeaders", valid_593514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593516: Call_TestInvokeAuthorizer_593503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_593516.validator(path, query, header, formData, body)
  let scheme = call_593516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593516.url(scheme.get, call_593516.host, call_593516.base,
                         call_593516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593516, url, valid)

proc call*(call_593517: Call_TestInvokeAuthorizer_593503; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  var path_593518 = newJObject()
  var body_593519 = newJObject()
  add(path_593518, "restapi_id", newJString(restapiId))
  add(path_593518, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_593519 = body
  result = call_593517.call(path_593518, nil, nil, nil, body_593519)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_593503(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_593504, base: "/",
    url: url_TestInvokeAuthorizer_593505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_593488 = ref object of OpenApiRestCall_592348
proc url_GetAuthorizer_593490(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_593489(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593491 = path.getOrDefault("restapi_id")
  valid_593491 = validateParameter(valid_593491, JString, required = true,
                                 default = nil)
  if valid_593491 != nil:
    section.add "restapi_id", valid_593491
  var valid_593492 = path.getOrDefault("authorizer_id")
  valid_593492 = validateParameter(valid_593492, JString, required = true,
                                 default = nil)
  if valid_593492 != nil:
    section.add "authorizer_id", valid_593492
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593493 = header.getOrDefault("X-Amz-Signature")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Signature", valid_593493
  var valid_593494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Content-Sha256", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Date")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Date", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Credential")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Credential", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Security-Token")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Security-Token", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Algorithm")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Algorithm", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-SignedHeaders", valid_593499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593500: Call_GetAuthorizer_593488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_593500.validator(path, query, header, formData, body)
  let scheme = call_593500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593500.url(scheme.get, call_593500.host, call_593500.base,
                         call_593500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593500, url, valid)

proc call*(call_593501: Call_GetAuthorizer_593488; restapiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_593502 = newJObject()
  add(path_593502, "restapi_id", newJString(restapiId))
  add(path_593502, "authorizer_id", newJString(authorizerId))
  result = call_593501.call(path_593502, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_593488(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_593489, base: "/", url: url_GetAuthorizer_593490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_593535 = ref object of OpenApiRestCall_592348
proc url_UpdateAuthorizer_593537(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_593536(path: JsonNode; query: JsonNode;
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
  var valid_593538 = path.getOrDefault("restapi_id")
  valid_593538 = validateParameter(valid_593538, JString, required = true,
                                 default = nil)
  if valid_593538 != nil:
    section.add "restapi_id", valid_593538
  var valid_593539 = path.getOrDefault("authorizer_id")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = nil)
  if valid_593539 != nil:
    section.add "authorizer_id", valid_593539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593540 = header.getOrDefault("X-Amz-Signature")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Signature", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Content-Sha256", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Date")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Date", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Credential")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Credential", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Security-Token")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Security-Token", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Algorithm")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Algorithm", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-SignedHeaders", valid_593546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593548: Call_UpdateAuthorizer_593535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_593548.validator(path, query, header, formData, body)
  let scheme = call_593548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593548.url(scheme.get, call_593548.host, call_593548.base,
                         call_593548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593548, url, valid)

proc call*(call_593549: Call_UpdateAuthorizer_593535; restapiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  var path_593550 = newJObject()
  var body_593551 = newJObject()
  add(path_593550, "restapi_id", newJString(restapiId))
  add(path_593550, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_593551 = body
  result = call_593549.call(path_593550, nil, nil, nil, body_593551)

var updateAuthorizer* = Call_UpdateAuthorizer_593535(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_593536, base: "/",
    url: url_UpdateAuthorizer_593537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_593520 = ref object of OpenApiRestCall_592348
proc url_DeleteAuthorizer_593522(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_593521(path: JsonNode; query: JsonNode;
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
  var valid_593523 = path.getOrDefault("restapi_id")
  valid_593523 = validateParameter(valid_593523, JString, required = true,
                                 default = nil)
  if valid_593523 != nil:
    section.add "restapi_id", valid_593523
  var valid_593524 = path.getOrDefault("authorizer_id")
  valid_593524 = validateParameter(valid_593524, JString, required = true,
                                 default = nil)
  if valid_593524 != nil:
    section.add "authorizer_id", valid_593524
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593525 = header.getOrDefault("X-Amz-Signature")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Signature", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Content-Sha256", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-Date")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-Date", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-Credential")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-Credential", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Security-Token")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Security-Token", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Algorithm")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Algorithm", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-SignedHeaders", valid_593531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593532: Call_DeleteAuthorizer_593520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_593532.validator(path, query, header, formData, body)
  let scheme = call_593532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593532.url(scheme.get, call_593532.host, call_593532.base,
                         call_593532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593532, url, valid)

proc call*(call_593533: Call_DeleteAuthorizer_593520; restapiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  var path_593534 = newJObject()
  add(path_593534, "restapi_id", newJString(restapiId))
  add(path_593534, "authorizer_id", newJString(authorizerId))
  result = call_593533.call(path_593534, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_593520(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_593521, base: "/",
    url: url_DeleteAuthorizer_593522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_593552 = ref object of OpenApiRestCall_592348
proc url_GetBasePathMapping_593554(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_593553(path: JsonNode; query: JsonNode;
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
  var valid_593555 = path.getOrDefault("base_path")
  valid_593555 = validateParameter(valid_593555, JString, required = true,
                                 default = nil)
  if valid_593555 != nil:
    section.add "base_path", valid_593555
  var valid_593556 = path.getOrDefault("domain_name")
  valid_593556 = validateParameter(valid_593556, JString, required = true,
                                 default = nil)
  if valid_593556 != nil:
    section.add "domain_name", valid_593556
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593557 = header.getOrDefault("X-Amz-Signature")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Signature", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Content-Sha256", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Date")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Date", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Credential")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Credential", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Security-Token")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Security-Token", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Algorithm")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Algorithm", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-SignedHeaders", valid_593563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593564: Call_GetBasePathMapping_593552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_593564.validator(path, query, header, formData, body)
  let scheme = call_593564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593564.url(scheme.get, call_593564.host, call_593564.base,
                         call_593564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593564, url, valid)

proc call*(call_593565: Call_GetBasePathMapping_593552; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_593566 = newJObject()
  add(path_593566, "base_path", newJString(basePath))
  add(path_593566, "domain_name", newJString(domainName))
  result = call_593565.call(path_593566, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_593552(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_593553, base: "/",
    url: url_GetBasePathMapping_593554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_593582 = ref object of OpenApiRestCall_592348
proc url_UpdateBasePathMapping_593584(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_593583(path: JsonNode; query: JsonNode;
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
  var valid_593585 = path.getOrDefault("base_path")
  valid_593585 = validateParameter(valid_593585, JString, required = true,
                                 default = nil)
  if valid_593585 != nil:
    section.add "base_path", valid_593585
  var valid_593586 = path.getOrDefault("domain_name")
  valid_593586 = validateParameter(valid_593586, JString, required = true,
                                 default = nil)
  if valid_593586 != nil:
    section.add "domain_name", valid_593586
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593587 = header.getOrDefault("X-Amz-Signature")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Signature", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Content-Sha256", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Date")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Date", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Credential")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Credential", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Security-Token")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Security-Token", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Algorithm")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Algorithm", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-SignedHeaders", valid_593593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593595: Call_UpdateBasePathMapping_593582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_593595.validator(path, query, header, formData, body)
  let scheme = call_593595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593595.url(scheme.get, call_593595.host, call_593595.base,
                         call_593595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593595, url, valid)

proc call*(call_593596: Call_UpdateBasePathMapping_593582; basePath: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  var path_593597 = newJObject()
  var body_593598 = newJObject()
  add(path_593597, "base_path", newJString(basePath))
  if body != nil:
    body_593598 = body
  add(path_593597, "domain_name", newJString(domainName))
  result = call_593596.call(path_593597, nil, nil, nil, body_593598)

var updateBasePathMapping* = Call_UpdateBasePathMapping_593582(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_593583, base: "/",
    url: url_UpdateBasePathMapping_593584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_593567 = ref object of OpenApiRestCall_592348
proc url_DeleteBasePathMapping_593569(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_593568(path: JsonNode; query: JsonNode;
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
  var valid_593570 = path.getOrDefault("base_path")
  valid_593570 = validateParameter(valid_593570, JString, required = true,
                                 default = nil)
  if valid_593570 != nil:
    section.add "base_path", valid_593570
  var valid_593571 = path.getOrDefault("domain_name")
  valid_593571 = validateParameter(valid_593571, JString, required = true,
                                 default = nil)
  if valid_593571 != nil:
    section.add "domain_name", valid_593571
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593572 = header.getOrDefault("X-Amz-Signature")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Signature", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-Content-Sha256", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Date")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Date", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Credential")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Credential", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Security-Token")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Security-Token", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Algorithm")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Algorithm", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-SignedHeaders", valid_593578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593579: Call_DeleteBasePathMapping_593567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_593579.validator(path, query, header, formData, body)
  let scheme = call_593579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593579.url(scheme.get, call_593579.host, call_593579.base,
                         call_593579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593579, url, valid)

proc call*(call_593580: Call_DeleteBasePathMapping_593567; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_593581 = newJObject()
  add(path_593581, "base_path", newJString(basePath))
  add(path_593581, "domain_name", newJString(domainName))
  result = call_593580.call(path_593581, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_593567(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_593568, base: "/",
    url: url_DeleteBasePathMapping_593569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_593599 = ref object of OpenApiRestCall_592348
proc url_GetClientCertificate_593601(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_593600(path: JsonNode; query: JsonNode;
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
  var valid_593602 = path.getOrDefault("clientcertificate_id")
  valid_593602 = validateParameter(valid_593602, JString, required = true,
                                 default = nil)
  if valid_593602 != nil:
    section.add "clientcertificate_id", valid_593602
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593603 = header.getOrDefault("X-Amz-Signature")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Signature", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Content-Sha256", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Date")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Date", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Credential")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Credential", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Security-Token")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Security-Token", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Algorithm")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Algorithm", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-SignedHeaders", valid_593609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593610: Call_GetClientCertificate_593599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_593610.validator(path, query, header, formData, body)
  let scheme = call_593610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593610.url(scheme.get, call_593610.host, call_593610.base,
                         call_593610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593610, url, valid)

proc call*(call_593611: Call_GetClientCertificate_593599;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_593612 = newJObject()
  add(path_593612, "clientcertificate_id", newJString(clientcertificateId))
  result = call_593611.call(path_593612, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_593599(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_593600, base: "/",
    url: url_GetClientCertificate_593601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_593627 = ref object of OpenApiRestCall_592348
proc url_UpdateClientCertificate_593629(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_593628(path: JsonNode; query: JsonNode;
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
  var valid_593630 = path.getOrDefault("clientcertificate_id")
  valid_593630 = validateParameter(valid_593630, JString, required = true,
                                 default = nil)
  if valid_593630 != nil:
    section.add "clientcertificate_id", valid_593630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593631 = header.getOrDefault("X-Amz-Signature")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Signature", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Content-Sha256", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Date")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Date", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Credential")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Credential", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Security-Token")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Security-Token", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Algorithm")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Algorithm", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-SignedHeaders", valid_593637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593639: Call_UpdateClientCertificate_593627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_593639.validator(path, query, header, formData, body)
  let scheme = call_593639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593639.url(scheme.get, call_593639.host, call_593639.base,
                         call_593639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593639, url, valid)

proc call*(call_593640: Call_UpdateClientCertificate_593627;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_593641 = newJObject()
  var body_593642 = newJObject()
  add(path_593641, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_593642 = body
  result = call_593640.call(path_593641, nil, nil, nil, body_593642)

var updateClientCertificate* = Call_UpdateClientCertificate_593627(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_593628, base: "/",
    url: url_UpdateClientCertificate_593629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_593613 = ref object of OpenApiRestCall_592348
proc url_DeleteClientCertificate_593615(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_593614(path: JsonNode; query: JsonNode;
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
  var valid_593616 = path.getOrDefault("clientcertificate_id")
  valid_593616 = validateParameter(valid_593616, JString, required = true,
                                 default = nil)
  if valid_593616 != nil:
    section.add "clientcertificate_id", valid_593616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593617 = header.getOrDefault("X-Amz-Signature")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Signature", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Content-Sha256", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Date")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Date", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Credential")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Credential", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Security-Token")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Security-Token", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Algorithm")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Algorithm", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-SignedHeaders", valid_593623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593624: Call_DeleteClientCertificate_593613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_593624.validator(path, query, header, formData, body)
  let scheme = call_593624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593624.url(scheme.get, call_593624.host, call_593624.base,
                         call_593624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593624, url, valid)

proc call*(call_593625: Call_DeleteClientCertificate_593613;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_593626 = newJObject()
  add(path_593626, "clientcertificate_id", newJString(clientcertificateId))
  result = call_593625.call(path_593626, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_593613(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_593614, base: "/",
    url: url_DeleteClientCertificate_593615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_593643 = ref object of OpenApiRestCall_592348
proc url_GetDeployment_593645(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_593644(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593646 = path.getOrDefault("deployment_id")
  valid_593646 = validateParameter(valid_593646, JString, required = true,
                                 default = nil)
  if valid_593646 != nil:
    section.add "deployment_id", valid_593646
  var valid_593647 = path.getOrDefault("restapi_id")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = nil)
  if valid_593647 != nil:
    section.add "restapi_id", valid_593647
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_593648 = query.getOrDefault("embed")
  valid_593648 = validateParameter(valid_593648, JArray, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "embed", valid_593648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593649 = header.getOrDefault("X-Amz-Signature")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Signature", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Content-Sha256", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Date")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Date", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Credential")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Credential", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Security-Token")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Security-Token", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Algorithm")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Algorithm", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-SignedHeaders", valid_593655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593656: Call_GetDeployment_593643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_593656.validator(path, query, header, formData, body)
  let scheme = call_593656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593656.url(scheme.get, call_593656.host, call_593656.base,
                         call_593656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593656, url, valid)

proc call*(call_593657: Call_GetDeployment_593643; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  var path_593658 = newJObject()
  var query_593659 = newJObject()
  add(path_593658, "deployment_id", newJString(deploymentId))
  add(path_593658, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_593659.add "embed", embed
  result = call_593657.call(path_593658, query_593659, nil, nil, nil)

var getDeployment* = Call_GetDeployment_593643(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_593644, base: "/", url: url_GetDeployment_593645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_593675 = ref object of OpenApiRestCall_592348
proc url_UpdateDeployment_593677(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_593676(path: JsonNode; query: JsonNode;
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
  var valid_593678 = path.getOrDefault("deployment_id")
  valid_593678 = validateParameter(valid_593678, JString, required = true,
                                 default = nil)
  if valid_593678 != nil:
    section.add "deployment_id", valid_593678
  var valid_593679 = path.getOrDefault("restapi_id")
  valid_593679 = validateParameter(valid_593679, JString, required = true,
                                 default = nil)
  if valid_593679 != nil:
    section.add "restapi_id", valid_593679
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593680 = header.getOrDefault("X-Amz-Signature")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Signature", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Content-Sha256", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Date")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Date", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Credential")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Credential", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Security-Token")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Security-Token", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Algorithm")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Algorithm", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-SignedHeaders", valid_593686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593688: Call_UpdateDeployment_593675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_593688.validator(path, query, header, formData, body)
  let scheme = call_593688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593688.url(scheme.get, call_593688.host, call_593688.base,
                         call_593688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593688, url, valid)

proc call*(call_593689: Call_UpdateDeployment_593675; deploymentId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593690 = newJObject()
  var body_593691 = newJObject()
  add(path_593690, "deployment_id", newJString(deploymentId))
  add(path_593690, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593691 = body
  result = call_593689.call(path_593690, nil, nil, nil, body_593691)

var updateDeployment* = Call_UpdateDeployment_593675(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_593676, base: "/",
    url: url_UpdateDeployment_593677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_593660 = ref object of OpenApiRestCall_592348
proc url_DeleteDeployment_593662(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_593661(path: JsonNode; query: JsonNode;
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
  var valid_593663 = path.getOrDefault("deployment_id")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = nil)
  if valid_593663 != nil:
    section.add "deployment_id", valid_593663
  var valid_593664 = path.getOrDefault("restapi_id")
  valid_593664 = validateParameter(valid_593664, JString, required = true,
                                 default = nil)
  if valid_593664 != nil:
    section.add "restapi_id", valid_593664
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593665 = header.getOrDefault("X-Amz-Signature")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Signature", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Content-Sha256", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Date")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Date", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Credential")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Credential", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Security-Token")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Security-Token", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Algorithm")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Algorithm", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-SignedHeaders", valid_593671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593672: Call_DeleteDeployment_593660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_593672.validator(path, query, header, formData, body)
  let scheme = call_593672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593672.url(scheme.get, call_593672.host, call_593672.base,
                         call_593672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593672, url, valid)

proc call*(call_593673: Call_DeleteDeployment_593660; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593674 = newJObject()
  add(path_593674, "deployment_id", newJString(deploymentId))
  add(path_593674, "restapi_id", newJString(restapiId))
  result = call_593673.call(path_593674, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_593660(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_593661, base: "/",
    url: url_DeleteDeployment_593662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_593692 = ref object of OpenApiRestCall_592348
proc url_GetDocumentationPart_593694(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_593693(path: JsonNode; query: JsonNode;
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
  var valid_593695 = path.getOrDefault("part_id")
  valid_593695 = validateParameter(valid_593695, JString, required = true,
                                 default = nil)
  if valid_593695 != nil:
    section.add "part_id", valid_593695
  var valid_593696 = path.getOrDefault("restapi_id")
  valid_593696 = validateParameter(valid_593696, JString, required = true,
                                 default = nil)
  if valid_593696 != nil:
    section.add "restapi_id", valid_593696
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593697 = header.getOrDefault("X-Amz-Signature")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Signature", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Content-Sha256", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Date")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Date", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Credential")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Credential", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Security-Token")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Security-Token", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-Algorithm")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-Algorithm", valid_593702
  var valid_593703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "X-Amz-SignedHeaders", valid_593703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593704: Call_GetDocumentationPart_593692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593704.validator(path, query, header, formData, body)
  let scheme = call_593704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593704.url(scheme.get, call_593704.host, call_593704.base,
                         call_593704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593704, url, valid)

proc call*(call_593705: Call_GetDocumentationPart_593692; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593706 = newJObject()
  add(path_593706, "part_id", newJString(partId))
  add(path_593706, "restapi_id", newJString(restapiId))
  result = call_593705.call(path_593706, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_593692(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_593693, base: "/",
    url: url_GetDocumentationPart_593694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_593722 = ref object of OpenApiRestCall_592348
proc url_UpdateDocumentationPart_593724(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_593723(path: JsonNode; query: JsonNode;
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
  var valid_593725 = path.getOrDefault("part_id")
  valid_593725 = validateParameter(valid_593725, JString, required = true,
                                 default = nil)
  if valid_593725 != nil:
    section.add "part_id", valid_593725
  var valid_593726 = path.getOrDefault("restapi_id")
  valid_593726 = validateParameter(valid_593726, JString, required = true,
                                 default = nil)
  if valid_593726 != nil:
    section.add "restapi_id", valid_593726
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593727 = header.getOrDefault("X-Amz-Signature")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Signature", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Content-Sha256", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Date")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Date", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-Credential")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Credential", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Security-Token")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Security-Token", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Algorithm")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Algorithm", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-SignedHeaders", valid_593733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593735: Call_UpdateDocumentationPart_593722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593735.validator(path, query, header, formData, body)
  let scheme = call_593735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593735.url(scheme.get, call_593735.host, call_593735.base,
                         call_593735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593735, url, valid)

proc call*(call_593736: Call_UpdateDocumentationPart_593722; partId: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_593737 = newJObject()
  var body_593738 = newJObject()
  add(path_593737, "part_id", newJString(partId))
  add(path_593737, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593738 = body
  result = call_593736.call(path_593737, nil, nil, nil, body_593738)

var updateDocumentationPart* = Call_UpdateDocumentationPart_593722(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_593723, base: "/",
    url: url_UpdateDocumentationPart_593724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_593707 = ref object of OpenApiRestCall_592348
proc url_DeleteDocumentationPart_593709(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_593708(path: JsonNode; query: JsonNode;
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
  var valid_593710 = path.getOrDefault("part_id")
  valid_593710 = validateParameter(valid_593710, JString, required = true,
                                 default = nil)
  if valid_593710 != nil:
    section.add "part_id", valid_593710
  var valid_593711 = path.getOrDefault("restapi_id")
  valid_593711 = validateParameter(valid_593711, JString, required = true,
                                 default = nil)
  if valid_593711 != nil:
    section.add "restapi_id", valid_593711
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593712 = header.getOrDefault("X-Amz-Signature")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Signature", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Content-Sha256", valid_593713
  var valid_593714 = header.getOrDefault("X-Amz-Date")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "X-Amz-Date", valid_593714
  var valid_593715 = header.getOrDefault("X-Amz-Credential")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Credential", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-Security-Token")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-Security-Token", valid_593716
  var valid_593717 = header.getOrDefault("X-Amz-Algorithm")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "X-Amz-Algorithm", valid_593717
  var valid_593718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "X-Amz-SignedHeaders", valid_593718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593719: Call_DeleteDocumentationPart_593707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593719.validator(path, query, header, formData, body)
  let scheme = call_593719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593719.url(scheme.get, call_593719.host, call_593719.base,
                         call_593719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593719, url, valid)

proc call*(call_593720: Call_DeleteDocumentationPart_593707; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593721 = newJObject()
  add(path_593721, "part_id", newJString(partId))
  add(path_593721, "restapi_id", newJString(restapiId))
  result = call_593720.call(path_593721, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_593707(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_593708, base: "/",
    url: url_DeleteDocumentationPart_593709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_593739 = ref object of OpenApiRestCall_592348
proc url_GetDocumentationVersion_593741(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_593740(path: JsonNode; query: JsonNode;
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
  var valid_593742 = path.getOrDefault("doc_version")
  valid_593742 = validateParameter(valid_593742, JString, required = true,
                                 default = nil)
  if valid_593742 != nil:
    section.add "doc_version", valid_593742
  var valid_593743 = path.getOrDefault("restapi_id")
  valid_593743 = validateParameter(valid_593743, JString, required = true,
                                 default = nil)
  if valid_593743 != nil:
    section.add "restapi_id", valid_593743
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593744 = header.getOrDefault("X-Amz-Signature")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Signature", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Content-Sha256", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Date")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Date", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Credential")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Credential", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Security-Token")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Security-Token", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Algorithm")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Algorithm", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-SignedHeaders", valid_593750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593751: Call_GetDocumentationVersion_593739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593751.validator(path, query, header, formData, body)
  let scheme = call_593751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593751.url(scheme.get, call_593751.host, call_593751.base,
                         call_593751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593751, url, valid)

proc call*(call_593752: Call_GetDocumentationVersion_593739; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593753 = newJObject()
  add(path_593753, "doc_version", newJString(docVersion))
  add(path_593753, "restapi_id", newJString(restapiId))
  result = call_593752.call(path_593753, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_593739(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_593740, base: "/",
    url: url_GetDocumentationVersion_593741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_593769 = ref object of OpenApiRestCall_592348
proc url_UpdateDocumentationVersion_593771(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_593770(path: JsonNode; query: JsonNode;
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
  var valid_593772 = path.getOrDefault("doc_version")
  valid_593772 = validateParameter(valid_593772, JString, required = true,
                                 default = nil)
  if valid_593772 != nil:
    section.add "doc_version", valid_593772
  var valid_593773 = path.getOrDefault("restapi_id")
  valid_593773 = validateParameter(valid_593773, JString, required = true,
                                 default = nil)
  if valid_593773 != nil:
    section.add "restapi_id", valid_593773
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593774 = header.getOrDefault("X-Amz-Signature")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Signature", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Content-Sha256", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Date")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Date", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Credential")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Credential", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-Security-Token")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-Security-Token", valid_593778
  var valid_593779 = header.getOrDefault("X-Amz-Algorithm")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "X-Amz-Algorithm", valid_593779
  var valid_593780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-SignedHeaders", valid_593780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593782: Call_UpdateDocumentationVersion_593769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593782.validator(path, query, header, formData, body)
  let scheme = call_593782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593782.url(scheme.get, call_593782.host, call_593782.base,
                         call_593782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593782, url, valid)

proc call*(call_593783: Call_UpdateDocumentationVersion_593769; docVersion: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  ##   body: JObject (required)
  var path_593784 = newJObject()
  var body_593785 = newJObject()
  add(path_593784, "doc_version", newJString(docVersion))
  add(path_593784, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593785 = body
  result = call_593783.call(path_593784, nil, nil, nil, body_593785)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_593769(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_593770, base: "/",
    url: url_UpdateDocumentationVersion_593771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_593754 = ref object of OpenApiRestCall_592348
proc url_DeleteDocumentationVersion_593756(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_593755(path: JsonNode; query: JsonNode;
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
  var valid_593757 = path.getOrDefault("doc_version")
  valid_593757 = validateParameter(valid_593757, JString, required = true,
                                 default = nil)
  if valid_593757 != nil:
    section.add "doc_version", valid_593757
  var valid_593758 = path.getOrDefault("restapi_id")
  valid_593758 = validateParameter(valid_593758, JString, required = true,
                                 default = nil)
  if valid_593758 != nil:
    section.add "restapi_id", valid_593758
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593759 = header.getOrDefault("X-Amz-Signature")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Signature", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Content-Sha256", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Date")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Date", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-Credential")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Credential", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-Security-Token")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Security-Token", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Algorithm")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Algorithm", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-SignedHeaders", valid_593765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593766: Call_DeleteDocumentationVersion_593754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593766.validator(path, query, header, formData, body)
  let scheme = call_593766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593766.url(scheme.get, call_593766.host, call_593766.base,
                         call_593766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593766, url, valid)

proc call*(call_593767: Call_DeleteDocumentationVersion_593754; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_593768 = newJObject()
  add(path_593768, "doc_version", newJString(docVersion))
  add(path_593768, "restapi_id", newJString(restapiId))
  result = call_593767.call(path_593768, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_593754(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_593755, base: "/",
    url: url_DeleteDocumentationVersion_593756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_593786 = ref object of OpenApiRestCall_592348
proc url_GetDomainName_593788(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_593787(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593789 = path.getOrDefault("domain_name")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = nil)
  if valid_593789 != nil:
    section.add "domain_name", valid_593789
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593790 = header.getOrDefault("X-Amz-Signature")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Signature", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-Content-Sha256", valid_593791
  var valid_593792 = header.getOrDefault("X-Amz-Date")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "X-Amz-Date", valid_593792
  var valid_593793 = header.getOrDefault("X-Amz-Credential")
  valid_593793 = validateParameter(valid_593793, JString, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "X-Amz-Credential", valid_593793
  var valid_593794 = header.getOrDefault("X-Amz-Security-Token")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "X-Amz-Security-Token", valid_593794
  var valid_593795 = header.getOrDefault("X-Amz-Algorithm")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Algorithm", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-SignedHeaders", valid_593796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593797: Call_GetDomainName_593786; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_593797.validator(path, query, header, formData, body)
  let scheme = call_593797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593797.url(scheme.get, call_593797.host, call_593797.base,
                         call_593797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593797, url, valid)

proc call*(call_593798: Call_GetDomainName_593786; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_593799 = newJObject()
  add(path_593799, "domain_name", newJString(domainName))
  result = call_593798.call(path_593799, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_593786(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_593787,
    base: "/", url: url_GetDomainName_593788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_593814 = ref object of OpenApiRestCall_592348
proc url_UpdateDomainName_593816(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_593815(path: JsonNode; query: JsonNode;
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
  var valid_593817 = path.getOrDefault("domain_name")
  valid_593817 = validateParameter(valid_593817, JString, required = true,
                                 default = nil)
  if valid_593817 != nil:
    section.add "domain_name", valid_593817
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593818 = header.getOrDefault("X-Amz-Signature")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-Signature", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Content-Sha256", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Date")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Date", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Credential")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Credential", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Security-Token")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Security-Token", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-Algorithm")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Algorithm", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-SignedHeaders", valid_593824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593826: Call_UpdateDomainName_593814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_593826.validator(path, query, header, formData, body)
  let scheme = call_593826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593826.url(scheme.get, call_593826.host, call_593826.base,
                         call_593826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593826, url, valid)

proc call*(call_593827: Call_UpdateDomainName_593814; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  var path_593828 = newJObject()
  var body_593829 = newJObject()
  if body != nil:
    body_593829 = body
  add(path_593828, "domain_name", newJString(domainName))
  result = call_593827.call(path_593828, nil, nil, nil, body_593829)

var updateDomainName* = Call_UpdateDomainName_593814(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_593815,
    base: "/", url: url_UpdateDomainName_593816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_593800 = ref object of OpenApiRestCall_592348
proc url_DeleteDomainName_593802(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_593801(path: JsonNode; query: JsonNode;
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
  var valid_593803 = path.getOrDefault("domain_name")
  valid_593803 = validateParameter(valid_593803, JString, required = true,
                                 default = nil)
  if valid_593803 != nil:
    section.add "domain_name", valid_593803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593804 = header.getOrDefault("X-Amz-Signature")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Signature", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Content-Sha256", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Date")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Date", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Credential")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Credential", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-Security-Token")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Security-Token", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Algorithm")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Algorithm", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-SignedHeaders", valid_593810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593811: Call_DeleteDomainName_593800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_593811.validator(path, query, header, formData, body)
  let scheme = call_593811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593811.url(scheme.get, call_593811.host, call_593811.base,
                         call_593811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593811, url, valid)

proc call*(call_593812: Call_DeleteDomainName_593800; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_593813 = newJObject()
  add(path_593813, "domain_name", newJString(domainName))
  result = call_593812.call(path_593813, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_593800(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_593801,
    base: "/", url: url_DeleteDomainName_593802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_593845 = ref object of OpenApiRestCall_592348
proc url_PutGatewayResponse_593847(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_593846(path: JsonNode; query: JsonNode;
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
  var valid_593848 = path.getOrDefault("response_type")
  valid_593848 = validateParameter(valid_593848, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_593848 != nil:
    section.add "response_type", valid_593848
  var valid_593849 = path.getOrDefault("restapi_id")
  valid_593849 = validateParameter(valid_593849, JString, required = true,
                                 default = nil)
  if valid_593849 != nil:
    section.add "restapi_id", valid_593849
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593850 = header.getOrDefault("X-Amz-Signature")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Signature", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Content-Sha256", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Date")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Date", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Credential")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Credential", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Security-Token")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Security-Token", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Algorithm")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Algorithm", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-SignedHeaders", valid_593856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593858: Call_PutGatewayResponse_593845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_593858.validator(path, query, header, formData, body)
  let scheme = call_593858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593858.url(scheme.get, call_593858.host, call_593858.base,
                         call_593858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593858, url, valid)

proc call*(call_593859: Call_PutGatewayResponse_593845; restapiId: string;
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
  var path_593860 = newJObject()
  var body_593861 = newJObject()
  add(path_593860, "response_type", newJString(responseType))
  add(path_593860, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593861 = body
  result = call_593859.call(path_593860, nil, nil, nil, body_593861)

var putGatewayResponse* = Call_PutGatewayResponse_593845(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_593846, base: "/",
    url: url_PutGatewayResponse_593847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_593830 = ref object of OpenApiRestCall_592348
proc url_GetGatewayResponse_593832(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_593831(path: JsonNode; query: JsonNode;
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
  var valid_593833 = path.getOrDefault("response_type")
  valid_593833 = validateParameter(valid_593833, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_593833 != nil:
    section.add "response_type", valid_593833
  var valid_593834 = path.getOrDefault("restapi_id")
  valid_593834 = validateParameter(valid_593834, JString, required = true,
                                 default = nil)
  if valid_593834 != nil:
    section.add "restapi_id", valid_593834
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593835 = header.getOrDefault("X-Amz-Signature")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Signature", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Content-Sha256", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Date")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Date", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Credential")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Credential", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Security-Token")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Security-Token", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Algorithm")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Algorithm", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-SignedHeaders", valid_593841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593842: Call_GetGatewayResponse_593830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_593842.validator(path, query, header, formData, body)
  let scheme = call_593842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593842.url(scheme.get, call_593842.host, call_593842.base,
                         call_593842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593842, url, valid)

proc call*(call_593843: Call_GetGatewayResponse_593830; restapiId: string;
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
  var path_593844 = newJObject()
  add(path_593844, "response_type", newJString(responseType))
  add(path_593844, "restapi_id", newJString(restapiId))
  result = call_593843.call(path_593844, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_593830(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_593831, base: "/",
    url: url_GetGatewayResponse_593832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_593877 = ref object of OpenApiRestCall_592348
proc url_UpdateGatewayResponse_593879(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_593878(path: JsonNode; query: JsonNode;
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
  var valid_593880 = path.getOrDefault("response_type")
  valid_593880 = validateParameter(valid_593880, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_593880 != nil:
    section.add "response_type", valid_593880
  var valid_593881 = path.getOrDefault("restapi_id")
  valid_593881 = validateParameter(valid_593881, JString, required = true,
                                 default = nil)
  if valid_593881 != nil:
    section.add "restapi_id", valid_593881
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593882 = header.getOrDefault("X-Amz-Signature")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-Signature", valid_593882
  var valid_593883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Content-Sha256", valid_593883
  var valid_593884 = header.getOrDefault("X-Amz-Date")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Date", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Credential")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Credential", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Security-Token")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Security-Token", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Algorithm")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Algorithm", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-SignedHeaders", valid_593888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593890: Call_UpdateGatewayResponse_593877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_593890.validator(path, query, header, formData, body)
  let scheme = call_593890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593890.url(scheme.get, call_593890.host, call_593890.base,
                         call_593890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593890, url, valid)

proc call*(call_593891: Call_UpdateGatewayResponse_593877; restapiId: string;
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
  var path_593892 = newJObject()
  var body_593893 = newJObject()
  add(path_593892, "response_type", newJString(responseType))
  add(path_593892, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593893 = body
  result = call_593891.call(path_593892, nil, nil, nil, body_593893)

var updateGatewayResponse* = Call_UpdateGatewayResponse_593877(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_593878, base: "/",
    url: url_UpdateGatewayResponse_593879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_593862 = ref object of OpenApiRestCall_592348
proc url_DeleteGatewayResponse_593864(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_593863(path: JsonNode; query: JsonNode;
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
  var valid_593865 = path.getOrDefault("response_type")
  valid_593865 = validateParameter(valid_593865, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_593865 != nil:
    section.add "response_type", valid_593865
  var valid_593866 = path.getOrDefault("restapi_id")
  valid_593866 = validateParameter(valid_593866, JString, required = true,
                                 default = nil)
  if valid_593866 != nil:
    section.add "restapi_id", valid_593866
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593867 = header.getOrDefault("X-Amz-Signature")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-Signature", valid_593867
  var valid_593868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Content-Sha256", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-Date")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Date", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Credential")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Credential", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Security-Token")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Security-Token", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Algorithm")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Algorithm", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-SignedHeaders", valid_593873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593874: Call_DeleteGatewayResponse_593862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_593874.validator(path, query, header, formData, body)
  let scheme = call_593874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593874.url(scheme.get, call_593874.host, call_593874.base,
                         call_593874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593874, url, valid)

proc call*(call_593875: Call_DeleteGatewayResponse_593862; restapiId: string;
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
  var path_593876 = newJObject()
  add(path_593876, "response_type", newJString(responseType))
  add(path_593876, "restapi_id", newJString(restapiId))
  result = call_593875.call(path_593876, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_593862(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_593863, base: "/",
    url: url_DeleteGatewayResponse_593864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_593910 = ref object of OpenApiRestCall_592348
proc url_PutIntegration_593912(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_593911(path: JsonNode; query: JsonNode;
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
  var valid_593913 = path.getOrDefault("restapi_id")
  valid_593913 = validateParameter(valid_593913, JString, required = true,
                                 default = nil)
  if valid_593913 != nil:
    section.add "restapi_id", valid_593913
  var valid_593914 = path.getOrDefault("resource_id")
  valid_593914 = validateParameter(valid_593914, JString, required = true,
                                 default = nil)
  if valid_593914 != nil:
    section.add "resource_id", valid_593914
  var valid_593915 = path.getOrDefault("http_method")
  valid_593915 = validateParameter(valid_593915, JString, required = true,
                                 default = nil)
  if valid_593915 != nil:
    section.add "http_method", valid_593915
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593916 = header.getOrDefault("X-Amz-Signature")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "X-Amz-Signature", valid_593916
  var valid_593917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "X-Amz-Content-Sha256", valid_593917
  var valid_593918 = header.getOrDefault("X-Amz-Date")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "X-Amz-Date", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-Credential")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Credential", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Security-Token")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Security-Token", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Algorithm")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Algorithm", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-SignedHeaders", valid_593922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593924: Call_PutIntegration_593910; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_593924.validator(path, query, header, formData, body)
  let scheme = call_593924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593924.url(scheme.get, call_593924.host, call_593924.base,
                         call_593924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593924, url, valid)

proc call*(call_593925: Call_PutIntegration_593910; restapiId: string;
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
  var path_593926 = newJObject()
  var body_593927 = newJObject()
  add(path_593926, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593927 = body
  add(path_593926, "resource_id", newJString(resourceId))
  add(path_593926, "http_method", newJString(httpMethod))
  result = call_593925.call(path_593926, nil, nil, nil, body_593927)

var putIntegration* = Call_PutIntegration_593910(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_593911, base: "/", url: url_PutIntegration_593912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_593894 = ref object of OpenApiRestCall_592348
proc url_GetIntegration_593896(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_593895(path: JsonNode; query: JsonNode;
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
  var valid_593897 = path.getOrDefault("restapi_id")
  valid_593897 = validateParameter(valid_593897, JString, required = true,
                                 default = nil)
  if valid_593897 != nil:
    section.add "restapi_id", valid_593897
  var valid_593898 = path.getOrDefault("resource_id")
  valid_593898 = validateParameter(valid_593898, JString, required = true,
                                 default = nil)
  if valid_593898 != nil:
    section.add "resource_id", valid_593898
  var valid_593899 = path.getOrDefault("http_method")
  valid_593899 = validateParameter(valid_593899, JString, required = true,
                                 default = nil)
  if valid_593899 != nil:
    section.add "http_method", valid_593899
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593900 = header.getOrDefault("X-Amz-Signature")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "X-Amz-Signature", valid_593900
  var valid_593901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Content-Sha256", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-Date")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-Date", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-Credential")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Credential", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Security-Token")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Security-Token", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-SignedHeaders", valid_593906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593907: Call_GetIntegration_593894; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_593907.validator(path, query, header, formData, body)
  let scheme = call_593907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593907.url(scheme.get, call_593907.host, call_593907.base,
                         call_593907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593907, url, valid)

proc call*(call_593908: Call_GetIntegration_593894; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  var path_593909 = newJObject()
  add(path_593909, "restapi_id", newJString(restapiId))
  add(path_593909, "resource_id", newJString(resourceId))
  add(path_593909, "http_method", newJString(httpMethod))
  result = call_593908.call(path_593909, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_593894(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_593895, base: "/", url: url_GetIntegration_593896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_593944 = ref object of OpenApiRestCall_592348
proc url_UpdateIntegration_593946(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_593945(path: JsonNode; query: JsonNode;
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
  var valid_593947 = path.getOrDefault("restapi_id")
  valid_593947 = validateParameter(valid_593947, JString, required = true,
                                 default = nil)
  if valid_593947 != nil:
    section.add "restapi_id", valid_593947
  var valid_593948 = path.getOrDefault("resource_id")
  valid_593948 = validateParameter(valid_593948, JString, required = true,
                                 default = nil)
  if valid_593948 != nil:
    section.add "resource_id", valid_593948
  var valid_593949 = path.getOrDefault("http_method")
  valid_593949 = validateParameter(valid_593949, JString, required = true,
                                 default = nil)
  if valid_593949 != nil:
    section.add "http_method", valid_593949
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593950 = header.getOrDefault("X-Amz-Signature")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "X-Amz-Signature", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Content-Sha256", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Date")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Date", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Credential")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Credential", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Security-Token")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Security-Token", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-Algorithm")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-Algorithm", valid_593955
  var valid_593956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "X-Amz-SignedHeaders", valid_593956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593958: Call_UpdateIntegration_593944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_593958.validator(path, query, header, formData, body)
  let scheme = call_593958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593958.url(scheme.get, call_593958.host, call_593958.base,
                         call_593958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593958, url, valid)

proc call*(call_593959: Call_UpdateIntegration_593944; restapiId: string;
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
  var path_593960 = newJObject()
  var body_593961 = newJObject()
  add(path_593960, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593961 = body
  add(path_593960, "resource_id", newJString(resourceId))
  add(path_593960, "http_method", newJString(httpMethod))
  result = call_593959.call(path_593960, nil, nil, nil, body_593961)

var updateIntegration* = Call_UpdateIntegration_593944(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_593945, base: "/",
    url: url_UpdateIntegration_593946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_593928 = ref object of OpenApiRestCall_592348
proc url_DeleteIntegration_593930(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_593929(path: JsonNode; query: JsonNode;
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
  var valid_593931 = path.getOrDefault("restapi_id")
  valid_593931 = validateParameter(valid_593931, JString, required = true,
                                 default = nil)
  if valid_593931 != nil:
    section.add "restapi_id", valid_593931
  var valid_593932 = path.getOrDefault("resource_id")
  valid_593932 = validateParameter(valid_593932, JString, required = true,
                                 default = nil)
  if valid_593932 != nil:
    section.add "resource_id", valid_593932
  var valid_593933 = path.getOrDefault("http_method")
  valid_593933 = validateParameter(valid_593933, JString, required = true,
                                 default = nil)
  if valid_593933 != nil:
    section.add "http_method", valid_593933
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593934 = header.getOrDefault("X-Amz-Signature")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Signature", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-Content-Sha256", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Date")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Date", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Credential")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Credential", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Security-Token")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Security-Token", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Algorithm")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Algorithm", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-SignedHeaders", valid_593940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593941: Call_DeleteIntegration_593928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_593941.validator(path, query, header, formData, body)
  let scheme = call_593941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593941.url(scheme.get, call_593941.host, call_593941.base,
                         call_593941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593941, url, valid)

proc call*(call_593942: Call_DeleteIntegration_593928; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  var path_593943 = newJObject()
  add(path_593943, "restapi_id", newJString(restapiId))
  add(path_593943, "resource_id", newJString(resourceId))
  add(path_593943, "http_method", newJString(httpMethod))
  result = call_593942.call(path_593943, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_593928(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_593929, base: "/",
    url: url_DeleteIntegration_593930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_593979 = ref object of OpenApiRestCall_592348
proc url_PutIntegrationResponse_593981(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_593980(path: JsonNode; query: JsonNode;
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
  var valid_593982 = path.getOrDefault("status_code")
  valid_593982 = validateParameter(valid_593982, JString, required = true,
                                 default = nil)
  if valid_593982 != nil:
    section.add "status_code", valid_593982
  var valid_593983 = path.getOrDefault("restapi_id")
  valid_593983 = validateParameter(valid_593983, JString, required = true,
                                 default = nil)
  if valid_593983 != nil:
    section.add "restapi_id", valid_593983
  var valid_593984 = path.getOrDefault("resource_id")
  valid_593984 = validateParameter(valid_593984, JString, required = true,
                                 default = nil)
  if valid_593984 != nil:
    section.add "resource_id", valid_593984
  var valid_593985 = path.getOrDefault("http_method")
  valid_593985 = validateParameter(valid_593985, JString, required = true,
                                 default = nil)
  if valid_593985 != nil:
    section.add "http_method", valid_593985
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593986 = header.getOrDefault("X-Amz-Signature")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Signature", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Content-Sha256", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Date")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Date", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Credential")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Credential", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Security-Token")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Security-Token", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-Algorithm")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-Algorithm", valid_593991
  var valid_593992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-SignedHeaders", valid_593992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593994: Call_PutIntegrationResponse_593979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_593994.validator(path, query, header, formData, body)
  let scheme = call_593994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593994.url(scheme.get, call_593994.host, call_593994.base,
                         call_593994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593994, url, valid)

proc call*(call_593995: Call_PutIntegrationResponse_593979; statusCode: string;
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
  var path_593996 = newJObject()
  var body_593997 = newJObject()
  add(path_593996, "status_code", newJString(statusCode))
  add(path_593996, "restapi_id", newJString(restapiId))
  if body != nil:
    body_593997 = body
  add(path_593996, "resource_id", newJString(resourceId))
  add(path_593996, "http_method", newJString(httpMethod))
  result = call_593995.call(path_593996, nil, nil, nil, body_593997)

var putIntegrationResponse* = Call_PutIntegrationResponse_593979(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_593980, base: "/",
    url: url_PutIntegrationResponse_593981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_593962 = ref object of OpenApiRestCall_592348
proc url_GetIntegrationResponse_593964(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_593963(path: JsonNode; query: JsonNode;
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
  var valid_593965 = path.getOrDefault("status_code")
  valid_593965 = validateParameter(valid_593965, JString, required = true,
                                 default = nil)
  if valid_593965 != nil:
    section.add "status_code", valid_593965
  var valid_593966 = path.getOrDefault("restapi_id")
  valid_593966 = validateParameter(valid_593966, JString, required = true,
                                 default = nil)
  if valid_593966 != nil:
    section.add "restapi_id", valid_593966
  var valid_593967 = path.getOrDefault("resource_id")
  valid_593967 = validateParameter(valid_593967, JString, required = true,
                                 default = nil)
  if valid_593967 != nil:
    section.add "resource_id", valid_593967
  var valid_593968 = path.getOrDefault("http_method")
  valid_593968 = validateParameter(valid_593968, JString, required = true,
                                 default = nil)
  if valid_593968 != nil:
    section.add "http_method", valid_593968
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593969 = header.getOrDefault("X-Amz-Signature")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-Signature", valid_593969
  var valid_593970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "X-Amz-Content-Sha256", valid_593970
  var valid_593971 = header.getOrDefault("X-Amz-Date")
  valid_593971 = validateParameter(valid_593971, JString, required = false,
                                 default = nil)
  if valid_593971 != nil:
    section.add "X-Amz-Date", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-Credential")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Credential", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-Security-Token")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Security-Token", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Algorithm")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Algorithm", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-SignedHeaders", valid_593975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593976: Call_GetIntegrationResponse_593962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_593976.validator(path, query, header, formData, body)
  let scheme = call_593976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593976.url(scheme.get, call_593976.host, call_593976.base,
                         call_593976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593976, url, valid)

proc call*(call_593977: Call_GetIntegrationResponse_593962; statusCode: string;
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
  var path_593978 = newJObject()
  add(path_593978, "status_code", newJString(statusCode))
  add(path_593978, "restapi_id", newJString(restapiId))
  add(path_593978, "resource_id", newJString(resourceId))
  add(path_593978, "http_method", newJString(httpMethod))
  result = call_593977.call(path_593978, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_593962(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_593963, base: "/",
    url: url_GetIntegrationResponse_593964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_594015 = ref object of OpenApiRestCall_592348
proc url_UpdateIntegrationResponse_594017(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_594016(path: JsonNode; query: JsonNode;
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
  var valid_594018 = path.getOrDefault("status_code")
  valid_594018 = validateParameter(valid_594018, JString, required = true,
                                 default = nil)
  if valid_594018 != nil:
    section.add "status_code", valid_594018
  var valid_594019 = path.getOrDefault("restapi_id")
  valid_594019 = validateParameter(valid_594019, JString, required = true,
                                 default = nil)
  if valid_594019 != nil:
    section.add "restapi_id", valid_594019
  var valid_594020 = path.getOrDefault("resource_id")
  valid_594020 = validateParameter(valid_594020, JString, required = true,
                                 default = nil)
  if valid_594020 != nil:
    section.add "resource_id", valid_594020
  var valid_594021 = path.getOrDefault("http_method")
  valid_594021 = validateParameter(valid_594021, JString, required = true,
                                 default = nil)
  if valid_594021 != nil:
    section.add "http_method", valid_594021
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594022 = header.getOrDefault("X-Amz-Signature")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Signature", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Content-Sha256", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Date")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Date", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Credential")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Credential", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-Security-Token")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-Security-Token", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-Algorithm")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Algorithm", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-SignedHeaders", valid_594028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594030: Call_UpdateIntegrationResponse_594015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_594030.validator(path, query, header, formData, body)
  let scheme = call_594030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594030.url(scheme.get, call_594030.host, call_594030.base,
                         call_594030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594030, url, valid)

proc call*(call_594031: Call_UpdateIntegrationResponse_594015; statusCode: string;
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
  var path_594032 = newJObject()
  var body_594033 = newJObject()
  add(path_594032, "status_code", newJString(statusCode))
  add(path_594032, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594033 = body
  add(path_594032, "resource_id", newJString(resourceId))
  add(path_594032, "http_method", newJString(httpMethod))
  result = call_594031.call(path_594032, nil, nil, nil, body_594033)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_594015(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_594016, base: "/",
    url: url_UpdateIntegrationResponse_594017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_593998 = ref object of OpenApiRestCall_592348
proc url_DeleteIntegrationResponse_594000(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_593999(path: JsonNode; query: JsonNode;
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
  var valid_594001 = path.getOrDefault("status_code")
  valid_594001 = validateParameter(valid_594001, JString, required = true,
                                 default = nil)
  if valid_594001 != nil:
    section.add "status_code", valid_594001
  var valid_594002 = path.getOrDefault("restapi_id")
  valid_594002 = validateParameter(valid_594002, JString, required = true,
                                 default = nil)
  if valid_594002 != nil:
    section.add "restapi_id", valid_594002
  var valid_594003 = path.getOrDefault("resource_id")
  valid_594003 = validateParameter(valid_594003, JString, required = true,
                                 default = nil)
  if valid_594003 != nil:
    section.add "resource_id", valid_594003
  var valid_594004 = path.getOrDefault("http_method")
  valid_594004 = validateParameter(valid_594004, JString, required = true,
                                 default = nil)
  if valid_594004 != nil:
    section.add "http_method", valid_594004
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594005 = header.getOrDefault("X-Amz-Signature")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Signature", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Content-Sha256", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Date")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Date", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Credential")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Credential", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Security-Token")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Security-Token", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Algorithm")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Algorithm", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-SignedHeaders", valid_594011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594012: Call_DeleteIntegrationResponse_593998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_594012.validator(path, query, header, formData, body)
  let scheme = call_594012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594012.url(scheme.get, call_594012.host, call_594012.base,
                         call_594012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594012, url, valid)

proc call*(call_594013: Call_DeleteIntegrationResponse_593998; statusCode: string;
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
  var path_594014 = newJObject()
  add(path_594014, "status_code", newJString(statusCode))
  add(path_594014, "restapi_id", newJString(restapiId))
  add(path_594014, "resource_id", newJString(resourceId))
  add(path_594014, "http_method", newJString(httpMethod))
  result = call_594013.call(path_594014, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_593998(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_593999, base: "/",
    url: url_DeleteIntegrationResponse_594000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_594050 = ref object of OpenApiRestCall_592348
proc url_PutMethod_594052(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_594051(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594053 = path.getOrDefault("restapi_id")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = nil)
  if valid_594053 != nil:
    section.add "restapi_id", valid_594053
  var valid_594054 = path.getOrDefault("resource_id")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = nil)
  if valid_594054 != nil:
    section.add "resource_id", valid_594054
  var valid_594055 = path.getOrDefault("http_method")
  valid_594055 = validateParameter(valid_594055, JString, required = true,
                                 default = nil)
  if valid_594055 != nil:
    section.add "http_method", valid_594055
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594056 = header.getOrDefault("X-Amz-Signature")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Signature", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Content-Sha256", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Date")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Date", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Credential")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Credential", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Security-Token")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Security-Token", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Algorithm")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Algorithm", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-SignedHeaders", valid_594062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594064: Call_PutMethod_594050; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_594064.validator(path, query, header, formData, body)
  let scheme = call_594064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594064.url(scheme.get, call_594064.host, call_594064.base,
                         call_594064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594064, url, valid)

proc call*(call_594065: Call_PutMethod_594050; restapiId: string; body: JsonNode;
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
  var path_594066 = newJObject()
  var body_594067 = newJObject()
  add(path_594066, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594067 = body
  add(path_594066, "resource_id", newJString(resourceId))
  add(path_594066, "http_method", newJString(httpMethod))
  result = call_594065.call(path_594066, nil, nil, nil, body_594067)

var putMethod* = Call_PutMethod_594050(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_594051,
                                    base: "/", url: url_PutMethod_594052,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_594068 = ref object of OpenApiRestCall_592348
proc url_TestInvokeMethod_594070(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_594069(path: JsonNode; query: JsonNode;
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
  var valid_594071 = path.getOrDefault("restapi_id")
  valid_594071 = validateParameter(valid_594071, JString, required = true,
                                 default = nil)
  if valid_594071 != nil:
    section.add "restapi_id", valid_594071
  var valid_594072 = path.getOrDefault("resource_id")
  valid_594072 = validateParameter(valid_594072, JString, required = true,
                                 default = nil)
  if valid_594072 != nil:
    section.add "resource_id", valid_594072
  var valid_594073 = path.getOrDefault("http_method")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = nil)
  if valid_594073 != nil:
    section.add "http_method", valid_594073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Content-Sha256", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Credential")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Credential", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Security-Token")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Security-Token", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Algorithm")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Algorithm", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-SignedHeaders", valid_594080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594082: Call_TestInvokeMethod_594068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_594082.validator(path, query, header, formData, body)
  let scheme = call_594082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594082.url(scheme.get, call_594082.host, call_594082.base,
                         call_594082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594082, url, valid)

proc call*(call_594083: Call_TestInvokeMethod_594068; restapiId: string;
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
  var path_594084 = newJObject()
  var body_594085 = newJObject()
  add(path_594084, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594085 = body
  add(path_594084, "resource_id", newJString(resourceId))
  add(path_594084, "http_method", newJString(httpMethod))
  result = call_594083.call(path_594084, nil, nil, nil, body_594085)

var testInvokeMethod* = Call_TestInvokeMethod_594068(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_594069, base: "/",
    url: url_TestInvokeMethod_594070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_594034 = ref object of OpenApiRestCall_592348
proc url_GetMethod_594036(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_594035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594037 = path.getOrDefault("restapi_id")
  valid_594037 = validateParameter(valid_594037, JString, required = true,
                                 default = nil)
  if valid_594037 != nil:
    section.add "restapi_id", valid_594037
  var valid_594038 = path.getOrDefault("resource_id")
  valid_594038 = validateParameter(valid_594038, JString, required = true,
                                 default = nil)
  if valid_594038 != nil:
    section.add "resource_id", valid_594038
  var valid_594039 = path.getOrDefault("http_method")
  valid_594039 = validateParameter(valid_594039, JString, required = true,
                                 default = nil)
  if valid_594039 != nil:
    section.add "http_method", valid_594039
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594040 = header.getOrDefault("X-Amz-Signature")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Signature", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Content-Sha256", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Date")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Date", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Credential")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Credential", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Security-Token")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Security-Token", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Algorithm")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Algorithm", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-SignedHeaders", valid_594046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594047: Call_GetMethod_594034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_594047.validator(path, query, header, formData, body)
  let scheme = call_594047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594047.url(scheme.get, call_594047.host, call_594047.base,
                         call_594047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594047, url, valid)

proc call*(call_594048: Call_GetMethod_594034; restapiId: string; resourceId: string;
          httpMethod: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  var path_594049 = newJObject()
  add(path_594049, "restapi_id", newJString(restapiId))
  add(path_594049, "resource_id", newJString(resourceId))
  add(path_594049, "http_method", newJString(httpMethod))
  result = call_594048.call(path_594049, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_594034(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_594035,
                                    base: "/", url: url_GetMethod_594036,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_594102 = ref object of OpenApiRestCall_592348
proc url_UpdateMethod_594104(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_594103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594105 = path.getOrDefault("restapi_id")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = nil)
  if valid_594105 != nil:
    section.add "restapi_id", valid_594105
  var valid_594106 = path.getOrDefault("resource_id")
  valid_594106 = validateParameter(valid_594106, JString, required = true,
                                 default = nil)
  if valid_594106 != nil:
    section.add "resource_id", valid_594106
  var valid_594107 = path.getOrDefault("http_method")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = nil)
  if valid_594107 != nil:
    section.add "http_method", valid_594107
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594108 = header.getOrDefault("X-Amz-Signature")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Signature", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Credential")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Credential", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Security-Token")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Security-Token", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_UpdateMethod_594102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_UpdateMethod_594102; restapiId: string; body: JsonNode;
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
  var path_594118 = newJObject()
  var body_594119 = newJObject()
  add(path_594118, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594119 = body
  add(path_594118, "resource_id", newJString(resourceId))
  add(path_594118, "http_method", newJString(httpMethod))
  result = call_594117.call(path_594118, nil, nil, nil, body_594119)

var updateMethod* = Call_UpdateMethod_594102(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_594103, base: "/", url: url_UpdateMethod_594104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_594086 = ref object of OpenApiRestCall_592348
proc url_DeleteMethod_594088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_594087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594089 = path.getOrDefault("restapi_id")
  valid_594089 = validateParameter(valid_594089, JString, required = true,
                                 default = nil)
  if valid_594089 != nil:
    section.add "restapi_id", valid_594089
  var valid_594090 = path.getOrDefault("resource_id")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = nil)
  if valid_594090 != nil:
    section.add "resource_id", valid_594090
  var valid_594091 = path.getOrDefault("http_method")
  valid_594091 = validateParameter(valid_594091, JString, required = true,
                                 default = nil)
  if valid_594091 != nil:
    section.add "http_method", valid_594091
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594092 = header.getOrDefault("X-Amz-Signature")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Signature", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Content-Sha256", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Date")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Date", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Credential")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Credential", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Security-Token")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Security-Token", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Algorithm")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Algorithm", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_DeleteMethod_594086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_DeleteMethod_594086; restapiId: string;
          resourceId: string; httpMethod: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  var path_594101 = newJObject()
  add(path_594101, "restapi_id", newJString(restapiId))
  add(path_594101, "resource_id", newJString(resourceId))
  add(path_594101, "http_method", newJString(httpMethod))
  result = call_594100.call(path_594101, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_594086(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_594087, base: "/", url: url_DeleteMethod_594088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_594137 = ref object of OpenApiRestCall_592348
proc url_PutMethodResponse_594139(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_594138(path: JsonNode; query: JsonNode;
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
  var valid_594140 = path.getOrDefault("status_code")
  valid_594140 = validateParameter(valid_594140, JString, required = true,
                                 default = nil)
  if valid_594140 != nil:
    section.add "status_code", valid_594140
  var valid_594141 = path.getOrDefault("restapi_id")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "restapi_id", valid_594141
  var valid_594142 = path.getOrDefault("resource_id")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "resource_id", valid_594142
  var valid_594143 = path.getOrDefault("http_method")
  valid_594143 = validateParameter(valid_594143, JString, required = true,
                                 default = nil)
  if valid_594143 != nil:
    section.add "http_method", valid_594143
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594144 = header.getOrDefault("X-Amz-Signature")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Signature", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594152: Call_PutMethodResponse_594137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_PutMethodResponse_594137; statusCode: string;
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
  var path_594154 = newJObject()
  var body_594155 = newJObject()
  add(path_594154, "status_code", newJString(statusCode))
  add(path_594154, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594155 = body
  add(path_594154, "resource_id", newJString(resourceId))
  add(path_594154, "http_method", newJString(httpMethod))
  result = call_594153.call(path_594154, nil, nil, nil, body_594155)

var putMethodResponse* = Call_PutMethodResponse_594137(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_594138, base: "/",
    url: url_PutMethodResponse_594139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_594120 = ref object of OpenApiRestCall_592348
proc url_GetMethodResponse_594122(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_594121(path: JsonNode; query: JsonNode;
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
  var valid_594123 = path.getOrDefault("status_code")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = nil)
  if valid_594123 != nil:
    section.add "status_code", valid_594123
  var valid_594124 = path.getOrDefault("restapi_id")
  valid_594124 = validateParameter(valid_594124, JString, required = true,
                                 default = nil)
  if valid_594124 != nil:
    section.add "restapi_id", valid_594124
  var valid_594125 = path.getOrDefault("resource_id")
  valid_594125 = validateParameter(valid_594125, JString, required = true,
                                 default = nil)
  if valid_594125 != nil:
    section.add "resource_id", valid_594125
  var valid_594126 = path.getOrDefault("http_method")
  valid_594126 = validateParameter(valid_594126, JString, required = true,
                                 default = nil)
  if valid_594126 != nil:
    section.add "http_method", valid_594126
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Content-Sha256", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Date")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Date", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Credential")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Credential", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Algorithm")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Algorithm", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_GetMethodResponse_594120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_GetMethodResponse_594120; statusCode: string;
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
  var path_594136 = newJObject()
  add(path_594136, "status_code", newJString(statusCode))
  add(path_594136, "restapi_id", newJString(restapiId))
  add(path_594136, "resource_id", newJString(resourceId))
  add(path_594136, "http_method", newJString(httpMethod))
  result = call_594135.call(path_594136, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_594120(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_594121, base: "/",
    url: url_GetMethodResponse_594122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_594173 = ref object of OpenApiRestCall_592348
proc url_UpdateMethodResponse_594175(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_594174(path: JsonNode; query: JsonNode;
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
  var valid_594176 = path.getOrDefault("status_code")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "status_code", valid_594176
  var valid_594177 = path.getOrDefault("restapi_id")
  valid_594177 = validateParameter(valid_594177, JString, required = true,
                                 default = nil)
  if valid_594177 != nil:
    section.add "restapi_id", valid_594177
  var valid_594178 = path.getOrDefault("resource_id")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = nil)
  if valid_594178 != nil:
    section.add "resource_id", valid_594178
  var valid_594179 = path.getOrDefault("http_method")
  valid_594179 = validateParameter(valid_594179, JString, required = true,
                                 default = nil)
  if valid_594179 != nil:
    section.add "http_method", valid_594179
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594188: Call_UpdateMethodResponse_594173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_594188.validator(path, query, header, formData, body)
  let scheme = call_594188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594188.url(scheme.get, call_594188.host, call_594188.base,
                         call_594188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594188, url, valid)

proc call*(call_594189: Call_UpdateMethodResponse_594173; statusCode: string;
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
  var path_594190 = newJObject()
  var body_594191 = newJObject()
  add(path_594190, "status_code", newJString(statusCode))
  add(path_594190, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594191 = body
  add(path_594190, "resource_id", newJString(resourceId))
  add(path_594190, "http_method", newJString(httpMethod))
  result = call_594189.call(path_594190, nil, nil, nil, body_594191)

var updateMethodResponse* = Call_UpdateMethodResponse_594173(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_594174, base: "/",
    url: url_UpdateMethodResponse_594175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_594156 = ref object of OpenApiRestCall_592348
proc url_DeleteMethodResponse_594158(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_594157(path: JsonNode; query: JsonNode;
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
  var valid_594159 = path.getOrDefault("status_code")
  valid_594159 = validateParameter(valid_594159, JString, required = true,
                                 default = nil)
  if valid_594159 != nil:
    section.add "status_code", valid_594159
  var valid_594160 = path.getOrDefault("restapi_id")
  valid_594160 = validateParameter(valid_594160, JString, required = true,
                                 default = nil)
  if valid_594160 != nil:
    section.add "restapi_id", valid_594160
  var valid_594161 = path.getOrDefault("resource_id")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "resource_id", valid_594161
  var valid_594162 = path.getOrDefault("http_method")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "http_method", valid_594162
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594163 = header.getOrDefault("X-Amz-Signature")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Signature", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Content-Sha256", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Date")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Date", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Credential")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Credential", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Algorithm")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Algorithm", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-SignedHeaders", valid_594169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594170: Call_DeleteMethodResponse_594156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_594170.validator(path, query, header, formData, body)
  let scheme = call_594170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594170.url(scheme.get, call_594170.host, call_594170.base,
                         call_594170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594170, url, valid)

proc call*(call_594171: Call_DeleteMethodResponse_594156; statusCode: string;
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
  var path_594172 = newJObject()
  add(path_594172, "status_code", newJString(statusCode))
  add(path_594172, "restapi_id", newJString(restapiId))
  add(path_594172, "resource_id", newJString(resourceId))
  add(path_594172, "http_method", newJString(httpMethod))
  result = call_594171.call(path_594172, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_594156(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_594157, base: "/",
    url: url_DeleteMethodResponse_594158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_594192 = ref object of OpenApiRestCall_592348
proc url_GetModel_594194(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_594193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594195 = path.getOrDefault("model_name")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = nil)
  if valid_594195 != nil:
    section.add "model_name", valid_594195
  var valid_594196 = path.getOrDefault("restapi_id")
  valid_594196 = validateParameter(valid_594196, JString, required = true,
                                 default = nil)
  if valid_594196 != nil:
    section.add "restapi_id", valid_594196
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_594197 = query.getOrDefault("flatten")
  valid_594197 = validateParameter(valid_594197, JBool, required = false, default = nil)
  if valid_594197 != nil:
    section.add "flatten", valid_594197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594198 = header.getOrDefault("X-Amz-Signature")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Signature", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Date")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Date", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Credential")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Credential", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Security-Token")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Security-Token", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Algorithm")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Algorithm", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-SignedHeaders", valid_594204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_GetModel_594192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_GetModel_594192; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_594207 = newJObject()
  var query_594208 = newJObject()
  add(query_594208, "flatten", newJBool(flatten))
  add(path_594207, "model_name", newJString(modelName))
  add(path_594207, "restapi_id", newJString(restapiId))
  result = call_594206.call(path_594207, query_594208, nil, nil, nil)

var getModel* = Call_GetModel_594192(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_594193, base: "/",
                                  url: url_GetModel_594194,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_594224 = ref object of OpenApiRestCall_592348
proc url_UpdateModel_594226(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_594225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594227 = path.getOrDefault("model_name")
  valid_594227 = validateParameter(valid_594227, JString, required = true,
                                 default = nil)
  if valid_594227 != nil:
    section.add "model_name", valid_594227
  var valid_594228 = path.getOrDefault("restapi_id")
  valid_594228 = validateParameter(valid_594228, JString, required = true,
                                 default = nil)
  if valid_594228 != nil:
    section.add "restapi_id", valid_594228
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594229 = header.getOrDefault("X-Amz-Signature")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Signature", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Content-Sha256", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Date")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Date", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Credential")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Credential", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Security-Token")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Security-Token", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-Algorithm")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Algorithm", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-SignedHeaders", valid_594235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594237: Call_UpdateModel_594224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_594237.validator(path, query, header, formData, body)
  let scheme = call_594237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594237.url(scheme.get, call_594237.host, call_594237.base,
                         call_594237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594237, url, valid)

proc call*(call_594238: Call_UpdateModel_594224; modelName: string;
          restapiId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_594239 = newJObject()
  var body_594240 = newJObject()
  add(path_594239, "model_name", newJString(modelName))
  add(path_594239, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594240 = body
  result = call_594238.call(path_594239, nil, nil, nil, body_594240)

var updateModel* = Call_UpdateModel_594224(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_594225,
                                        base: "/", url: url_UpdateModel_594226,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_594209 = ref object of OpenApiRestCall_592348
proc url_DeleteModel_594211(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_594210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594212 = path.getOrDefault("model_name")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = nil)
  if valid_594212 != nil:
    section.add "model_name", valid_594212
  var valid_594213 = path.getOrDefault("restapi_id")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = nil)
  if valid_594213 != nil:
    section.add "restapi_id", valid_594213
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594214 = header.getOrDefault("X-Amz-Signature")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Signature", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Content-Sha256", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Date")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Date", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Credential")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Credential", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Security-Token")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Security-Token", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Algorithm")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Algorithm", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-SignedHeaders", valid_594220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594221: Call_DeleteModel_594209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_594221.validator(path, query, header, formData, body)
  let scheme = call_594221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594221.url(scheme.get, call_594221.host, call_594221.base,
                         call_594221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594221, url, valid)

proc call*(call_594222: Call_DeleteModel_594209; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594223 = newJObject()
  add(path_594223, "model_name", newJString(modelName))
  add(path_594223, "restapi_id", newJString(restapiId))
  result = call_594222.call(path_594223, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_594209(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_594210,
                                        base: "/", url: url_DeleteModel_594211,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_594241 = ref object of OpenApiRestCall_592348
proc url_GetRequestValidator_594243(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_594242(path: JsonNode; query: JsonNode;
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
  var valid_594244 = path.getOrDefault("restapi_id")
  valid_594244 = validateParameter(valid_594244, JString, required = true,
                                 default = nil)
  if valid_594244 != nil:
    section.add "restapi_id", valid_594244
  var valid_594245 = path.getOrDefault("requestvalidator_id")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = nil)
  if valid_594245 != nil:
    section.add "requestvalidator_id", valid_594245
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Content-Sha256", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Date")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Date", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Security-Token")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Security-Token", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Algorithm")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Algorithm", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-SignedHeaders", valid_594252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594253: Call_GetRequestValidator_594241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_594253.validator(path, query, header, formData, body)
  let scheme = call_594253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594253.url(scheme.get, call_594253.host, call_594253.base,
                         call_594253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594253, url, valid)

proc call*(call_594254: Call_GetRequestValidator_594241; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  var path_594255 = newJObject()
  add(path_594255, "restapi_id", newJString(restapiId))
  add(path_594255, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_594254.call(path_594255, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_594241(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_594242, base: "/",
    url: url_GetRequestValidator_594243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_594271 = ref object of OpenApiRestCall_592348
proc url_UpdateRequestValidator_594273(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_594272(path: JsonNode; query: JsonNode;
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
  var valid_594274 = path.getOrDefault("restapi_id")
  valid_594274 = validateParameter(valid_594274, JString, required = true,
                                 default = nil)
  if valid_594274 != nil:
    section.add "restapi_id", valid_594274
  var valid_594275 = path.getOrDefault("requestvalidator_id")
  valid_594275 = validateParameter(valid_594275, JString, required = true,
                                 default = nil)
  if valid_594275 != nil:
    section.add "requestvalidator_id", valid_594275
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Content-Sha256", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Date")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Date", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Credential")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Credential", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Security-Token")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Security-Token", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Algorithm")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Algorithm", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-SignedHeaders", valid_594282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594284: Call_UpdateRequestValidator_594271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_594284.validator(path, query, header, formData, body)
  let scheme = call_594284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594284.url(scheme.get, call_594284.host, call_594284.base,
                         call_594284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594284, url, valid)

proc call*(call_594285: Call_UpdateRequestValidator_594271; restapiId: string;
          requestvalidatorId: string; body: JsonNode): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  var path_594286 = newJObject()
  var body_594287 = newJObject()
  add(path_594286, "restapi_id", newJString(restapiId))
  add(path_594286, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_594287 = body
  result = call_594285.call(path_594286, nil, nil, nil, body_594287)

var updateRequestValidator* = Call_UpdateRequestValidator_594271(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_594272, base: "/",
    url: url_UpdateRequestValidator_594273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_594256 = ref object of OpenApiRestCall_592348
proc url_DeleteRequestValidator_594258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_594257(path: JsonNode; query: JsonNode;
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
  var valid_594259 = path.getOrDefault("restapi_id")
  valid_594259 = validateParameter(valid_594259, JString, required = true,
                                 default = nil)
  if valid_594259 != nil:
    section.add "restapi_id", valid_594259
  var valid_594260 = path.getOrDefault("requestvalidator_id")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = nil)
  if valid_594260 != nil:
    section.add "requestvalidator_id", valid_594260
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Content-Sha256", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Credential")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Credential", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Security-Token")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Security-Token", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-SignedHeaders", valid_594267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594268: Call_DeleteRequestValidator_594256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_594268.validator(path, query, header, formData, body)
  let scheme = call_594268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594268.url(scheme.get, call_594268.host, call_594268.base,
                         call_594268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594268, url, valid)

proc call*(call_594269: Call_DeleteRequestValidator_594256; restapiId: string;
          requestvalidatorId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  var path_594270 = newJObject()
  add(path_594270, "restapi_id", newJString(restapiId))
  add(path_594270, "requestvalidator_id", newJString(requestvalidatorId))
  result = call_594269.call(path_594270, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_594256(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_594257, base: "/",
    url: url_DeleteRequestValidator_594258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_594288 = ref object of OpenApiRestCall_592348
proc url_GetResource_594290(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_594289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594291 = path.getOrDefault("restapi_id")
  valid_594291 = validateParameter(valid_594291, JString, required = true,
                                 default = nil)
  if valid_594291 != nil:
    section.add "restapi_id", valid_594291
  var valid_594292 = path.getOrDefault("resource_id")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = nil)
  if valid_594292 != nil:
    section.add "resource_id", valid_594292
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_594293 = query.getOrDefault("embed")
  valid_594293 = validateParameter(valid_594293, JArray, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "embed", valid_594293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594294 = header.getOrDefault("X-Amz-Signature")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Signature", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Content-Sha256", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Date")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Date", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Credential")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Credential", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Security-Token")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Security-Token", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Algorithm")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Algorithm", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-SignedHeaders", valid_594300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594301: Call_GetResource_594288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_594301.validator(path, query, header, formData, body)
  let scheme = call_594301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594301.url(scheme.get, call_594301.host, call_594301.base,
                         call_594301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594301, url, valid)

proc call*(call_594302: Call_GetResource_594288; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_594303 = newJObject()
  var query_594304 = newJObject()
  add(path_594303, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_594304.add "embed", embed
  add(path_594303, "resource_id", newJString(resourceId))
  result = call_594302.call(path_594303, query_594304, nil, nil, nil)

var getResource* = Call_GetResource_594288(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_594289,
                                        base: "/", url: url_GetResource_594290,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_594320 = ref object of OpenApiRestCall_592348
proc url_UpdateResource_594322(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_594321(path: JsonNode; query: JsonNode;
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
  var valid_594323 = path.getOrDefault("restapi_id")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = nil)
  if valid_594323 != nil:
    section.add "restapi_id", valid_594323
  var valid_594324 = path.getOrDefault("resource_id")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = nil)
  if valid_594324 != nil:
    section.add "resource_id", valid_594324
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594325 = header.getOrDefault("X-Amz-Signature")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Signature", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Content-Sha256", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Date")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Date", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Credential")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Credential", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Security-Token")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Security-Token", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Algorithm")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Algorithm", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-SignedHeaders", valid_594331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594333: Call_UpdateResource_594320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_594333.validator(path, query, header, formData, body)
  let scheme = call_594333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594333.url(scheme.get, call_594333.host, call_594333.base,
                         call_594333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594333, url, valid)

proc call*(call_594334: Call_UpdateResource_594320; restapiId: string;
          body: JsonNode; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_594335 = newJObject()
  var body_594336 = newJObject()
  add(path_594335, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594336 = body
  add(path_594335, "resource_id", newJString(resourceId))
  result = call_594334.call(path_594335, nil, nil, nil, body_594336)

var updateResource* = Call_UpdateResource_594320(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_594321, base: "/", url: url_UpdateResource_594322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_594305 = ref object of OpenApiRestCall_592348
proc url_DeleteResource_594307(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_594306(path: JsonNode; query: JsonNode;
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
  var valid_594308 = path.getOrDefault("restapi_id")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = nil)
  if valid_594308 != nil:
    section.add "restapi_id", valid_594308
  var valid_594309 = path.getOrDefault("resource_id")
  valid_594309 = validateParameter(valid_594309, JString, required = true,
                                 default = nil)
  if valid_594309 != nil:
    section.add "resource_id", valid_594309
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594310 = header.getOrDefault("X-Amz-Signature")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Signature", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Content-Sha256", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Date")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Date", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Credential")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Credential", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Security-Token")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Security-Token", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Algorithm")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Algorithm", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-SignedHeaders", valid_594316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594317: Call_DeleteResource_594305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_594317.validator(path, query, header, formData, body)
  let scheme = call_594317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594317.url(scheme.get, call_594317.host, call_594317.base,
                         call_594317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594317, url, valid)

proc call*(call_594318: Call_DeleteResource_594305; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_594319 = newJObject()
  add(path_594319, "restapi_id", newJString(restapiId))
  add(path_594319, "resource_id", newJString(resourceId))
  result = call_594318.call(path_594319, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_594305(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_594306, base: "/", url: url_DeleteResource_594307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_594351 = ref object of OpenApiRestCall_592348
proc url_PutRestApi_594353(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_594352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594354 = path.getOrDefault("restapi_id")
  valid_594354 = validateParameter(valid_594354, JString, required = true,
                                 default = nil)
  if valid_594354 != nil:
    section.add "restapi_id", valid_594354
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
  var valid_594355 = query.getOrDefault("failonwarnings")
  valid_594355 = validateParameter(valid_594355, JBool, required = false, default = nil)
  if valid_594355 != nil:
    section.add "failonwarnings", valid_594355
  var valid_594356 = query.getOrDefault("parameters.2.value")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "parameters.2.value", valid_594356
  var valid_594357 = query.getOrDefault("parameters.1.value")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "parameters.1.value", valid_594357
  var valid_594358 = query.getOrDefault("mode")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = newJString("merge"))
  if valid_594358 != nil:
    section.add "mode", valid_594358
  var valid_594359 = query.getOrDefault("parameters.1.key")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "parameters.1.key", valid_594359
  var valid_594360 = query.getOrDefault("parameters.2.key")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "parameters.2.key", valid_594360
  var valid_594361 = query.getOrDefault("parameters.0.value")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "parameters.0.value", valid_594361
  var valid_594362 = query.getOrDefault("parameters.0.key")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "parameters.0.key", valid_594362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594363 = header.getOrDefault("X-Amz-Signature")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Signature", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Date")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Date", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Credential")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Credential", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Security-Token")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Security-Token", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Algorithm")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Algorithm", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-SignedHeaders", valid_594369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_PutRestApi_594351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_PutRestApi_594351; restapiId: string; body: JsonNode;
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
  var path_594373 = newJObject()
  var query_594374 = newJObject()
  var body_594375 = newJObject()
  add(query_594374, "failonwarnings", newJBool(failonwarnings))
  add(query_594374, "parameters.2.value", newJString(parameters2Value))
  add(query_594374, "parameters.1.value", newJString(parameters1Value))
  add(query_594374, "mode", newJString(mode))
  add(query_594374, "parameters.1.key", newJString(parameters1Key))
  add(path_594373, "restapi_id", newJString(restapiId))
  add(query_594374, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_594375 = body
  add(query_594374, "parameters.0.value", newJString(parameters0Value))
  add(query_594374, "parameters.0.key", newJString(parameters0Key))
  result = call_594372.call(path_594373, query_594374, nil, nil, body_594375)

var putRestApi* = Call_PutRestApi_594351(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_594352,
                                      base: "/", url: url_PutRestApi_594353,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_594337 = ref object of OpenApiRestCall_592348
proc url_GetRestApi_594339(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_594338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594340 = path.getOrDefault("restapi_id")
  valid_594340 = validateParameter(valid_594340, JString, required = true,
                                 default = nil)
  if valid_594340 != nil:
    section.add "restapi_id", valid_594340
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594341 = header.getOrDefault("X-Amz-Signature")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Signature", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Content-Sha256", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Date")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Date", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Credential")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Credential", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Security-Token")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Security-Token", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Algorithm")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Algorithm", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-SignedHeaders", valid_594347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594348: Call_GetRestApi_594337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_594348.validator(path, query, header, formData, body)
  let scheme = call_594348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594348.url(scheme.get, call_594348.host, call_594348.base,
                         call_594348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594348, url, valid)

proc call*(call_594349: Call_GetRestApi_594337; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594350 = newJObject()
  add(path_594350, "restapi_id", newJString(restapiId))
  result = call_594349.call(path_594350, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_594337(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_594338,
                                      base: "/", url: url_GetRestApi_594339,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_594390 = ref object of OpenApiRestCall_592348
proc url_UpdateRestApi_594392(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_594391(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594393 = path.getOrDefault("restapi_id")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = nil)
  if valid_594393 != nil:
    section.add "restapi_id", valid_594393
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594394 = header.getOrDefault("X-Amz-Signature")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Signature", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Date")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Date", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Credential")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Credential", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Security-Token")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Security-Token", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Algorithm")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Algorithm", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-SignedHeaders", valid_594400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594402: Call_UpdateRestApi_594390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_594402.validator(path, query, header, formData, body)
  let scheme = call_594402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594402.url(scheme.get, call_594402.host, call_594402.base,
                         call_594402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594402, url, valid)

proc call*(call_594403: Call_UpdateRestApi_594390; restapiId: string; body: JsonNode): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  var path_594404 = newJObject()
  var body_594405 = newJObject()
  add(path_594404, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594405 = body
  result = call_594403.call(path_594404, nil, nil, nil, body_594405)

var updateRestApi* = Call_UpdateRestApi_594390(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_594391,
    base: "/", url: url_UpdateRestApi_594392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_594376 = ref object of OpenApiRestCall_592348
proc url_DeleteRestApi_594378(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_594377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594379 = path.getOrDefault("restapi_id")
  valid_594379 = validateParameter(valid_594379, JString, required = true,
                                 default = nil)
  if valid_594379 != nil:
    section.add "restapi_id", valid_594379
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594380 = header.getOrDefault("X-Amz-Signature")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Signature", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Content-Sha256", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Date")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Date", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Security-Token")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Security-Token", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Algorithm")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Algorithm", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-SignedHeaders", valid_594386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594387: Call_DeleteRestApi_594376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_594387.validator(path, query, header, formData, body)
  let scheme = call_594387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594387.url(scheme.get, call_594387.host, call_594387.base,
                         call_594387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594387, url, valid)

proc call*(call_594388: Call_DeleteRestApi_594376; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594389 = newJObject()
  add(path_594389, "restapi_id", newJString(restapiId))
  result = call_594388.call(path_594389, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_594376(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_594377,
    base: "/", url: url_DeleteRestApi_594378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_594406 = ref object of OpenApiRestCall_592348
proc url_GetStage_594408(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_594407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594409 = path.getOrDefault("restapi_id")
  valid_594409 = validateParameter(valid_594409, JString, required = true,
                                 default = nil)
  if valid_594409 != nil:
    section.add "restapi_id", valid_594409
  var valid_594410 = path.getOrDefault("stage_name")
  valid_594410 = validateParameter(valid_594410, JString, required = true,
                                 default = nil)
  if valid_594410 != nil:
    section.add "stage_name", valid_594410
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Content-Sha256", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Date")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Date", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Credential")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Credential", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Security-Token")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Security-Token", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Algorithm")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Algorithm", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-SignedHeaders", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594418: Call_GetStage_594406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_594418.validator(path, query, header, formData, body)
  let scheme = call_594418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594418.url(scheme.get, call_594418.host, call_594418.base,
                         call_594418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594418, url, valid)

proc call*(call_594419: Call_GetStage_594406; restapiId: string; stageName: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  var path_594420 = newJObject()
  add(path_594420, "restapi_id", newJString(restapiId))
  add(path_594420, "stage_name", newJString(stageName))
  result = call_594419.call(path_594420, nil, nil, nil, nil)

var getStage* = Call_GetStage_594406(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_594407, base: "/",
                                  url: url_GetStage_594408,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_594436 = ref object of OpenApiRestCall_592348
proc url_UpdateStage_594438(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_594437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594439 = path.getOrDefault("restapi_id")
  valid_594439 = validateParameter(valid_594439, JString, required = true,
                                 default = nil)
  if valid_594439 != nil:
    section.add "restapi_id", valid_594439
  var valid_594440 = path.getOrDefault("stage_name")
  valid_594440 = validateParameter(valid_594440, JString, required = true,
                                 default = nil)
  if valid_594440 != nil:
    section.add "stage_name", valid_594440
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Content-Sha256", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Date")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Date", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Credential")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Credential", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Security-Token")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Security-Token", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Algorithm")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Algorithm", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-SignedHeaders", valid_594447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_UpdateStage_594436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_UpdateStage_594436; restapiId: string; body: JsonNode;
          stageName: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  var path_594451 = newJObject()
  var body_594452 = newJObject()
  add(path_594451, "restapi_id", newJString(restapiId))
  if body != nil:
    body_594452 = body
  add(path_594451, "stage_name", newJString(stageName))
  result = call_594450.call(path_594451, nil, nil, nil, body_594452)

var updateStage* = Call_UpdateStage_594436(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_594437,
                                        base: "/", url: url_UpdateStage_594438,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_594421 = ref object of OpenApiRestCall_592348
proc url_DeleteStage_594423(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_594422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594424 = path.getOrDefault("restapi_id")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = nil)
  if valid_594424 != nil:
    section.add "restapi_id", valid_594424
  var valid_594425 = path.getOrDefault("stage_name")
  valid_594425 = validateParameter(valid_594425, JString, required = true,
                                 default = nil)
  if valid_594425 != nil:
    section.add "stage_name", valid_594425
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Date")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Date", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Credential")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Credential", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Security-Token")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Security-Token", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Algorithm")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Algorithm", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-SignedHeaders", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594433: Call_DeleteStage_594421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_594433.validator(path, query, header, formData, body)
  let scheme = call_594433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594433.url(scheme.get, call_594433.host, call_594433.base,
                         call_594433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594433, url, valid)

proc call*(call_594434: Call_DeleteStage_594421; restapiId: string; stageName: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  var path_594435 = newJObject()
  add(path_594435, "restapi_id", newJString(restapiId))
  add(path_594435, "stage_name", newJString(stageName))
  result = call_594434.call(path_594435, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_594421(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_594422,
                                        base: "/", url: url_DeleteStage_594423,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_594453 = ref object of OpenApiRestCall_592348
proc url_GetUsagePlan_594455(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_594454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594456 = path.getOrDefault("usageplanId")
  valid_594456 = validateParameter(valid_594456, JString, required = true,
                                 default = nil)
  if valid_594456 != nil:
    section.add "usageplanId", valid_594456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594457 = header.getOrDefault("X-Amz-Signature")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Signature", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Date")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Date", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Credential")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Credential", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Security-Token")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Security-Token", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Algorithm")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Algorithm", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-SignedHeaders", valid_594463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_GetUsagePlan_594453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_GetUsagePlan_594453; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_594466 = newJObject()
  add(path_594466, "usageplanId", newJString(usageplanId))
  result = call_594465.call(path_594466, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_594453(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_594454,
    base: "/", url: url_GetUsagePlan_594455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_594481 = ref object of OpenApiRestCall_592348
proc url_UpdateUsagePlan_594483(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_594482(path: JsonNode; query: JsonNode;
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
  var valid_594484 = path.getOrDefault("usageplanId")
  valid_594484 = validateParameter(valid_594484, JString, required = true,
                                 default = nil)
  if valid_594484 != nil:
    section.add "usageplanId", valid_594484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594485 = header.getOrDefault("X-Amz-Signature")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Signature", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Content-Sha256", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Date")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Date", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Credential")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Credential", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Security-Token")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Security-Token", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Algorithm")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Algorithm", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-SignedHeaders", valid_594491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594493: Call_UpdateUsagePlan_594481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_594493.validator(path, query, header, formData, body)
  let scheme = call_594493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594493.url(scheme.get, call_594493.host, call_594493.base,
                         call_594493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594493, url, valid)

proc call*(call_594494: Call_UpdateUsagePlan_594481; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_594495 = newJObject()
  var body_594496 = newJObject()
  add(path_594495, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_594496 = body
  result = call_594494.call(path_594495, nil, nil, nil, body_594496)

var updateUsagePlan* = Call_UpdateUsagePlan_594481(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_594482,
    base: "/", url: url_UpdateUsagePlan_594483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_594467 = ref object of OpenApiRestCall_592348
proc url_DeleteUsagePlan_594469(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_594468(path: JsonNode; query: JsonNode;
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
  var valid_594470 = path.getOrDefault("usageplanId")
  valid_594470 = validateParameter(valid_594470, JString, required = true,
                                 default = nil)
  if valid_594470 != nil:
    section.add "usageplanId", valid_594470
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Content-Sha256", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Date")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Date", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Credential")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Credential", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Security-Token")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Security-Token", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Algorithm")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Algorithm", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-SignedHeaders", valid_594477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594478: Call_DeleteUsagePlan_594467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_594478.validator(path, query, header, formData, body)
  let scheme = call_594478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594478.url(scheme.get, call_594478.host, call_594478.base,
                         call_594478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594478, url, valid)

proc call*(call_594479: Call_DeleteUsagePlan_594467; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_594480 = newJObject()
  add(path_594480, "usageplanId", newJString(usageplanId))
  result = call_594479.call(path_594480, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_594467(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_594468,
    base: "/", url: url_DeleteUsagePlan_594469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_594497 = ref object of OpenApiRestCall_592348
proc url_GetUsagePlanKey_594499(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_594498(path: JsonNode; query: JsonNode;
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
  var valid_594500 = path.getOrDefault("usageplanId")
  valid_594500 = validateParameter(valid_594500, JString, required = true,
                                 default = nil)
  if valid_594500 != nil:
    section.add "usageplanId", valid_594500
  var valid_594501 = path.getOrDefault("keyId")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "keyId", valid_594501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594502 = header.getOrDefault("X-Amz-Signature")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Signature", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Content-Sha256", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Date")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Date", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Credential")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Credential", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Security-Token")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Security-Token", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Algorithm")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Algorithm", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-SignedHeaders", valid_594508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_GetUsagePlanKey_594497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_GetUsagePlanKey_594497; usageplanId: string;
          keyId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_594511 = newJObject()
  add(path_594511, "usageplanId", newJString(usageplanId))
  add(path_594511, "keyId", newJString(keyId))
  result = call_594510.call(path_594511, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_594497(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_594498, base: "/", url: url_GetUsagePlanKey_594499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_594512 = ref object of OpenApiRestCall_592348
proc url_DeleteUsagePlanKey_594514(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_594513(path: JsonNode; query: JsonNode;
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
  var valid_594515 = path.getOrDefault("usageplanId")
  valid_594515 = validateParameter(valid_594515, JString, required = true,
                                 default = nil)
  if valid_594515 != nil:
    section.add "usageplanId", valid_594515
  var valid_594516 = path.getOrDefault("keyId")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = nil)
  if valid_594516 != nil:
    section.add "keyId", valid_594516
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594517 = header.getOrDefault("X-Amz-Signature")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Signature", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Content-Sha256", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Date")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Date", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Credential")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Credential", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Security-Token")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Security-Token", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Algorithm")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Algorithm", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594524: Call_DeleteUsagePlanKey_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_594524.validator(path, query, header, formData, body)
  let scheme = call_594524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594524.url(scheme.get, call_594524.host, call_594524.base,
                         call_594524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594524, url, valid)

proc call*(call_594525: Call_DeleteUsagePlanKey_594512; usageplanId: string;
          keyId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  var path_594526 = newJObject()
  add(path_594526, "usageplanId", newJString(usageplanId))
  add(path_594526, "keyId", newJString(keyId))
  result = call_594525.call(path_594526, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_594512(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_594513, base: "/",
    url: url_DeleteUsagePlanKey_594514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_594527 = ref object of OpenApiRestCall_592348
proc url_GetVpcLink_594529(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_594528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594530 = path.getOrDefault("vpclink_id")
  valid_594530 = validateParameter(valid_594530, JString, required = true,
                                 default = nil)
  if valid_594530 != nil:
    section.add "vpclink_id", valid_594530
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Content-Sha256", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Credential")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Credential", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Security-Token")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Security-Token", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-SignedHeaders", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594538: Call_GetVpcLink_594527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_594538.validator(path, query, header, formData, body)
  let scheme = call_594538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594538.url(scheme.get, call_594538.host, call_594538.base,
                         call_594538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594538, url, valid)

proc call*(call_594539: Call_GetVpcLink_594527; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_594540 = newJObject()
  add(path_594540, "vpclink_id", newJString(vpclinkId))
  result = call_594539.call(path_594540, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_594527(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_594528,
                                      base: "/", url: url_GetVpcLink_594529,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_594555 = ref object of OpenApiRestCall_592348
proc url_UpdateVpcLink_594557(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_594556(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594558 = path.getOrDefault("vpclink_id")
  valid_594558 = validateParameter(valid_594558, JString, required = true,
                                 default = nil)
  if valid_594558 != nil:
    section.add "vpclink_id", valid_594558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594559 = header.getOrDefault("X-Amz-Signature")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Signature", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Content-Sha256", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Date")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Date", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Credential")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Credential", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Security-Token")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Security-Token", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Algorithm")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Algorithm", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-SignedHeaders", valid_594565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594567: Call_UpdateVpcLink_594555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_594567.validator(path, query, header, formData, body)
  let scheme = call_594567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594567.url(scheme.get, call_594567.host, call_594567.base,
                         call_594567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594567, url, valid)

proc call*(call_594568: Call_UpdateVpcLink_594555; vpclinkId: string; body: JsonNode): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  ##   body: JObject (required)
  var path_594569 = newJObject()
  var body_594570 = newJObject()
  add(path_594569, "vpclink_id", newJString(vpclinkId))
  if body != nil:
    body_594570 = body
  result = call_594568.call(path_594569, nil, nil, nil, body_594570)

var updateVpcLink* = Call_UpdateVpcLink_594555(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_594556,
    base: "/", url: url_UpdateVpcLink_594557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_594541 = ref object of OpenApiRestCall_592348
proc url_DeleteVpcLink_594543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_594542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594544 = path.getOrDefault("vpclink_id")
  valid_594544 = validateParameter(valid_594544, JString, required = true,
                                 default = nil)
  if valid_594544 != nil:
    section.add "vpclink_id", valid_594544
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594545 = header.getOrDefault("X-Amz-Signature")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Signature", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Content-Sha256", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Date")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Date", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Security-Token")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Security-Token", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Algorithm")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Algorithm", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-SignedHeaders", valid_594551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594552: Call_DeleteVpcLink_594541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_594552.validator(path, query, header, formData, body)
  let scheme = call_594552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594552.url(scheme.get, call_594552.host, call_594552.base,
                         call_594552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594552, url, valid)

proc call*(call_594553: Call_DeleteVpcLink_594541; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_594554 = newJObject()
  add(path_594554, "vpclink_id", newJString(vpclinkId))
  result = call_594553.call(path_594554, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_594541(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_594542,
    base: "/", url: url_DeleteVpcLink_594543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_594571 = ref object of OpenApiRestCall_592348
proc url_FlushStageAuthorizersCache_594573(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_594572(path: JsonNode; query: JsonNode;
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
  var valid_594574 = path.getOrDefault("restapi_id")
  valid_594574 = validateParameter(valid_594574, JString, required = true,
                                 default = nil)
  if valid_594574 != nil:
    section.add "restapi_id", valid_594574
  var valid_594575 = path.getOrDefault("stage_name")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = nil)
  if valid_594575 != nil:
    section.add "stage_name", valid_594575
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Content-Sha256", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Date")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Date", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Credential")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Credential", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Security-Token")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Security-Token", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Algorithm")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Algorithm", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-SignedHeaders", valid_594582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594583: Call_FlushStageAuthorizersCache_594571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_594583.validator(path, query, header, formData, body)
  let scheme = call_594583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594583.url(scheme.get, call_594583.host, call_594583.base,
                         call_594583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594583, url, valid)

proc call*(call_594584: Call_FlushStageAuthorizersCache_594571; restapiId: string;
          stageName: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  var path_594585 = newJObject()
  add(path_594585, "restapi_id", newJString(restapiId))
  add(path_594585, "stage_name", newJString(stageName))
  result = call_594584.call(path_594585, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_594571(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_594572, base: "/",
    url: url_FlushStageAuthorizersCache_594573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_594586 = ref object of OpenApiRestCall_592348
proc url_FlushStageCache_594588(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_594587(path: JsonNode; query: JsonNode;
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
  var valid_594589 = path.getOrDefault("restapi_id")
  valid_594589 = validateParameter(valid_594589, JString, required = true,
                                 default = nil)
  if valid_594589 != nil:
    section.add "restapi_id", valid_594589
  var valid_594590 = path.getOrDefault("stage_name")
  valid_594590 = validateParameter(valid_594590, JString, required = true,
                                 default = nil)
  if valid_594590 != nil:
    section.add "stage_name", valid_594590
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Content-Sha256", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Date")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Date", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Credential")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Credential", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Security-Token")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Security-Token", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Algorithm")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Algorithm", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-SignedHeaders", valid_594597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594598: Call_FlushStageCache_594586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_594598.validator(path, query, header, formData, body)
  let scheme = call_594598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594598.url(scheme.get, call_594598.host, call_594598.base,
                         call_594598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594598, url, valid)

proc call*(call_594599: Call_FlushStageCache_594586; restapiId: string;
          stageName: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  var path_594600 = newJObject()
  add(path_594600, "restapi_id", newJString(restapiId))
  add(path_594600, "stage_name", newJString(stageName))
  result = call_594599.call(path_594600, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_594586(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_594587, base: "/", url: url_FlushStageCache_594588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_594616 = ref object of OpenApiRestCall_592348
proc url_GenerateClientCertificate_594618(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateClientCertificate_594617(path: JsonNode; query: JsonNode;
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
  var valid_594619 = header.getOrDefault("X-Amz-Signature")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Signature", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Content-Sha256", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Date")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Date", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Credential")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Credential", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Security-Token")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Security-Token", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Algorithm")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Algorithm", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-SignedHeaders", valid_594625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594627: Call_GenerateClientCertificate_594616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_594627.validator(path, query, header, formData, body)
  let scheme = call_594627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594627.url(scheme.get, call_594627.host, call_594627.base,
                         call_594627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594627, url, valid)

proc call*(call_594628: Call_GenerateClientCertificate_594616; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_594629 = newJObject()
  if body != nil:
    body_594629 = body
  result = call_594628.call(nil, nil, nil, nil, body_594629)

var generateClientCertificate* = Call_GenerateClientCertificate_594616(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_594617, base: "/",
    url: url_GenerateClientCertificate_594618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_594601 = ref object of OpenApiRestCall_592348
proc url_GetClientCertificates_594603(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClientCertificates_594602(path: JsonNode; query: JsonNode;
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
  var valid_594604 = query.getOrDefault("limit")
  valid_594604 = validateParameter(valid_594604, JInt, required = false, default = nil)
  if valid_594604 != nil:
    section.add "limit", valid_594604
  var valid_594605 = query.getOrDefault("position")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "position", valid_594605
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Content-Sha256", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Date")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Date", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Credential")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Credential", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Security-Token")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Security-Token", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Algorithm")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Algorithm", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-SignedHeaders", valid_594612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594613: Call_GetClientCertificates_594601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_594613.validator(path, query, header, formData, body)
  let scheme = call_594613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594613.url(scheme.get, call_594613.host, call_594613.base,
                         call_594613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594613, url, valid)

proc call*(call_594614: Call_GetClientCertificates_594601; limit: int = 0;
          position: string = ""): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_594615 = newJObject()
  add(query_594615, "limit", newJInt(limit))
  add(query_594615, "position", newJString(position))
  result = call_594614.call(nil, query_594615, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_594601(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_594602, base: "/",
    url: url_GetClientCertificates_594603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_594630 = ref object of OpenApiRestCall_592348
proc url_GetAccount_594632(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccount_594631(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594633 = header.getOrDefault("X-Amz-Signature")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Signature", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Content-Sha256", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Date")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Date", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Credential")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Credential", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Security-Token")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Security-Token", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Algorithm")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Algorithm", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-SignedHeaders", valid_594639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_GetAccount_594630; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_GetAccount_594630): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_594641.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_594630(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_594631,
                                      base: "/", url: url_GetAccount_594632,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_594642 = ref object of OpenApiRestCall_592348
proc url_UpdateAccount_594644(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAccount_594643(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594645 = header.getOrDefault("X-Amz-Signature")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Signature", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Content-Sha256", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Date")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Date", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Credential")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Credential", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Security-Token")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Security-Token", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-SignedHeaders", valid_594651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594653: Call_UpdateAccount_594642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_594653.validator(path, query, header, formData, body)
  let scheme = call_594653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594653.url(scheme.get, call_594653.host, call_594653.base,
                         call_594653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594653, url, valid)

proc call*(call_594654: Call_UpdateAccount_594642; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_594655 = newJObject()
  if body != nil:
    body_594655 = body
  result = call_594654.call(nil, nil, nil, nil, body_594655)

var updateAccount* = Call_UpdateAccount_594642(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_594643, base: "/", url: url_UpdateAccount_594644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_594656 = ref object of OpenApiRestCall_592348
proc url_GetExport_594658(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_594657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594659 = path.getOrDefault("export_type")
  valid_594659 = validateParameter(valid_594659, JString, required = true,
                                 default = nil)
  if valid_594659 != nil:
    section.add "export_type", valid_594659
  var valid_594660 = path.getOrDefault("restapi_id")
  valid_594660 = validateParameter(valid_594660, JString, required = true,
                                 default = nil)
  if valid_594660 != nil:
    section.add "restapi_id", valid_594660
  var valid_594661 = path.getOrDefault("stage_name")
  valid_594661 = validateParameter(valid_594661, JString, required = true,
                                 default = nil)
  if valid_594661 != nil:
    section.add "stage_name", valid_594661
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_594662 = query.getOrDefault("parameters.2.value")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "parameters.2.value", valid_594662
  var valid_594663 = query.getOrDefault("parameters.1.value")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "parameters.1.value", valid_594663
  var valid_594664 = query.getOrDefault("parameters.1.key")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "parameters.1.key", valid_594664
  var valid_594665 = query.getOrDefault("parameters.2.key")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "parameters.2.key", valid_594665
  var valid_594666 = query.getOrDefault("parameters.0.value")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "parameters.0.value", valid_594666
  var valid_594667 = query.getOrDefault("parameters.0.key")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "parameters.0.key", valid_594667
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
  var valid_594668 = header.getOrDefault("X-Amz-Signature")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Signature", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Content-Sha256", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Date")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Date", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Credential")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Credential", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Security-Token")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Security-Token", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Algorithm")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Algorithm", valid_594673
  var valid_594674 = header.getOrDefault("Accept")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "Accept", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-SignedHeaders", valid_594675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594676: Call_GetExport_594656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_594676.validator(path, query, header, formData, body)
  let scheme = call_594676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594676.url(scheme.get, call_594676.host, call_594676.base,
                         call_594676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594676, url, valid)

proc call*(call_594677: Call_GetExport_594656; exportType: string; restapiId: string;
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
  var path_594678 = newJObject()
  var query_594679 = newJObject()
  add(query_594679, "parameters.2.value", newJString(parameters2Value))
  add(query_594679, "parameters.1.value", newJString(parameters1Value))
  add(query_594679, "parameters.1.key", newJString(parameters1Key))
  add(path_594678, "export_type", newJString(exportType))
  add(path_594678, "restapi_id", newJString(restapiId))
  add(query_594679, "parameters.2.key", newJString(parameters2Key))
  add(path_594678, "stage_name", newJString(stageName))
  add(query_594679, "parameters.0.value", newJString(parameters0Value))
  add(query_594679, "parameters.0.key", newJString(parameters0Key))
  result = call_594677.call(path_594678, query_594679, nil, nil, nil)

var getExport* = Call_GetExport_594656(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_594657,
                                    base: "/", url: url_GetExport_594658,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_594680 = ref object of OpenApiRestCall_592348
proc url_GetGatewayResponses_594682(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_594681(path: JsonNode; query: JsonNode;
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
  var valid_594683 = path.getOrDefault("restapi_id")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = nil)
  if valid_594683 != nil:
    section.add "restapi_id", valid_594683
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  section = newJObject()
  var valid_594684 = query.getOrDefault("limit")
  valid_594684 = validateParameter(valid_594684, JInt, required = false, default = nil)
  if valid_594684 != nil:
    section.add "limit", valid_594684
  var valid_594685 = query.getOrDefault("position")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "position", valid_594685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594686 = header.getOrDefault("X-Amz-Signature")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Signature", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Content-Sha256", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Date")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Date", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Credential")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Credential", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Security-Token")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Security-Token", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Algorithm")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Algorithm", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-SignedHeaders", valid_594692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594693: Call_GetGatewayResponses_594680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_594693.validator(path, query, header, formData, body)
  let scheme = call_594693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594693.url(scheme.get, call_594693.host, call_594693.base,
                         call_594693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594693, url, valid)

proc call*(call_594694: Call_GetGatewayResponses_594680; restapiId: string;
          limit: int = 0; position: string = ""): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594695 = newJObject()
  var query_594696 = newJObject()
  add(query_594696, "limit", newJInt(limit))
  add(query_594696, "position", newJString(position))
  add(path_594695, "restapi_id", newJString(restapiId))
  result = call_594694.call(path_594695, query_594696, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_594680(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_594681, base: "/",
    url: url_GetGatewayResponses_594682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_594697 = ref object of OpenApiRestCall_592348
proc url_GetModelTemplate_594699(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_594698(path: JsonNode; query: JsonNode;
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
  var valid_594700 = path.getOrDefault("model_name")
  valid_594700 = validateParameter(valid_594700, JString, required = true,
                                 default = nil)
  if valid_594700 != nil:
    section.add "model_name", valid_594700
  var valid_594701 = path.getOrDefault("restapi_id")
  valid_594701 = validateParameter(valid_594701, JString, required = true,
                                 default = nil)
  if valid_594701 != nil:
    section.add "restapi_id", valid_594701
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594702 = header.getOrDefault("X-Amz-Signature")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Signature", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Content-Sha256", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Date")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Date", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Credential")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Credential", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Security-Token")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Security-Token", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Algorithm")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Algorithm", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-SignedHeaders", valid_594708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594709: Call_GetModelTemplate_594697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_594709.validator(path, query, header, formData, body)
  let scheme = call_594709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594709.url(scheme.get, call_594709.host, call_594709.base,
                         call_594709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594709, url, valid)

proc call*(call_594710: Call_GetModelTemplate_594697; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_594711 = newJObject()
  add(path_594711, "model_name", newJString(modelName))
  add(path_594711, "restapi_id", newJString(restapiId))
  result = call_594710.call(path_594711, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_594697(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_594698, base: "/",
    url: url_GetModelTemplate_594699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_594712 = ref object of OpenApiRestCall_592348
proc url_GetResources_594714(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_594713(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594715 = path.getOrDefault("restapi_id")
  valid_594715 = validateParameter(valid_594715, JString, required = true,
                                 default = nil)
  if valid_594715 != nil:
    section.add "restapi_id", valid_594715
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  section = newJObject()
  var valid_594716 = query.getOrDefault("limit")
  valid_594716 = validateParameter(valid_594716, JInt, required = false, default = nil)
  if valid_594716 != nil:
    section.add "limit", valid_594716
  var valid_594717 = query.getOrDefault("position")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "position", valid_594717
  var valid_594718 = query.getOrDefault("embed")
  valid_594718 = validateParameter(valid_594718, JArray, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "embed", valid_594718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594719 = header.getOrDefault("X-Amz-Signature")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Signature", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Content-Sha256", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Credential")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Credential", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Security-Token")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Security-Token", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Algorithm")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Algorithm", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-SignedHeaders", valid_594725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594726: Call_GetResources_594712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_594726.validator(path, query, header, formData, body)
  let scheme = call_594726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594726.url(scheme.get, call_594726.host, call_594726.base,
                         call_594726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594726, url, valid)

proc call*(call_594727: Call_GetResources_594712; restapiId: string; limit: int = 0;
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
  var path_594728 = newJObject()
  var query_594729 = newJObject()
  add(query_594729, "limit", newJInt(limit))
  add(query_594729, "position", newJString(position))
  add(path_594728, "restapi_id", newJString(restapiId))
  if embed != nil:
    query_594729.add "embed", embed
  result = call_594727.call(path_594728, query_594729, nil, nil, nil)

var getResources* = Call_GetResources_594712(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_594713,
    base: "/", url: url_GetResources_594714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_594730 = ref object of OpenApiRestCall_592348
proc url_GetSdk_594732(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_594731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594733 = path.getOrDefault("sdk_type")
  valid_594733 = validateParameter(valid_594733, JString, required = true,
                                 default = nil)
  if valid_594733 != nil:
    section.add "sdk_type", valid_594733
  var valid_594734 = path.getOrDefault("restapi_id")
  valid_594734 = validateParameter(valid_594734, JString, required = true,
                                 default = nil)
  if valid_594734 != nil:
    section.add "restapi_id", valid_594734
  var valid_594735 = path.getOrDefault("stage_name")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = nil)
  if valid_594735 != nil:
    section.add "stage_name", valid_594735
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.2.value: JString
  ##   parameters.1.value: JString
  ##   parameters.1.key: JString
  ##   parameters.2.key: JString
  ##   parameters.0.value: JString
  ##   parameters.0.key: JString
  section = newJObject()
  var valid_594736 = query.getOrDefault("parameters.2.value")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "parameters.2.value", valid_594736
  var valid_594737 = query.getOrDefault("parameters.1.value")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "parameters.1.value", valid_594737
  var valid_594738 = query.getOrDefault("parameters.1.key")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "parameters.1.key", valid_594738
  var valid_594739 = query.getOrDefault("parameters.2.key")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "parameters.2.key", valid_594739
  var valid_594740 = query.getOrDefault("parameters.0.value")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "parameters.0.value", valid_594740
  var valid_594741 = query.getOrDefault("parameters.0.key")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "parameters.0.key", valid_594741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594742 = header.getOrDefault("X-Amz-Signature")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Signature", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Content-Sha256", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Date")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Date", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Credential")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Credential", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Security-Token")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Security-Token", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Algorithm")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Algorithm", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-SignedHeaders", valid_594748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594749: Call_GetSdk_594730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_594749.validator(path, query, header, formData, body)
  let scheme = call_594749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594749.url(scheme.get, call_594749.host, call_594749.base,
                         call_594749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594749, url, valid)

proc call*(call_594750: Call_GetSdk_594730; sdkType: string; restapiId: string;
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
  var path_594751 = newJObject()
  var query_594752 = newJObject()
  add(path_594751, "sdk_type", newJString(sdkType))
  add(query_594752, "parameters.2.value", newJString(parameters2Value))
  add(query_594752, "parameters.1.value", newJString(parameters1Value))
  add(query_594752, "parameters.1.key", newJString(parameters1Key))
  add(path_594751, "restapi_id", newJString(restapiId))
  add(query_594752, "parameters.2.key", newJString(parameters2Key))
  add(path_594751, "stage_name", newJString(stageName))
  add(query_594752, "parameters.0.value", newJString(parameters0Value))
  add(query_594752, "parameters.0.key", newJString(parameters0Key))
  result = call_594750.call(path_594751, query_594752, nil, nil, nil)

var getSdk* = Call_GetSdk_594730(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_594731, base: "/",
                              url: url_GetSdk_594732,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_594753 = ref object of OpenApiRestCall_592348
proc url_GetSdkType_594755(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_594754(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_594756 = path.getOrDefault("sdktype_id")
  valid_594756 = validateParameter(valid_594756, JString, required = true,
                                 default = nil)
  if valid_594756 != nil:
    section.add "sdktype_id", valid_594756
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594757 = header.getOrDefault("X-Amz-Signature")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Signature", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Content-Sha256", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Date")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Date", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Credential")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Credential", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Security-Token")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Security-Token", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Algorithm")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Algorithm", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-SignedHeaders", valid_594763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_GetSdkType_594753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_GetSdkType_594753; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_594766 = newJObject()
  add(path_594766, "sdktype_id", newJString(sdktypeId))
  result = call_594765.call(path_594766, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_594753(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_594754,
                                      base: "/", url: url_GetSdkType_594755,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_594767 = ref object of OpenApiRestCall_592348
proc url_GetSdkTypes_594769(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSdkTypes_594768(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594770 = query.getOrDefault("limit")
  valid_594770 = validateParameter(valid_594770, JInt, required = false, default = nil)
  if valid_594770 != nil:
    section.add "limit", valid_594770
  var valid_594771 = query.getOrDefault("position")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "position", valid_594771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594772 = header.getOrDefault("X-Amz-Signature")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Signature", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Content-Sha256", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Date")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Date", valid_594774
  var valid_594775 = header.getOrDefault("X-Amz-Credential")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Credential", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Security-Token")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Security-Token", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Algorithm")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Algorithm", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-SignedHeaders", valid_594778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594779: Call_GetSdkTypes_594767; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594779.validator(path, query, header, formData, body)
  let scheme = call_594779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594779.url(scheme.get, call_594779.host, call_594779.base,
                         call_594779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594779, url, valid)

proc call*(call_594780: Call_GetSdkTypes_594767; limit: int = 0; position: string = ""): Recallable =
  ## getSdkTypes
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  var query_594781 = newJObject()
  add(query_594781, "limit", newJInt(limit))
  add(query_594781, "position", newJString(position))
  result = call_594780.call(nil, query_594781, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_594767(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_594768,
                                        base: "/", url: url_GetSdkTypes_594769,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594799 = ref object of OpenApiRestCall_592348
proc url_TagResource_594801(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594800(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594802 = path.getOrDefault("resource_arn")
  valid_594802 = validateParameter(valid_594802, JString, required = true,
                                 default = nil)
  if valid_594802 != nil:
    section.add "resource_arn", valid_594802
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594803 = header.getOrDefault("X-Amz-Signature")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Signature", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Content-Sha256", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Date")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Date", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Credential")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Credential", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Security-Token")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Security-Token", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Algorithm")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Algorithm", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-SignedHeaders", valid_594809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594811: Call_TagResource_594799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_594811.validator(path, query, header, formData, body)
  let scheme = call_594811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594811.url(scheme.get, call_594811.host, call_594811.base,
                         call_594811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594811, url, valid)

proc call*(call_594812: Call_TagResource_594799; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_594813 = newJObject()
  var body_594814 = newJObject()
  add(path_594813, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_594814 = body
  result = call_594812.call(path_594813, nil, nil, nil, body_594814)

var tagResource* = Call_TagResource_594799(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_594800,
                                        base: "/", url: url_TagResource_594801,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_594782 = ref object of OpenApiRestCall_592348
proc url_GetTags_594784(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_594783(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594785 = path.getOrDefault("resource_arn")
  valid_594785 = validateParameter(valid_594785, JString, required = true,
                                 default = nil)
  if valid_594785 != nil:
    section.add "resource_arn", valid_594785
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  section = newJObject()
  var valid_594786 = query.getOrDefault("limit")
  valid_594786 = validateParameter(valid_594786, JInt, required = false, default = nil)
  if valid_594786 != nil:
    section.add "limit", valid_594786
  var valid_594787 = query.getOrDefault("position")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "position", valid_594787
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594788 = header.getOrDefault("X-Amz-Signature")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Signature", valid_594788
  var valid_594789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Content-Sha256", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Date")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Date", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Credential")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Credential", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Security-Token")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Security-Token", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Algorithm")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Algorithm", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-SignedHeaders", valid_594794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594795: Call_GetTags_594782; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_594795.validator(path, query, header, formData, body)
  let scheme = call_594795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594795.url(scheme.get, call_594795.host, call_594795.base,
                         call_594795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594795, url, valid)

proc call*(call_594796: Call_GetTags_594782; resourceArn: string; limit: int = 0;
          position: string = ""): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  var path_594797 = newJObject()
  var query_594798 = newJObject()
  add(query_594798, "limit", newJInt(limit))
  add(path_594797, "resource_arn", newJString(resourceArn))
  add(query_594798, "position", newJString(position))
  result = call_594796.call(path_594797, query_594798, nil, nil, nil)

var getTags* = Call_GetTags_594782(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_594783, base: "/",
                                url: url_GetTags_594784,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_594815 = ref object of OpenApiRestCall_592348
proc url_GetUsage_594817(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_594816(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594818 = path.getOrDefault("usageplanId")
  valid_594818 = validateParameter(valid_594818, JString, required = true,
                                 default = nil)
  if valid_594818 != nil:
    section.add "usageplanId", valid_594818
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
  var valid_594819 = query.getOrDefault("limit")
  valid_594819 = validateParameter(valid_594819, JInt, required = false, default = nil)
  if valid_594819 != nil:
    section.add "limit", valid_594819
  assert query != nil, "query argument is necessary due to required `endDate` field"
  var valid_594820 = query.getOrDefault("endDate")
  valid_594820 = validateParameter(valid_594820, JString, required = true,
                                 default = nil)
  if valid_594820 != nil:
    section.add "endDate", valid_594820
  var valid_594821 = query.getOrDefault("position")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "position", valid_594821
  var valid_594822 = query.getOrDefault("keyId")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "keyId", valid_594822
  var valid_594823 = query.getOrDefault("startDate")
  valid_594823 = validateParameter(valid_594823, JString, required = true,
                                 default = nil)
  if valid_594823 != nil:
    section.add "startDate", valid_594823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594824 = header.getOrDefault("X-Amz-Signature")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Signature", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Content-Sha256", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Date")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Date", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Credential")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Credential", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Security-Token")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Security-Token", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Algorithm")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Algorithm", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-SignedHeaders", valid_594830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594831: Call_GetUsage_594815; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_594831.validator(path, query, header, formData, body)
  let scheme = call_594831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594831.url(scheme.get, call_594831.host, call_594831.base,
                         call_594831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594831, url, valid)

proc call*(call_594832: Call_GetUsage_594815; usageplanId: string; endDate: string;
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
  var path_594833 = newJObject()
  var query_594834 = newJObject()
  add(path_594833, "usageplanId", newJString(usageplanId))
  add(query_594834, "limit", newJInt(limit))
  add(query_594834, "endDate", newJString(endDate))
  add(query_594834, "position", newJString(position))
  add(query_594834, "keyId", newJString(keyId))
  add(query_594834, "startDate", newJString(startDate))
  result = call_594832.call(path_594833, query_594834, nil, nil, nil)

var getUsage* = Call_GetUsage_594815(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_594816, base: "/",
                                  url: url_GetUsage_594817,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_594835 = ref object of OpenApiRestCall_592348
proc url_ImportApiKeys_594837(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportApiKeys_594836(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594838 = query.getOrDefault("failonwarnings")
  valid_594838 = validateParameter(valid_594838, JBool, required = false, default = nil)
  if valid_594838 != nil:
    section.add "failonwarnings", valid_594838
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_594839 = query.getOrDefault("mode")
  valid_594839 = validateParameter(valid_594839, JString, required = true,
                                 default = newJString("import"))
  if valid_594839 != nil:
    section.add "mode", valid_594839
  var valid_594840 = query.getOrDefault("format")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = newJString("csv"))
  if valid_594840 != nil:
    section.add "format", valid_594840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594841 = header.getOrDefault("X-Amz-Signature")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Signature", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Content-Sha256", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Date")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Date", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Credential")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Credential", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Security-Token")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Security-Token", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Algorithm")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Algorithm", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-SignedHeaders", valid_594847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594849: Call_ImportApiKeys_594835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_594849.validator(path, query, header, formData, body)
  let scheme = call_594849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594849.url(scheme.get, call_594849.host, call_594849.base,
                         call_594849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594849, url, valid)

proc call*(call_594850: Call_ImportApiKeys_594835; body: JsonNode;
          failonwarnings: bool = false; mode: string = "import"; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   mode: string (required)
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_594851 = newJObject()
  var body_594852 = newJObject()
  add(query_594851, "failonwarnings", newJBool(failonwarnings))
  add(query_594851, "mode", newJString(mode))
  if body != nil:
    body_594852 = body
  add(query_594851, "format", newJString(format))
  result = call_594850.call(nil, query_594851, nil, nil, body_594852)

var importApiKeys* = Call_ImportApiKeys_594835(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_594836,
    base: "/", url: url_ImportApiKeys_594837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_594853 = ref object of OpenApiRestCall_592348
proc url_ImportRestApi_594855(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportRestApi_594854(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594856 = query.getOrDefault("failonwarnings")
  valid_594856 = validateParameter(valid_594856, JBool, required = false, default = nil)
  if valid_594856 != nil:
    section.add "failonwarnings", valid_594856
  var valid_594857 = query.getOrDefault("parameters.2.value")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "parameters.2.value", valid_594857
  var valid_594858 = query.getOrDefault("parameters.1.value")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "parameters.1.value", valid_594858
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_594859 = query.getOrDefault("mode")
  valid_594859 = validateParameter(valid_594859, JString, required = true,
                                 default = newJString("import"))
  if valid_594859 != nil:
    section.add "mode", valid_594859
  var valid_594860 = query.getOrDefault("parameters.1.key")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "parameters.1.key", valid_594860
  var valid_594861 = query.getOrDefault("parameters.2.key")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "parameters.2.key", valid_594861
  var valid_594862 = query.getOrDefault("parameters.0.value")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "parameters.0.value", valid_594862
  var valid_594863 = query.getOrDefault("parameters.0.key")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "parameters.0.key", valid_594863
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594864 = header.getOrDefault("X-Amz-Signature")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Signature", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Content-Sha256", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Credential")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Credential", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Security-Token")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Security-Token", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Algorithm")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Algorithm", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-SignedHeaders", valid_594870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594872: Call_ImportRestApi_594853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_594872.validator(path, query, header, formData, body)
  let scheme = call_594872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594872.url(scheme.get, call_594872.host, call_594872.base,
                         call_594872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594872, url, valid)

proc call*(call_594873: Call_ImportRestApi_594853; body: JsonNode;
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
  var query_594874 = newJObject()
  var body_594875 = newJObject()
  add(query_594874, "failonwarnings", newJBool(failonwarnings))
  add(query_594874, "parameters.2.value", newJString(parameters2Value))
  add(query_594874, "parameters.1.value", newJString(parameters1Value))
  add(query_594874, "mode", newJString(mode))
  add(query_594874, "parameters.1.key", newJString(parameters1Key))
  add(query_594874, "parameters.2.key", newJString(parameters2Key))
  if body != nil:
    body_594875 = body
  add(query_594874, "parameters.0.value", newJString(parameters0Value))
  add(query_594874, "parameters.0.key", newJString(parameters0Key))
  result = call_594873.call(nil, query_594874, nil, nil, body_594875)

var importRestApi* = Call_ImportRestApi_594853(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_594854,
    base: "/", url: url_ImportRestApi_594855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594876 = ref object of OpenApiRestCall_592348
proc url_UntagResource_594878(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594877(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594879 = path.getOrDefault("resource_arn")
  valid_594879 = validateParameter(valid_594879, JString, required = true,
                                 default = nil)
  if valid_594879 != nil:
    section.add "resource_arn", valid_594879
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594880 = query.getOrDefault("tagKeys")
  valid_594880 = validateParameter(valid_594880, JArray, required = true, default = nil)
  if valid_594880 != nil:
    section.add "tagKeys", valid_594880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594881 = header.getOrDefault("X-Amz-Signature")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Signature", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Content-Sha256", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Date")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Date", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Credential")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Credential", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Security-Token")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Security-Token", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Algorithm")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Algorithm", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-SignedHeaders", valid_594887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594888: Call_UntagResource_594876; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_594888.validator(path, query, header, formData, body)
  let scheme = call_594888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594888.url(scheme.get, call_594888.host, call_594888.base,
                         call_594888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594888, url, valid)

proc call*(call_594889: Call_UntagResource_594876; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_594890 = newJObject()
  var query_594891 = newJObject()
  add(path_594890, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_594891.add "tagKeys", tagKeys
  result = call_594889.call(path_594890, query_594891, nil, nil, nil)

var untagResource* = Call_UntagResource_594876(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_594877,
    base: "/", url: url_UntagResource_594878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_594892 = ref object of OpenApiRestCall_592348
proc url_UpdateUsage_594894(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_594893(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594895 = path.getOrDefault("usageplanId")
  valid_594895 = validateParameter(valid_594895, JString, required = true,
                                 default = nil)
  if valid_594895 != nil:
    section.add "usageplanId", valid_594895
  var valid_594896 = path.getOrDefault("keyId")
  valid_594896 = validateParameter(valid_594896, JString, required = true,
                                 default = nil)
  if valid_594896 != nil:
    section.add "keyId", valid_594896
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594897 = header.getOrDefault("X-Amz-Signature")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Signature", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Content-Sha256", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Date")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Date", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-Credential")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-Credential", valid_594900
  var valid_594901 = header.getOrDefault("X-Amz-Security-Token")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-Security-Token", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-Algorithm")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-Algorithm", valid_594902
  var valid_594903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594903 = validateParameter(valid_594903, JString, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "X-Amz-SignedHeaders", valid_594903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594905: Call_UpdateUsage_594892; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_594905.validator(path, query, header, formData, body)
  let scheme = call_594905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594905.url(scheme.get, call_594905.host, call_594905.base,
                         call_594905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594905, url, valid)

proc call*(call_594906: Call_UpdateUsage_594892; usageplanId: string; keyId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   body: JObject (required)
  var path_594907 = newJObject()
  var body_594908 = newJObject()
  add(path_594907, "usageplanId", newJString(usageplanId))
  add(path_594907, "keyId", newJString(keyId))
  if body != nil:
    body_594908 = body
  result = call_594906.call(path_594907, nil, nil, nil, body_594908)

var updateUsage* = Call_UpdateUsage_594892(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_594893,
                                        base: "/", url: url_UpdateUsage_594894,
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
