
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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_603047 = ref object of OpenApiRestCall_602450
proc url_CreateApiKey_603049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApiKey_603048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603050 = header.getOrDefault("X-Amz-Date")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Date", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Security-Token")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Security-Token", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Content-Sha256", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Algorithm")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Algorithm", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Signature")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Signature", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-SignedHeaders", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Credential")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Credential", valid_603056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_CreateApiKey_603047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603058, url, valid)

proc call*(call_603059: Call_CreateApiKey_603047; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_603060 = newJObject()
  if body != nil:
    body_603060 = body
  result = call_603059.call(nil, nil, nil, nil, body_603060)

var createApiKey* = Call_CreateApiKey_603047(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_603048, base: "/", url: url_CreateApiKey_603049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_602787 = ref object of OpenApiRestCall_602450
proc url_GetApiKeys_602789(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApiKeys_602788(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602901 = query.getOrDefault("customerId")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "customerId", valid_602901
  var valid_602902 = query.getOrDefault("includeValues")
  valid_602902 = validateParameter(valid_602902, JBool, required = false, default = nil)
  if valid_602902 != nil:
    section.add "includeValues", valid_602902
  var valid_602903 = query.getOrDefault("name")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "name", valid_602903
  var valid_602904 = query.getOrDefault("position")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "position", valid_602904
  var valid_602905 = query.getOrDefault("limit")
  valid_602905 = validateParameter(valid_602905, JInt, required = false, default = nil)
  if valid_602905 != nil:
    section.add "limit", valid_602905
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_602935: Call_GetApiKeys_602787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_602935.validator(path, query, header, formData, body)
  let scheme = call_602935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602935.url(scheme.get, call_602935.host, call_602935.base,
                         call_602935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602935, url, valid)

proc call*(call_603006: Call_GetApiKeys_602787; customerId: string = "";
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
  var query_603007 = newJObject()
  add(query_603007, "customerId", newJString(customerId))
  add(query_603007, "includeValues", newJBool(includeValues))
  add(query_603007, "name", newJString(name))
  add(query_603007, "position", newJString(position))
  add(query_603007, "limit", newJInt(limit))
  result = call_603006.call(nil, query_603007, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_602787(name: "getApiKeys",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys",
                                      validator: validate_GetApiKeys_602788,
                                      base: "/", url: url_GetApiKeys_602789,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_603092 = ref object of OpenApiRestCall_602450
proc url_CreateAuthorizer_603094(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_603093(path: JsonNode; query: JsonNode;
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
  var valid_603095 = path.getOrDefault("restapi_id")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "restapi_id", valid_603095
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_603104: Call_CreateAuthorizer_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_CreateAuthorizer_603092; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603106 = newJObject()
  var body_603107 = newJObject()
  if body != nil:
    body_603107 = body
  add(path_603106, "restapi_id", newJString(restapiId))
  result = call_603105.call(path_603106, nil, nil, nil, body_603107)

var createAuthorizer* = Call_CreateAuthorizer_603092(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_603093, base: "/",
    url: url_CreateAuthorizer_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_603061 = ref object of OpenApiRestCall_602450
proc url_GetAuthorizers_603063(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_603062(path: JsonNode; query: JsonNode;
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
  var valid_603078 = path.getOrDefault("restapi_id")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "restapi_id", valid_603078
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

proc call*(call_603088: Call_GetAuthorizers_603061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_GetAuthorizers_603061; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603090 = newJObject()
  var query_603091 = newJObject()
  add(query_603091, "position", newJString(position))
  add(query_603091, "limit", newJInt(limit))
  add(path_603090, "restapi_id", newJString(restapiId))
  result = call_603089.call(path_603090, query_603091, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_603061(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_603062, base: "/", url: url_GetAuthorizers_603063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_603125 = ref object of OpenApiRestCall_602450
proc url_CreateBasePathMapping_603127(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBasePathMapping_603126(path: JsonNode; query: JsonNode;
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
  var valid_603128 = path.getOrDefault("domain_name")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "domain_name", valid_603128
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_603137: Call_CreateBasePathMapping_603125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603137.validator(path, query, header, formData, body)
  let scheme = call_603137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603137.url(scheme.get, call_603137.host, call_603137.base,
                         call_603137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603137, url, valid)

proc call*(call_603138: Call_CreateBasePathMapping_603125; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_603139 = newJObject()
  var body_603140 = newJObject()
  add(path_603139, "domain_name", newJString(domainName))
  if body != nil:
    body_603140 = body
  result = call_603138.call(path_603139, nil, nil, nil, body_603140)

var createBasePathMapping* = Call_CreateBasePathMapping_603125(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_603126, base: "/",
    url: url_CreateBasePathMapping_603127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_603108 = ref object of OpenApiRestCall_602450
proc url_GetBasePathMappings_603110(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_603109(path: JsonNode; query: JsonNode;
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
  var valid_603111 = path.getOrDefault("domain_name")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "domain_name", valid_603111
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

proc call*(call_603121: Call_GetBasePathMappings_603108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_603121.validator(path, query, header, formData, body)
  let scheme = call_603121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603121.url(scheme.get, call_603121.host, call_603121.base,
                         call_603121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603121, url, valid)

proc call*(call_603122: Call_GetBasePathMappings_603108; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_603123 = newJObject()
  var query_603124 = newJObject()
  add(path_603123, "domain_name", newJString(domainName))
  add(query_603124, "position", newJString(position))
  add(query_603124, "limit", newJInt(limit))
  result = call_603122.call(path_603123, query_603124, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_603108(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_603109, base: "/",
    url: url_GetBasePathMappings_603110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_603158 = ref object of OpenApiRestCall_602450
proc url_CreateDeployment_603160(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_603159(path: JsonNode; query: JsonNode;
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
  var valid_603161 = path.getOrDefault("restapi_id")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "restapi_id", valid_603161
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Content-Sha256", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Algorithm")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Algorithm", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Signature")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Signature", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-SignedHeaders", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Credential")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Credential", valid_603168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603170: Call_CreateDeployment_603158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_603170.validator(path, query, header, formData, body)
  let scheme = call_603170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603170.url(scheme.get, call_603170.host, call_603170.base,
                         call_603170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603170, url, valid)

proc call*(call_603171: Call_CreateDeployment_603158; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603172 = newJObject()
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  add(path_603172, "restapi_id", newJString(restapiId))
  result = call_603171.call(path_603172, nil, nil, nil, body_603173)

var createDeployment* = Call_CreateDeployment_603158(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_603159, base: "/",
    url: url_CreateDeployment_603160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_603141 = ref object of OpenApiRestCall_602450
proc url_GetDeployments_603143(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_603142(path: JsonNode; query: JsonNode;
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
  var valid_603144 = path.getOrDefault("restapi_id")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "restapi_id", valid_603144
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603145 = query.getOrDefault("position")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "position", valid_603145
  var valid_603146 = query.getOrDefault("limit")
  valid_603146 = validateParameter(valid_603146, JInt, required = false, default = nil)
  if valid_603146 != nil:
    section.add "limit", valid_603146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Content-Sha256", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Algorithm")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Algorithm", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Signature")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Signature", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-SignedHeaders", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Credential")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Credential", valid_603153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603154: Call_GetDeployments_603141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_603154.validator(path, query, header, formData, body)
  let scheme = call_603154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603154.url(scheme.get, call_603154.host, call_603154.base,
                         call_603154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603154, url, valid)

proc call*(call_603155: Call_GetDeployments_603141; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603156 = newJObject()
  var query_603157 = newJObject()
  add(query_603157, "position", newJString(position))
  add(query_603157, "limit", newJInt(limit))
  add(path_603156, "restapi_id", newJString(restapiId))
  result = call_603155.call(path_603156, query_603157, nil, nil, nil)

var getDeployments* = Call_GetDeployments_603141(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_603142, base: "/", url: url_GetDeployments_603143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_603208 = ref object of OpenApiRestCall_602450
proc url_ImportDocumentationParts_603210(protocol: Scheme; host: string;
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

proc validate_ImportDocumentationParts_603209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603211 = path.getOrDefault("restapi_id")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = nil)
  if valid_603211 != nil:
    section.add "restapi_id", valid_603211
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_603212 = query.getOrDefault("mode")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = newJString("merge"))
  if valid_603212 != nil:
    section.add "mode", valid_603212
  var valid_603213 = query.getOrDefault("failonwarnings")
  valid_603213 = validateParameter(valid_603213, JBool, required = false, default = nil)
  if valid_603213 != nil:
    section.add "failonwarnings", valid_603213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Algorithm")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Algorithm", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Signature")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Signature", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_ImportDocumentationParts_603208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_ImportDocumentationParts_603208; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603224 = newJObject()
  var query_603225 = newJObject()
  var body_603226 = newJObject()
  add(query_603225, "mode", newJString(mode))
  add(query_603225, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_603226 = body
  add(path_603224, "restapi_id", newJString(restapiId))
  result = call_603223.call(path_603224, query_603225, nil, nil, body_603226)

var importDocumentationParts* = Call_ImportDocumentationParts_603208(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_603209, base: "/",
    url: url_ImportDocumentationParts_603210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_603227 = ref object of OpenApiRestCall_602450
proc url_CreateDocumentationPart_603229(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDocumentationPart_603228(path: JsonNode; query: JsonNode;
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

proc call*(call_603239: Call_CreateDocumentationPart_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_CreateDocumentationPart_603227; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603241 = newJObject()
  var body_603242 = newJObject()
  if body != nil:
    body_603242 = body
  add(path_603241, "restapi_id", newJString(restapiId))
  result = call_603240.call(path_603241, nil, nil, nil, body_603242)

var createDocumentationPart* = Call_CreateDocumentationPart_603227(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_603228, base: "/",
    url: url_CreateDocumentationPart_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_603174 = ref object of OpenApiRestCall_602450
proc url_GetDocumentationParts_603176(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_603175(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603177 = path.getOrDefault("restapi_id")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = nil)
  if valid_603177 != nil:
    section.add "restapi_id", valid_603177
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
  var valid_603191 = query.getOrDefault("type")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = newJString("API"))
  if valid_603191 != nil:
    section.add "type", valid_603191
  var valid_603192 = query.getOrDefault("path")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "path", valid_603192
  var valid_603193 = query.getOrDefault("locationStatus")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = newJString("DOCUMENTED"))
  if valid_603193 != nil:
    section.add "locationStatus", valid_603193
  var valid_603194 = query.getOrDefault("name")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "name", valid_603194
  var valid_603195 = query.getOrDefault("position")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "position", valid_603195
  var valid_603196 = query.getOrDefault("limit")
  valid_603196 = validateParameter(valid_603196, JInt, required = false, default = nil)
  if valid_603196 != nil:
    section.add "limit", valid_603196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603197 = header.getOrDefault("X-Amz-Date")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Date", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Security-Token")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Security-Token", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_GetDocumentationParts_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_GetDocumentationParts_603174; restapiId: string;
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
  var path_603206 = newJObject()
  var query_603207 = newJObject()
  add(query_603207, "type", newJString(`type`))
  add(query_603207, "path", newJString(path))
  add(query_603207, "locationStatus", newJString(locationStatus))
  add(query_603207, "name", newJString(name))
  add(query_603207, "position", newJString(position))
  add(query_603207, "limit", newJInt(limit))
  add(path_603206, "restapi_id", newJString(restapiId))
  result = call_603205.call(path_603206, query_603207, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_603174(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_603175, base: "/",
    url: url_GetDocumentationParts_603176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_603260 = ref object of OpenApiRestCall_602450
proc url_CreateDocumentationVersion_603262(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_603261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603263 = path.getOrDefault("restapi_id")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = nil)
  if valid_603263 != nil:
    section.add "restapi_id", valid_603263
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603264 = header.getOrDefault("X-Amz-Date")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Date", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Security-Token")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Security-Token", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Content-Sha256", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Algorithm")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Algorithm", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Signature")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Signature", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-SignedHeaders", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603272: Call_CreateDocumentationVersion_603260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603272.validator(path, query, header, formData, body)
  let scheme = call_603272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603272.url(scheme.get, call_603272.host, call_603272.base,
                         call_603272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603272, url, valid)

proc call*(call_603273: Call_CreateDocumentationVersion_603260; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603274 = newJObject()
  var body_603275 = newJObject()
  if body != nil:
    body_603275 = body
  add(path_603274, "restapi_id", newJString(restapiId))
  result = call_603273.call(path_603274, nil, nil, nil, body_603275)

var createDocumentationVersion* = Call_CreateDocumentationVersion_603260(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_603261, base: "/",
    url: url_CreateDocumentationVersion_603262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_603243 = ref object of OpenApiRestCall_602450
proc url_GetDocumentationVersions_603245(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_603244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_603246 = path.getOrDefault("restapi_id")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = nil)
  if valid_603246 != nil:
    section.add "restapi_id", valid_603246
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603247 = query.getOrDefault("position")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "position", valid_603247
  var valid_603248 = query.getOrDefault("limit")
  valid_603248 = validateParameter(valid_603248, JInt, required = false, default = nil)
  if valid_603248 != nil:
    section.add "limit", valid_603248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603249 = header.getOrDefault("X-Amz-Date")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Date", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Security-Token")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Security-Token", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Content-Sha256", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Algorithm")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Algorithm", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Signature")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Signature", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-SignedHeaders", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Credential")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Credential", valid_603255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603256: Call_GetDocumentationVersions_603243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603256.validator(path, query, header, formData, body)
  let scheme = call_603256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603256.url(scheme.get, call_603256.host, call_603256.base,
                         call_603256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603256, url, valid)

proc call*(call_603257: Call_GetDocumentationVersions_603243; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603258 = newJObject()
  var query_603259 = newJObject()
  add(query_603259, "position", newJString(position))
  add(query_603259, "limit", newJInt(limit))
  add(path_603258, "restapi_id", newJString(restapiId))
  result = call_603257.call(path_603258, query_603259, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_603243(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_603244, base: "/",
    url: url_GetDocumentationVersions_603245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_603291 = ref object of OpenApiRestCall_602450
proc url_CreateDomainName_603293(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainName_603292(path: JsonNode; query: JsonNode;
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
  var valid_603294 = header.getOrDefault("X-Amz-Date")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Date", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Security-Token")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Security-Token", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Content-Sha256", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Algorithm")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Algorithm", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Signature")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Signature", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-SignedHeaders", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Credential")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Credential", valid_603300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603302: Call_CreateDomainName_603291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_603302.validator(path, query, header, formData, body)
  let scheme = call_603302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603302.url(scheme.get, call_603302.host, call_603302.base,
                         call_603302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603302, url, valid)

proc call*(call_603303: Call_CreateDomainName_603291; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_603304 = newJObject()
  if body != nil:
    body_603304 = body
  result = call_603303.call(nil, nil, nil, nil, body_603304)

var createDomainName* = Call_CreateDomainName_603291(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_603292, base: "/",
    url: url_CreateDomainName_603293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_603276 = ref object of OpenApiRestCall_602450
proc url_GetDomainNames_603278(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainNames_603277(path: JsonNode; query: JsonNode;
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
  var valid_603279 = query.getOrDefault("position")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "position", valid_603279
  var valid_603280 = query.getOrDefault("limit")
  valid_603280 = validateParameter(valid_603280, JInt, required = false, default = nil)
  if valid_603280 != nil:
    section.add "limit", valid_603280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603281 = header.getOrDefault("X-Amz-Date")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Date", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Security-Token")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Security-Token", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Content-Sha256", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Algorithm")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Algorithm", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Signature")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Signature", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-SignedHeaders", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Credential")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Credential", valid_603287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603288: Call_GetDomainNames_603276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_603288.validator(path, query, header, formData, body)
  let scheme = call_603288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603288.url(scheme.get, call_603288.host, call_603288.base,
                         call_603288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603288, url, valid)

proc call*(call_603289: Call_GetDomainNames_603276; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603290 = newJObject()
  add(query_603290, "position", newJString(position))
  add(query_603290, "limit", newJInt(limit))
  result = call_603289.call(nil, query_603290, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_603276(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_603277, base: "/",
    url: url_GetDomainNames_603278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_603322 = ref object of OpenApiRestCall_602450
proc url_CreateModel_603324(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_603323(path: JsonNode; query: JsonNode; header: JsonNode;
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

proc call*(call_603334: Call_CreateModel_603322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_CreateModel_603322; body: JsonNode; restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_603336 = newJObject()
  var body_603337 = newJObject()
  if body != nil:
    body_603337 = body
  add(path_603336, "restapi_id", newJString(restapiId))
  result = call_603335.call(path_603336, nil, nil, nil, body_603337)

var createModel* = Call_CreateModel_603322(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/models",
                                        validator: validate_CreateModel_603323,
                                        base: "/", url: url_CreateModel_603324,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_603305 = ref object of OpenApiRestCall_602450
proc url_GetModels_603307(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_603306(path: JsonNode; query: JsonNode; header: JsonNode;
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

proc call*(call_603318: Call_GetModels_603305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_GetModels_603305; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
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

var getModels* = Call_GetModels_603305(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/models",
                                    validator: validate_GetModels_603306,
                                    base: "/", url: url_GetModels_603307,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_603355 = ref object of OpenApiRestCall_602450
proc url_CreateRequestValidator_603357(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRequestValidator_603356(path: JsonNode; query: JsonNode;
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
  var valid_603358 = path.getOrDefault("restapi_id")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = nil)
  if valid_603358 != nil:
    section.add "restapi_id", valid_603358
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603359 = header.getOrDefault("X-Amz-Date")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Date", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Security-Token")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Security-Token", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_CreateRequestValidator_603355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_CreateRequestValidator_603355; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603369 = newJObject()
  var body_603370 = newJObject()
  if body != nil:
    body_603370 = body
  add(path_603369, "restapi_id", newJString(restapiId))
  result = call_603368.call(path_603369, nil, nil, nil, body_603370)

var createRequestValidator* = Call_CreateRequestValidator_603355(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_603356, base: "/",
    url: url_CreateRequestValidator_603357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_603338 = ref object of OpenApiRestCall_602450
proc url_GetRequestValidators_603340(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_603339(path: JsonNode; query: JsonNode;
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
  var valid_603341 = path.getOrDefault("restapi_id")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "restapi_id", valid_603341
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603342 = query.getOrDefault("position")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "position", valid_603342
  var valid_603343 = query.getOrDefault("limit")
  valid_603343 = validateParameter(valid_603343, JInt, required = false, default = nil)
  if valid_603343 != nil:
    section.add "limit", valid_603343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603344 = header.getOrDefault("X-Amz-Date")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Date", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Security-Token")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Security-Token", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Content-Sha256", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Algorithm")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Algorithm", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Signature")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Signature", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-SignedHeaders", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Credential")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Credential", valid_603350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_GetRequestValidators_603338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_GetRequestValidators_603338; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603353 = newJObject()
  var query_603354 = newJObject()
  add(query_603354, "position", newJString(position))
  add(query_603354, "limit", newJInt(limit))
  add(path_603353, "restapi_id", newJString(restapiId))
  result = call_603352.call(path_603353, query_603354, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_603338(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_603339, base: "/",
    url: url_GetRequestValidators_603340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_603371 = ref object of OpenApiRestCall_602450
proc url_CreateResource_603373(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_603372(path: JsonNode; query: JsonNode;
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
  var valid_603374 = path.getOrDefault("parent_id")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = nil)
  if valid_603374 != nil:
    section.add "parent_id", valid_603374
  var valid_603375 = path.getOrDefault("restapi_id")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = nil)
  if valid_603375 != nil:
    section.add "restapi_id", valid_603375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603376 = header.getOrDefault("X-Amz-Date")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Date", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_CreateResource_603371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_CreateResource_603371; parentId: string; body: JsonNode;
          restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603386 = newJObject()
  var body_603387 = newJObject()
  add(path_603386, "parent_id", newJString(parentId))
  if body != nil:
    body_603387 = body
  add(path_603386, "restapi_id", newJString(restapiId))
  result = call_603385.call(path_603386, nil, nil, nil, body_603387)

var createResource* = Call_CreateResource_603371(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_603372, base: "/", url: url_CreateResource_603373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_603403 = ref object of OpenApiRestCall_602450
proc url_CreateRestApi_603405(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRestApi_603404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_CreateRestApi_603403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_CreateRestApi_603403; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var createRestApi* = Call_CreateRestApi_603403(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_603404, base: "/", url: url_CreateRestApi_603405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_603388 = ref object of OpenApiRestCall_602450
proc url_GetRestApis_603390(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestApis_603389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603391 = query.getOrDefault("position")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "position", valid_603391
  var valid_603392 = query.getOrDefault("limit")
  valid_603392 = validateParameter(valid_603392, JInt, required = false, default = nil)
  if valid_603392 != nil:
    section.add "limit", valid_603392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603393 = header.getOrDefault("X-Amz-Date")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Date", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Security-Token")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Security-Token", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Content-Sha256", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Algorithm")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Algorithm", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Signature")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Signature", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-SignedHeaders", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Credential")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Credential", valid_603399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_GetRestApis_603388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_GetRestApis_603388; position: string = ""; limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603402 = newJObject()
  add(query_603402, "position", newJString(position))
  add(query_603402, "limit", newJInt(limit))
  result = call_603401.call(nil, query_603402, nil, nil, nil)

var getRestApis* = Call_GetRestApis_603388(name: "getRestApis",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis",
                                        validator: validate_GetRestApis_603389,
                                        base: "/", url: url_GetRestApis_603390,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_603433 = ref object of OpenApiRestCall_602450
proc url_CreateStage_603435(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_603434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603436 = path.getOrDefault("restapi_id")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = nil)
  if valid_603436 != nil:
    section.add "restapi_id", valid_603436
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Security-Token")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Security-Token", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Signature")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Signature", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-SignedHeaders", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_CreateStage_603433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_CreateStage_603433; body: JsonNode; restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603447 = newJObject()
  var body_603448 = newJObject()
  if body != nil:
    body_603448 = body
  add(path_603447, "restapi_id", newJString(restapiId))
  result = call_603446.call(path_603447, nil, nil, nil, body_603448)

var createStage* = Call_CreateStage_603433(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}/stages",
                                        validator: validate_CreateStage_603434,
                                        base: "/", url: url_CreateStage_603435,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_603417 = ref object of OpenApiRestCall_602450
proc url_GetStages_603419(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_603418(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603420 = path.getOrDefault("restapi_id")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "restapi_id", valid_603420
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_603421 = query.getOrDefault("deploymentId")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "deploymentId", valid_603421
  result.add "query", section
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

proc call*(call_603429: Call_GetStages_603417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_GetStages_603417; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603431 = newJObject()
  var query_603432 = newJObject()
  add(query_603432, "deploymentId", newJString(deploymentId))
  add(path_603431, "restapi_id", newJString(restapiId))
  result = call_603430.call(path_603431, query_603432, nil, nil, nil)

var getStages* = Call_GetStages_603417(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/restapis/{restapi_id}/stages",
                                    validator: validate_GetStages_603418,
                                    base: "/", url: url_GetStages_603419,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_603465 = ref object of OpenApiRestCall_602450
proc url_CreateUsagePlan_603467(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUsagePlan_603466(path: JsonNode; query: JsonNode;
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

proc call*(call_603476: Call_CreateUsagePlan_603465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_603476.validator(path, query, header, formData, body)
  let scheme = call_603476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603476.url(scheme.get, call_603476.host, call_603476.base,
                         call_603476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603476, url, valid)

proc call*(call_603477: Call_CreateUsagePlan_603465; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_603478 = newJObject()
  if body != nil:
    body_603478 = body
  result = call_603477.call(nil, nil, nil, nil, body_603478)

var createUsagePlan* = Call_CreateUsagePlan_603465(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_603466, base: "/",
    url: url_CreateUsagePlan_603467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_603449 = ref object of OpenApiRestCall_602450
proc url_GetUsagePlans_603451(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUsagePlans_603450(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603452 = query.getOrDefault("keyId")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "keyId", valid_603452
  var valid_603453 = query.getOrDefault("position")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "position", valid_603453
  var valid_603454 = query.getOrDefault("limit")
  valid_603454 = validateParameter(valid_603454, JInt, required = false, default = nil)
  if valid_603454 != nil:
    section.add "limit", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603462: Call_GetUsagePlans_603449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_603462.validator(path, query, header, formData, body)
  let scheme = call_603462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603462.url(scheme.get, call_603462.host, call_603462.base,
                         call_603462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603462, url, valid)

proc call*(call_603463: Call_GetUsagePlans_603449; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603464 = newJObject()
  add(query_603464, "keyId", newJString(keyId))
  add(query_603464, "position", newJString(position))
  add(query_603464, "limit", newJInt(limit))
  result = call_603463.call(nil, query_603464, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_603449(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_603450, base: "/",
    url: url_GetUsagePlans_603451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_603497 = ref object of OpenApiRestCall_602450
proc url_CreateUsagePlanKey_603499(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_603498(path: JsonNode; query: JsonNode;
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
  var valid_603500 = path.getOrDefault("usageplanId")
  valid_603500 = validateParameter(valid_603500, JString, required = true,
                                 default = nil)
  if valid_603500 != nil:
    section.add "usageplanId", valid_603500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603501 = header.getOrDefault("X-Amz-Date")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Date", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Security-Token")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Security-Token", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Content-Sha256", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Algorithm")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Algorithm", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Signature")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Signature", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-SignedHeaders", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Credential")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Credential", valid_603507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603509: Call_CreateUsagePlanKey_603497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_603509.validator(path, query, header, formData, body)
  let scheme = call_603509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603509.url(scheme.get, call_603509.host, call_603509.base,
                         call_603509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603509, url, valid)

proc call*(call_603510: Call_CreateUsagePlanKey_603497; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_603511 = newJObject()
  var body_603512 = newJObject()
  add(path_603511, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_603512 = body
  result = call_603510.call(path_603511, nil, nil, nil, body_603512)

var createUsagePlanKey* = Call_CreateUsagePlanKey_603497(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_603498, base: "/",
    url: url_CreateUsagePlanKey_603499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_603479 = ref object of OpenApiRestCall_602450
proc url_GetUsagePlanKeys_603481(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_603480(path: JsonNode; query: JsonNode;
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
  var valid_603482 = path.getOrDefault("usageplanId")
  valid_603482 = validateParameter(valid_603482, JString, required = true,
                                 default = nil)
  if valid_603482 != nil:
    section.add "usageplanId", valid_603482
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_603483 = query.getOrDefault("name")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "name", valid_603483
  var valid_603484 = query.getOrDefault("position")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "position", valid_603484
  var valid_603485 = query.getOrDefault("limit")
  valid_603485 = validateParameter(valid_603485, JInt, required = false, default = nil)
  if valid_603485 != nil:
    section.add "limit", valid_603485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603486 = header.getOrDefault("X-Amz-Date")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Date", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Content-Sha256", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Algorithm")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Algorithm", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Signature")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Signature", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-SignedHeaders", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Credential")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Credential", valid_603492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_GetUsagePlanKeys_603479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_GetUsagePlanKeys_603479; usageplanId: string;
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
  var path_603495 = newJObject()
  var query_603496 = newJObject()
  add(path_603495, "usageplanId", newJString(usageplanId))
  add(query_603496, "name", newJString(name))
  add(query_603496, "position", newJString(position))
  add(query_603496, "limit", newJInt(limit))
  result = call_603494.call(path_603495, query_603496, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_603479(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_603480,
    base: "/", url: url_GetUsagePlanKeys_603481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_603528 = ref object of OpenApiRestCall_602450
proc url_CreateVpcLink_603530(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVpcLink_603529(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603531 = header.getOrDefault("X-Amz-Date")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Date", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Security-Token")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Security-Token", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Content-Sha256", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Algorithm")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Algorithm", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Signature")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Signature", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-SignedHeaders", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Credential")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Credential", valid_603537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603539: Call_CreateVpcLink_603528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_603539.validator(path, query, header, formData, body)
  let scheme = call_603539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603539.url(scheme.get, call_603539.host, call_603539.base,
                         call_603539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603539, url, valid)

proc call*(call_603540: Call_CreateVpcLink_603528; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_603541 = newJObject()
  if body != nil:
    body_603541 = body
  result = call_603540.call(nil, nil, nil, nil, body_603541)

var createVpcLink* = Call_CreateVpcLink_603528(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_603529, base: "/", url: url_CreateVpcLink_603530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_603513 = ref object of OpenApiRestCall_602450
proc url_GetVpcLinks_603515(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetVpcLinks_603514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603516 = query.getOrDefault("position")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "position", valid_603516
  var valid_603517 = query.getOrDefault("limit")
  valid_603517 = validateParameter(valid_603517, JInt, required = false, default = nil)
  if valid_603517 != nil:
    section.add "limit", valid_603517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603518 = header.getOrDefault("X-Amz-Date")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Date", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Security-Token")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Security-Token", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Content-Sha256", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Algorithm")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Algorithm", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-SignedHeaders", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Credential")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Credential", valid_603524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603525: Call_GetVpcLinks_603513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_603525.validator(path, query, header, formData, body)
  let scheme = call_603525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603525.url(scheme.get, call_603525.host, call_603525.base,
                         call_603525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603525, url, valid)

proc call*(call_603526: Call_GetVpcLinks_603513; position: string = ""; limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_603527 = newJObject()
  add(query_603527, "position", newJString(position))
  add(query_603527, "limit", newJInt(limit))
  result = call_603526.call(nil, query_603527, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_603513(name: "getVpcLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks",
                                        validator: validate_GetVpcLinks_603514,
                                        base: "/", url: url_GetVpcLinks_603515,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_603542 = ref object of OpenApiRestCall_602450
proc url_GetApiKey_603544(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApiKey_603543(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603545 = path.getOrDefault("api_Key")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = nil)
  if valid_603545 != nil:
    section.add "api_Key", valid_603545
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_603546 = query.getOrDefault("includeValue")
  valid_603546 = validateParameter(valid_603546, JBool, required = false, default = nil)
  if valid_603546 != nil:
    section.add "includeValue", valid_603546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Content-Sha256", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Credential")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Credential", valid_603553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603554: Call_GetApiKey_603542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_603554.validator(path, query, header, formData, body)
  let scheme = call_603554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603554.url(scheme.get, call_603554.host, call_603554.base,
                         call_603554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603554, url, valid)

proc call*(call_603555: Call_GetApiKey_603542; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_603556 = newJObject()
  var query_603557 = newJObject()
  add(query_603557, "includeValue", newJBool(includeValue))
  add(path_603556, "api_Key", newJString(apiKey))
  result = call_603555.call(path_603556, query_603557, nil, nil, nil)

var getApiKey* = Call_GetApiKey_603542(name: "getApiKey", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/apikeys/{api_Key}",
                                    validator: validate_GetApiKey_603543,
                                    base: "/", url: url_GetApiKey_603544,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_603572 = ref object of OpenApiRestCall_602450
proc url_UpdateApiKey_603574(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_603573(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603575 = path.getOrDefault("api_Key")
  valid_603575 = validateParameter(valid_603575, JString, required = true,
                                 default = nil)
  if valid_603575 != nil:
    section.add "api_Key", valid_603575
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603576 = header.getOrDefault("X-Amz-Date")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Date", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Security-Token")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Security-Token", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Content-Sha256", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Algorithm")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Algorithm", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Signature")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Signature", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-SignedHeaders", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Credential")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Credential", valid_603582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603584: Call_UpdateApiKey_603572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_603584.validator(path, query, header, formData, body)
  let scheme = call_603584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603584.url(scheme.get, call_603584.host, call_603584.base,
                         call_603584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603584, url, valid)

proc call*(call_603585: Call_UpdateApiKey_603572; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_603586 = newJObject()
  var body_603587 = newJObject()
  add(path_603586, "api_Key", newJString(apiKey))
  if body != nil:
    body_603587 = body
  result = call_603585.call(path_603586, nil, nil, nil, body_603587)

var updateApiKey* = Call_UpdateApiKey_603572(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_603573, base: "/",
    url: url_UpdateApiKey_603574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_603558 = ref object of OpenApiRestCall_602450
proc url_DeleteApiKey_603560(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_603559(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603561 = path.getOrDefault("api_Key")
  valid_603561 = validateParameter(valid_603561, JString, required = true,
                                 default = nil)
  if valid_603561 != nil:
    section.add "api_Key", valid_603561
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Content-Sha256", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Algorithm")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Algorithm", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Signature")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Signature", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-SignedHeaders", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Credential")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Credential", valid_603568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603569: Call_DeleteApiKey_603558; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_603569.validator(path, query, header, formData, body)
  let scheme = call_603569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603569.url(scheme.get, call_603569.host, call_603569.base,
                         call_603569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603569, url, valid)

proc call*(call_603570: Call_DeleteApiKey_603558; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_603571 = newJObject()
  add(path_603571, "api_Key", newJString(apiKey))
  result = call_603570.call(path_603571, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_603558(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_603559, base: "/",
    url: url_DeleteApiKey_603560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_603603 = ref object of OpenApiRestCall_602450
proc url_TestInvokeAuthorizer_603605(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_603604(path: JsonNode; query: JsonNode;
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
  var valid_603606 = path.getOrDefault("authorizer_id")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "authorizer_id", valid_603606
  var valid_603607 = path.getOrDefault("restapi_id")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = nil)
  if valid_603607 != nil:
    section.add "restapi_id", valid_603607
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603608 = header.getOrDefault("X-Amz-Date")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Date", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Security-Token")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Security-Token", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Algorithm")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Algorithm", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Signature")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Signature", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-SignedHeaders", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Credential")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Credential", valid_603614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603616: Call_TestInvokeAuthorizer_603603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_603616.validator(path, query, header, formData, body)
  let scheme = call_603616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603616.url(scheme.get, call_603616.host, call_603616.base,
                         call_603616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603616, url, valid)

proc call*(call_603617: Call_TestInvokeAuthorizer_603603; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603618 = newJObject()
  var body_603619 = newJObject()
  add(path_603618, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_603619 = body
  add(path_603618, "restapi_id", newJString(restapiId))
  result = call_603617.call(path_603618, nil, nil, nil, body_603619)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_603603(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_603604, base: "/",
    url: url_TestInvokeAuthorizer_603605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_603588 = ref object of OpenApiRestCall_602450
proc url_GetAuthorizer_603590(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_603589(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603591 = path.getOrDefault("authorizer_id")
  valid_603591 = validateParameter(valid_603591, JString, required = true,
                                 default = nil)
  if valid_603591 != nil:
    section.add "authorizer_id", valid_603591
  var valid_603592 = path.getOrDefault("restapi_id")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = nil)
  if valid_603592 != nil:
    section.add "restapi_id", valid_603592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603593 = header.getOrDefault("X-Amz-Date")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Date", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Security-Token")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Security-Token", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Content-Sha256", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Algorithm")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Algorithm", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Signature")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Signature", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-SignedHeaders", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Credential")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Credential", valid_603599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603600: Call_GetAuthorizer_603588; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603600.validator(path, query, header, formData, body)
  let scheme = call_603600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603600.url(scheme.get, call_603600.host, call_603600.base,
                         call_603600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603600, url, valid)

proc call*(call_603601: Call_GetAuthorizer_603588; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603602 = newJObject()
  add(path_603602, "authorizer_id", newJString(authorizerId))
  add(path_603602, "restapi_id", newJString(restapiId))
  result = call_603601.call(path_603602, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_603588(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_603589, base: "/", url: url_GetAuthorizer_603590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_603635 = ref object of OpenApiRestCall_602450
proc url_UpdateAuthorizer_603637(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_603636(path: JsonNode; query: JsonNode;
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
  var valid_603638 = path.getOrDefault("authorizer_id")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = nil)
  if valid_603638 != nil:
    section.add "authorizer_id", valid_603638
  var valid_603639 = path.getOrDefault("restapi_id")
  valid_603639 = validateParameter(valid_603639, JString, required = true,
                                 default = nil)
  if valid_603639 != nil:
    section.add "restapi_id", valid_603639
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Content-Sha256", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Algorithm")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Algorithm", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Signature")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Signature", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-SignedHeaders", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Credential")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Credential", valid_603646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_UpdateAuthorizer_603635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_UpdateAuthorizer_603635; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603650 = newJObject()
  var body_603651 = newJObject()
  add(path_603650, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_603651 = body
  add(path_603650, "restapi_id", newJString(restapiId))
  result = call_603649.call(path_603650, nil, nil, nil, body_603651)

var updateAuthorizer* = Call_UpdateAuthorizer_603635(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_603636, base: "/",
    url: url_UpdateAuthorizer_603637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_603620 = ref object of OpenApiRestCall_602450
proc url_DeleteAuthorizer_603622(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_603621(path: JsonNode; query: JsonNode;
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
  var valid_603623 = path.getOrDefault("authorizer_id")
  valid_603623 = validateParameter(valid_603623, JString, required = true,
                                 default = nil)
  if valid_603623 != nil:
    section.add "authorizer_id", valid_603623
  var valid_603624 = path.getOrDefault("restapi_id")
  valid_603624 = validateParameter(valid_603624, JString, required = true,
                                 default = nil)
  if valid_603624 != nil:
    section.add "restapi_id", valid_603624
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603625 = header.getOrDefault("X-Amz-Date")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Date", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Security-Token")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Security-Token", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Content-Sha256", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Algorithm")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Algorithm", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Signature")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Signature", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-SignedHeaders", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Credential")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Credential", valid_603631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603632: Call_DeleteAuthorizer_603620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_603632.validator(path, query, header, formData, body)
  let scheme = call_603632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603632.url(scheme.get, call_603632.host, call_603632.base,
                         call_603632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603632, url, valid)

proc call*(call_603633: Call_DeleteAuthorizer_603620; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603634 = newJObject()
  add(path_603634, "authorizer_id", newJString(authorizerId))
  add(path_603634, "restapi_id", newJString(restapiId))
  result = call_603633.call(path_603634, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_603620(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_603621, base: "/",
    url: url_DeleteAuthorizer_603622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_603652 = ref object of OpenApiRestCall_602450
proc url_GetBasePathMapping_603654(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_603653(path: JsonNode; query: JsonNode;
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
  var valid_603655 = path.getOrDefault("base_path")
  valid_603655 = validateParameter(valid_603655, JString, required = true,
                                 default = nil)
  if valid_603655 != nil:
    section.add "base_path", valid_603655
  var valid_603656 = path.getOrDefault("domain_name")
  valid_603656 = validateParameter(valid_603656, JString, required = true,
                                 default = nil)
  if valid_603656 != nil:
    section.add "domain_name", valid_603656
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603657 = header.getOrDefault("X-Amz-Date")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Date", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Security-Token")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Security-Token", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Content-Sha256", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Algorithm")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Algorithm", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Signature")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Signature", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-SignedHeaders", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Credential")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Credential", valid_603663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603664: Call_GetBasePathMapping_603652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603664.validator(path, query, header, formData, body)
  let scheme = call_603664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603664.url(scheme.get, call_603664.host, call_603664.base,
                         call_603664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603664, url, valid)

proc call*(call_603665: Call_GetBasePathMapping_603652; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_603666 = newJObject()
  add(path_603666, "base_path", newJString(basePath))
  add(path_603666, "domain_name", newJString(domainName))
  result = call_603665.call(path_603666, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_603652(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_603653, base: "/",
    url: url_GetBasePathMapping_603654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_603682 = ref object of OpenApiRestCall_602450
proc url_UpdateBasePathMapping_603684(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBasePathMapping_603683(path: JsonNode; query: JsonNode;
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
  var valid_603685 = path.getOrDefault("base_path")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = nil)
  if valid_603685 != nil:
    section.add "base_path", valid_603685
  var valid_603686 = path.getOrDefault("domain_name")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "domain_name", valid_603686
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603687 = header.getOrDefault("X-Amz-Date")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Date", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Security-Token")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Security-Token", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Content-Sha256", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Algorithm")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Algorithm", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Signature")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Signature", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-SignedHeaders", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Credential")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Credential", valid_603693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603695: Call_UpdateBasePathMapping_603682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603695.validator(path, query, header, formData, body)
  let scheme = call_603695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603695.url(scheme.get, call_603695.host, call_603695.base,
                         call_603695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603695, url, valid)

proc call*(call_603696: Call_UpdateBasePathMapping_603682; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_603697 = newJObject()
  var body_603698 = newJObject()
  add(path_603697, "base_path", newJString(basePath))
  add(path_603697, "domain_name", newJString(domainName))
  if body != nil:
    body_603698 = body
  result = call_603696.call(path_603697, nil, nil, nil, body_603698)

var updateBasePathMapping* = Call_UpdateBasePathMapping_603682(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_603683, base: "/",
    url: url_UpdateBasePathMapping_603684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_603667 = ref object of OpenApiRestCall_602450
proc url_DeleteBasePathMapping_603669(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBasePathMapping_603668(path: JsonNode; query: JsonNode;
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
  var valid_603670 = path.getOrDefault("base_path")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = nil)
  if valid_603670 != nil:
    section.add "base_path", valid_603670
  var valid_603671 = path.getOrDefault("domain_name")
  valid_603671 = validateParameter(valid_603671, JString, required = true,
                                 default = nil)
  if valid_603671 != nil:
    section.add "domain_name", valid_603671
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603672 = header.getOrDefault("X-Amz-Date")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Date", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Security-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Security-Token", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Content-Sha256", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Algorithm")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Algorithm", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Signature")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Signature", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-SignedHeaders", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Credential")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Credential", valid_603678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_DeleteBasePathMapping_603667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603679, url, valid)

proc call*(call_603680: Call_DeleteBasePathMapping_603667; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_603681 = newJObject()
  add(path_603681, "base_path", newJString(basePath))
  add(path_603681, "domain_name", newJString(domainName))
  result = call_603680.call(path_603681, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_603667(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_603668, base: "/",
    url: url_DeleteBasePathMapping_603669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_603699 = ref object of OpenApiRestCall_602450
proc url_GetClientCertificate_603701(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_603700(path: JsonNode; query: JsonNode;
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
  var valid_603702 = path.getOrDefault("clientcertificate_id")
  valid_603702 = validateParameter(valid_603702, JString, required = true,
                                 default = nil)
  if valid_603702 != nil:
    section.add "clientcertificate_id", valid_603702
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603703 = header.getOrDefault("X-Amz-Date")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Date", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Security-Token")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Security-Token", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Content-Sha256", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Algorithm")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Algorithm", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Signature")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Signature", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-SignedHeaders", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Credential")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Credential", valid_603709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603710: Call_GetClientCertificate_603699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603710.validator(path, query, header, formData, body)
  let scheme = call_603710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603710.url(scheme.get, call_603710.host, call_603710.base,
                         call_603710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603710, url, valid)

proc call*(call_603711: Call_GetClientCertificate_603699;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_603712 = newJObject()
  add(path_603712, "clientcertificate_id", newJString(clientcertificateId))
  result = call_603711.call(path_603712, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_603699(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_603700, base: "/",
    url: url_GetClientCertificate_603701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_603727 = ref object of OpenApiRestCall_602450
proc url_UpdateClientCertificate_603729(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClientCertificate_603728(path: JsonNode; query: JsonNode;
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
  var valid_603730 = path.getOrDefault("clientcertificate_id")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = nil)
  if valid_603730 != nil:
    section.add "clientcertificate_id", valid_603730
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603731 = header.getOrDefault("X-Amz-Date")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Date", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Security-Token")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Security-Token", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Content-Sha256", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Algorithm")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Algorithm", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Signature")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Signature", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-SignedHeaders", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Credential")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Credential", valid_603737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_UpdateClientCertificate_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_UpdateClientCertificate_603727;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_603741 = newJObject()
  var body_603742 = newJObject()
  add(path_603741, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_603742 = body
  result = call_603740.call(path_603741, nil, nil, nil, body_603742)

var updateClientCertificate* = Call_UpdateClientCertificate_603727(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_603728, base: "/",
    url: url_UpdateClientCertificate_603729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_603713 = ref object of OpenApiRestCall_602450
proc url_DeleteClientCertificate_603715(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClientCertificate_603714(path: JsonNode; query: JsonNode;
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
  var valid_603716 = path.getOrDefault("clientcertificate_id")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = nil)
  if valid_603716 != nil:
    section.add "clientcertificate_id", valid_603716
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603717 = header.getOrDefault("X-Amz-Date")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Date", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Security-Token")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Security-Token", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Content-Sha256", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Algorithm")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Algorithm", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Signature")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Signature", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-SignedHeaders", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Credential")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Credential", valid_603723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603724: Call_DeleteClientCertificate_603713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_603724.validator(path, query, header, formData, body)
  let scheme = call_603724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603724.url(scheme.get, call_603724.host, call_603724.base,
                         call_603724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603724, url, valid)

proc call*(call_603725: Call_DeleteClientCertificate_603713;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_603726 = newJObject()
  add(path_603726, "clientcertificate_id", newJString(clientcertificateId))
  result = call_603725.call(path_603726, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_603713(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_603714, base: "/",
    url: url_DeleteClientCertificate_603715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_603743 = ref object of OpenApiRestCall_602450
proc url_GetDeployment_603745(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_603744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603746 = path.getOrDefault("deployment_id")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "deployment_id", valid_603746
  var valid_603747 = path.getOrDefault("restapi_id")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = nil)
  if valid_603747 != nil:
    section.add "restapi_id", valid_603747
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_603748 = query.getOrDefault("embed")
  valid_603748 = validateParameter(valid_603748, JArray, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "embed", valid_603748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Security-Token")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Security-Token", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_GetDeployment_603743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_GetDeployment_603743; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603758 = newJObject()
  var query_603759 = newJObject()
  add(path_603758, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_603759.add "embed", embed
  add(path_603758, "restapi_id", newJString(restapiId))
  result = call_603757.call(path_603758, query_603759, nil, nil, nil)

var getDeployment* = Call_GetDeployment_603743(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_603744, base: "/", url: url_GetDeployment_603745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_603775 = ref object of OpenApiRestCall_602450
proc url_UpdateDeployment_603777(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_603776(path: JsonNode; query: JsonNode;
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
  var valid_603778 = path.getOrDefault("deployment_id")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = nil)
  if valid_603778 != nil:
    section.add "deployment_id", valid_603778
  var valid_603779 = path.getOrDefault("restapi_id")
  valid_603779 = validateParameter(valid_603779, JString, required = true,
                                 default = nil)
  if valid_603779 != nil:
    section.add "restapi_id", valid_603779
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603780 = header.getOrDefault("X-Amz-Date")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Date", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Security-Token")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Security-Token", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Content-Sha256", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Algorithm")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Algorithm", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Signature")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Signature", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-SignedHeaders", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Credential")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Credential", valid_603786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_UpdateDeployment_603775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603788, url, valid)

proc call*(call_603789: Call_UpdateDeployment_603775; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603790 = newJObject()
  var body_603791 = newJObject()
  add(path_603790, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_603791 = body
  add(path_603790, "restapi_id", newJString(restapiId))
  result = call_603789.call(path_603790, nil, nil, nil, body_603791)

var updateDeployment* = Call_UpdateDeployment_603775(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_603776, base: "/",
    url: url_UpdateDeployment_603777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_603760 = ref object of OpenApiRestCall_602450
proc url_DeleteDeployment_603762(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_603761(path: JsonNode; query: JsonNode;
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
  var valid_603763 = path.getOrDefault("deployment_id")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = nil)
  if valid_603763 != nil:
    section.add "deployment_id", valid_603763
  var valid_603764 = path.getOrDefault("restapi_id")
  valid_603764 = validateParameter(valid_603764, JString, required = true,
                                 default = nil)
  if valid_603764 != nil:
    section.add "restapi_id", valid_603764
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603765 = header.getOrDefault("X-Amz-Date")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Date", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Security-Token")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Security-Token", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Content-Sha256", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Algorithm")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Algorithm", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Signature")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Signature", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-SignedHeaders", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Credential")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Credential", valid_603771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603772: Call_DeleteDeployment_603760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_603772.validator(path, query, header, formData, body)
  let scheme = call_603772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603772.url(scheme.get, call_603772.host, call_603772.base,
                         call_603772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603772, url, valid)

proc call*(call_603773: Call_DeleteDeployment_603760; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603774 = newJObject()
  add(path_603774, "deployment_id", newJString(deploymentId))
  add(path_603774, "restapi_id", newJString(restapiId))
  result = call_603773.call(path_603774, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_603760(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_603761, base: "/",
    url: url_DeleteDeployment_603762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_603792 = ref object of OpenApiRestCall_602450
proc url_GetDocumentationPart_603794(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_603793(path: JsonNode; query: JsonNode;
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
  var valid_603795 = path.getOrDefault("part_id")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = nil)
  if valid_603795 != nil:
    section.add "part_id", valid_603795
  var valid_603796 = path.getOrDefault("restapi_id")
  valid_603796 = validateParameter(valid_603796, JString, required = true,
                                 default = nil)
  if valid_603796 != nil:
    section.add "restapi_id", valid_603796
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Security-Token")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Security-Token", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_GetDocumentationPart_603792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_GetDocumentationPart_603792; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603806 = newJObject()
  add(path_603806, "part_id", newJString(partId))
  add(path_603806, "restapi_id", newJString(restapiId))
  result = call_603805.call(path_603806, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_603792(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_603793, base: "/",
    url: url_GetDocumentationPart_603794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_603822 = ref object of OpenApiRestCall_602450
proc url_UpdateDocumentationPart_603824(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentationPart_603823(path: JsonNode; query: JsonNode;
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
  var valid_603825 = path.getOrDefault("part_id")
  valid_603825 = validateParameter(valid_603825, JString, required = true,
                                 default = nil)
  if valid_603825 != nil:
    section.add "part_id", valid_603825
  var valid_603826 = path.getOrDefault("restapi_id")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = nil)
  if valid_603826 != nil:
    section.add "restapi_id", valid_603826
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603827 = header.getOrDefault("X-Amz-Date")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Date", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Security-Token")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Security-Token", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Content-Sha256", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Algorithm")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Algorithm", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Signature")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Signature", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-SignedHeaders", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Credential")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Credential", valid_603833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603835: Call_UpdateDocumentationPart_603822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603835.validator(path, query, header, formData, body)
  let scheme = call_603835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603835.url(scheme.get, call_603835.host, call_603835.base,
                         call_603835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603835, url, valid)

proc call*(call_603836: Call_UpdateDocumentationPart_603822; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603837 = newJObject()
  var body_603838 = newJObject()
  if body != nil:
    body_603838 = body
  add(path_603837, "part_id", newJString(partId))
  add(path_603837, "restapi_id", newJString(restapiId))
  result = call_603836.call(path_603837, nil, nil, nil, body_603838)

var updateDocumentationPart* = Call_UpdateDocumentationPart_603822(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_603823, base: "/",
    url: url_UpdateDocumentationPart_603824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_603807 = ref object of OpenApiRestCall_602450
proc url_DeleteDocumentationPart_603809(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocumentationPart_603808(path: JsonNode; query: JsonNode;
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
  var valid_603810 = path.getOrDefault("part_id")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = nil)
  if valid_603810 != nil:
    section.add "part_id", valid_603810
  var valid_603811 = path.getOrDefault("restapi_id")
  valid_603811 = validateParameter(valid_603811, JString, required = true,
                                 default = nil)
  if valid_603811 != nil:
    section.add "restapi_id", valid_603811
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603812 = header.getOrDefault("X-Amz-Date")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Date", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Security-Token")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Security-Token", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Content-Sha256", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Algorithm")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Algorithm", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Signature")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Signature", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-SignedHeaders", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Credential")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Credential", valid_603818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603819: Call_DeleteDocumentationPart_603807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603819.validator(path, query, header, formData, body)
  let scheme = call_603819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603819.url(scheme.get, call_603819.host, call_603819.base,
                         call_603819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603819, url, valid)

proc call*(call_603820: Call_DeleteDocumentationPart_603807; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603821 = newJObject()
  add(path_603821, "part_id", newJString(partId))
  add(path_603821, "restapi_id", newJString(restapiId))
  result = call_603820.call(path_603821, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_603807(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_603808, base: "/",
    url: url_DeleteDocumentationPart_603809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_603839 = ref object of OpenApiRestCall_602450
proc url_GetDocumentationVersion_603841(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationVersion_603840(path: JsonNode; query: JsonNode;
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
  var valid_603842 = path.getOrDefault("doc_version")
  valid_603842 = validateParameter(valid_603842, JString, required = true,
                                 default = nil)
  if valid_603842 != nil:
    section.add "doc_version", valid_603842
  var valid_603843 = path.getOrDefault("restapi_id")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = nil)
  if valid_603843 != nil:
    section.add "restapi_id", valid_603843
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603844 = header.getOrDefault("X-Amz-Date")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Date", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Security-Token")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Security-Token", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Content-Sha256", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Algorithm")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Algorithm", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Signature")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Signature", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-SignedHeaders", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Credential")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Credential", valid_603850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603851: Call_GetDocumentationVersion_603839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603851.validator(path, query, header, formData, body)
  let scheme = call_603851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603851.url(scheme.get, call_603851.host, call_603851.base,
                         call_603851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603851, url, valid)

proc call*(call_603852: Call_GetDocumentationVersion_603839; docVersion: string;
          restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603853 = newJObject()
  add(path_603853, "doc_version", newJString(docVersion))
  add(path_603853, "restapi_id", newJString(restapiId))
  result = call_603852.call(path_603853, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_603839(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_603840, base: "/",
    url: url_GetDocumentationVersion_603841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_603869 = ref object of OpenApiRestCall_602450
proc url_UpdateDocumentationVersion_603871(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_603870(path: JsonNode; query: JsonNode;
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
  var valid_603872 = path.getOrDefault("doc_version")
  valid_603872 = validateParameter(valid_603872, JString, required = true,
                                 default = nil)
  if valid_603872 != nil:
    section.add "doc_version", valid_603872
  var valid_603873 = path.getOrDefault("restapi_id")
  valid_603873 = validateParameter(valid_603873, JString, required = true,
                                 default = nil)
  if valid_603873 != nil:
    section.add "restapi_id", valid_603873
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603874 = header.getOrDefault("X-Amz-Date")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Date", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Security-Token")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Security-Token", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Content-Sha256", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Algorithm")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Algorithm", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Signature")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Signature", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-SignedHeaders", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Credential")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Credential", valid_603880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603882: Call_UpdateDocumentationVersion_603869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603882.validator(path, query, header, formData, body)
  let scheme = call_603882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603882.url(scheme.get, call_603882.host, call_603882.base,
                         call_603882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603882, url, valid)

proc call*(call_603883: Call_UpdateDocumentationVersion_603869; docVersion: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_603884 = newJObject()
  var body_603885 = newJObject()
  add(path_603884, "doc_version", newJString(docVersion))
  if body != nil:
    body_603885 = body
  add(path_603884, "restapi_id", newJString(restapiId))
  result = call_603883.call(path_603884, nil, nil, nil, body_603885)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_603869(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_603870, base: "/",
    url: url_UpdateDocumentationVersion_603871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_603854 = ref object of OpenApiRestCall_602450
proc url_DeleteDocumentationVersion_603856(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_603855(path: JsonNode; query: JsonNode;
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
  var valid_603857 = path.getOrDefault("doc_version")
  valid_603857 = validateParameter(valid_603857, JString, required = true,
                                 default = nil)
  if valid_603857 != nil:
    section.add "doc_version", valid_603857
  var valid_603858 = path.getOrDefault("restapi_id")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = nil)
  if valid_603858 != nil:
    section.add "restapi_id", valid_603858
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603859 = header.getOrDefault("X-Amz-Date")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Date", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Security-Token")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Security-Token", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Content-Sha256", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Algorithm")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Algorithm", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Signature")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Signature", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-SignedHeaders", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Credential")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Credential", valid_603865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603866: Call_DeleteDocumentationVersion_603854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603866.validator(path, query, header, formData, body)
  let scheme = call_603866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603866.url(scheme.get, call_603866.host, call_603866.base,
                         call_603866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603866, url, valid)

proc call*(call_603867: Call_DeleteDocumentationVersion_603854; docVersion: string;
          restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_603868 = newJObject()
  add(path_603868, "doc_version", newJString(docVersion))
  add(path_603868, "restapi_id", newJString(restapiId))
  result = call_603867.call(path_603868, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_603854(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_603855, base: "/",
    url: url_DeleteDocumentationVersion_603856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_603886 = ref object of OpenApiRestCall_602450
proc url_GetDomainName_603888(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_603887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603889 = path.getOrDefault("domain_name")
  valid_603889 = validateParameter(valid_603889, JString, required = true,
                                 default = nil)
  if valid_603889 != nil:
    section.add "domain_name", valid_603889
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603890 = header.getOrDefault("X-Amz-Date")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Date", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Security-Token")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Security-Token", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Content-Sha256", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Algorithm")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Algorithm", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Signature")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Signature", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-SignedHeaders", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Credential")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Credential", valid_603896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603897: Call_GetDomainName_603886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_603897.validator(path, query, header, formData, body)
  let scheme = call_603897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603897.url(scheme.get, call_603897.host, call_603897.base,
                         call_603897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603897, url, valid)

proc call*(call_603898: Call_GetDomainName_603886; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_603899 = newJObject()
  add(path_603899, "domain_name", newJString(domainName))
  result = call_603898.call(path_603899, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_603886(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_603887,
    base: "/", url: url_GetDomainName_603888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_603914 = ref object of OpenApiRestCall_602450
proc url_UpdateDomainName_603916(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_603915(path: JsonNode; query: JsonNode;
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
  var valid_603917 = path.getOrDefault("domain_name")
  valid_603917 = validateParameter(valid_603917, JString, required = true,
                                 default = nil)
  if valid_603917 != nil:
    section.add "domain_name", valid_603917
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603918 = header.getOrDefault("X-Amz-Date")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Date", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Security-Token")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Security-Token", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Content-Sha256", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Algorithm")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Algorithm", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Signature")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Signature", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-SignedHeaders", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Credential")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Credential", valid_603924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603926: Call_UpdateDomainName_603914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_603926.validator(path, query, header, formData, body)
  let scheme = call_603926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603926.url(scheme.get, call_603926.host, call_603926.base,
                         call_603926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603926, url, valid)

proc call*(call_603927: Call_UpdateDomainName_603914; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_603928 = newJObject()
  var body_603929 = newJObject()
  add(path_603928, "domain_name", newJString(domainName))
  if body != nil:
    body_603929 = body
  result = call_603927.call(path_603928, nil, nil, nil, body_603929)

var updateDomainName* = Call_UpdateDomainName_603914(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_603915,
    base: "/", url: url_UpdateDomainName_603916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_603900 = ref object of OpenApiRestCall_602450
proc url_DeleteDomainName_603902(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_603901(path: JsonNode; query: JsonNode;
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
  var valid_603903 = path.getOrDefault("domain_name")
  valid_603903 = validateParameter(valid_603903, JString, required = true,
                                 default = nil)
  if valid_603903 != nil:
    section.add "domain_name", valid_603903
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603904 = header.getOrDefault("X-Amz-Date")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Date", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Security-Token")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Security-Token", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603911: Call_DeleteDomainName_603900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_603911.validator(path, query, header, formData, body)
  let scheme = call_603911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603911.url(scheme.get, call_603911.host, call_603911.base,
                         call_603911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603911, url, valid)

proc call*(call_603912: Call_DeleteDomainName_603900; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_603913 = newJObject()
  add(path_603913, "domain_name", newJString(domainName))
  result = call_603912.call(path_603913, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_603900(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_603901,
    base: "/", url: url_DeleteDomainName_603902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_603945 = ref object of OpenApiRestCall_602450
proc url_PutGatewayResponse_603947(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_603946(path: JsonNode; query: JsonNode;
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
  var valid_603948 = path.getOrDefault("response_type")
  valid_603948 = validateParameter(valid_603948, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603948 != nil:
    section.add "response_type", valid_603948
  var valid_603949 = path.getOrDefault("restapi_id")
  valid_603949 = validateParameter(valid_603949, JString, required = true,
                                 default = nil)
  if valid_603949 != nil:
    section.add "restapi_id", valid_603949
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603950 = header.getOrDefault("X-Amz-Date")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Date", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Security-Token")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Security-Token", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Content-Sha256", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Algorithm")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Algorithm", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Signature")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Signature", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-SignedHeaders", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Credential")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Credential", valid_603956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603958: Call_PutGatewayResponse_603945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_603958.validator(path, query, header, formData, body)
  let scheme = call_603958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603958.url(scheme.get, call_603958.host, call_603958.base,
                         call_603958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603958, url, valid)

proc call*(call_603959: Call_PutGatewayResponse_603945; body: JsonNode;
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
  var path_603960 = newJObject()
  var body_603961 = newJObject()
  add(path_603960, "response_type", newJString(responseType))
  if body != nil:
    body_603961 = body
  add(path_603960, "restapi_id", newJString(restapiId))
  result = call_603959.call(path_603960, nil, nil, nil, body_603961)

var putGatewayResponse* = Call_PutGatewayResponse_603945(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_603946, base: "/",
    url: url_PutGatewayResponse_603947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_603930 = ref object of OpenApiRestCall_602450
proc url_GetGatewayResponse_603932(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_603931(path: JsonNode; query: JsonNode;
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
  var valid_603933 = path.getOrDefault("response_type")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603933 != nil:
    section.add "response_type", valid_603933
  var valid_603934 = path.getOrDefault("restapi_id")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = nil)
  if valid_603934 != nil:
    section.add "restapi_id", valid_603934
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603935 = header.getOrDefault("X-Amz-Date")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Date", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Security-Token")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Security-Token", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Content-Sha256", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Signature")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Signature", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-SignedHeaders", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Credential")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Credential", valid_603941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603942: Call_GetGatewayResponse_603930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_603942.validator(path, query, header, formData, body)
  let scheme = call_603942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603942.url(scheme.get, call_603942.host, call_603942.base,
                         call_603942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603942, url, valid)

proc call*(call_603943: Call_GetGatewayResponse_603930; restapiId: string;
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
  var path_603944 = newJObject()
  add(path_603944, "response_type", newJString(responseType))
  add(path_603944, "restapi_id", newJString(restapiId))
  result = call_603943.call(path_603944, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_603930(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_603931, base: "/",
    url: url_GetGatewayResponse_603932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_603977 = ref object of OpenApiRestCall_602450
proc url_UpdateGatewayResponse_603979(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayResponse_603978(path: JsonNode; query: JsonNode;
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
  var valid_603980 = path.getOrDefault("response_type")
  valid_603980 = validateParameter(valid_603980, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603980 != nil:
    section.add "response_type", valid_603980
  var valid_603981 = path.getOrDefault("restapi_id")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = nil)
  if valid_603981 != nil:
    section.add "restapi_id", valid_603981
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603982 = header.getOrDefault("X-Amz-Date")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Date", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Security-Token")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Security-Token", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Content-Sha256", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Algorithm")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Algorithm", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Signature")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Signature", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-SignedHeaders", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Credential")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Credential", valid_603988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603990: Call_UpdateGatewayResponse_603977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_603990.validator(path, query, header, formData, body)
  let scheme = call_603990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603990.url(scheme.get, call_603990.host, call_603990.base,
                         call_603990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603990, url, valid)

proc call*(call_603991: Call_UpdateGatewayResponse_603977; body: JsonNode;
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
  var path_603992 = newJObject()
  var body_603993 = newJObject()
  add(path_603992, "response_type", newJString(responseType))
  if body != nil:
    body_603993 = body
  add(path_603992, "restapi_id", newJString(restapiId))
  result = call_603991.call(path_603992, nil, nil, nil, body_603993)

var updateGatewayResponse* = Call_UpdateGatewayResponse_603977(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_603978, base: "/",
    url: url_UpdateGatewayResponse_603979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_603962 = ref object of OpenApiRestCall_602450
proc url_DeleteGatewayResponse_603964(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayResponse_603963(path: JsonNode; query: JsonNode;
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
  var valid_603965 = path.getOrDefault("response_type")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = newJString("DEFAULT_4XX"))
  if valid_603965 != nil:
    section.add "response_type", valid_603965
  var valid_603966 = path.getOrDefault("restapi_id")
  valid_603966 = validateParameter(valid_603966, JString, required = true,
                                 default = nil)
  if valid_603966 != nil:
    section.add "restapi_id", valid_603966
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_603974: Call_DeleteGatewayResponse_603962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_603974.validator(path, query, header, formData, body)
  let scheme = call_603974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603974.url(scheme.get, call_603974.host, call_603974.base,
                         call_603974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603974, url, valid)

proc call*(call_603975: Call_DeleteGatewayResponse_603962; restapiId: string;
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
  var path_603976 = newJObject()
  add(path_603976, "response_type", newJString(responseType))
  add(path_603976, "restapi_id", newJString(restapiId))
  result = call_603975.call(path_603976, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_603962(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_603963, base: "/",
    url: url_DeleteGatewayResponse_603964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_604010 = ref object of OpenApiRestCall_602450
proc url_PutIntegration_604012(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_604011(path: JsonNode; query: JsonNode;
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
  var valid_604013 = path.getOrDefault("http_method")
  valid_604013 = validateParameter(valid_604013, JString, required = true,
                                 default = nil)
  if valid_604013 != nil:
    section.add "http_method", valid_604013
  var valid_604014 = path.getOrDefault("restapi_id")
  valid_604014 = validateParameter(valid_604014, JString, required = true,
                                 default = nil)
  if valid_604014 != nil:
    section.add "restapi_id", valid_604014
  var valid_604015 = path.getOrDefault("resource_id")
  valid_604015 = validateParameter(valid_604015, JString, required = true,
                                 default = nil)
  if valid_604015 != nil:
    section.add "resource_id", valid_604015
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604016 = header.getOrDefault("X-Amz-Date")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Date", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Security-Token")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Security-Token", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Content-Sha256", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Algorithm")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Algorithm", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Signature")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Signature", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-SignedHeaders", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Credential")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Credential", valid_604022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604024: Call_PutIntegration_604010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_604024.validator(path, query, header, formData, body)
  let scheme = call_604024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604024.url(scheme.get, call_604024.host, call_604024.base,
                         call_604024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604024, url, valid)

proc call*(call_604025: Call_PutIntegration_604010; httpMethod: string;
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
  var path_604026 = newJObject()
  var body_604027 = newJObject()
  add(path_604026, "http_method", newJString(httpMethod))
  if body != nil:
    body_604027 = body
  add(path_604026, "restapi_id", newJString(restapiId))
  add(path_604026, "resource_id", newJString(resourceId))
  result = call_604025.call(path_604026, nil, nil, nil, body_604027)

var putIntegration* = Call_PutIntegration_604010(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_604011, base: "/", url: url_PutIntegration_604012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_603994 = ref object of OpenApiRestCall_602450
proc url_GetIntegration_603996(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_603995(path: JsonNode; query: JsonNode;
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
  var valid_603997 = path.getOrDefault("http_method")
  valid_603997 = validateParameter(valid_603997, JString, required = true,
                                 default = nil)
  if valid_603997 != nil:
    section.add "http_method", valid_603997
  var valid_603998 = path.getOrDefault("restapi_id")
  valid_603998 = validateParameter(valid_603998, JString, required = true,
                                 default = nil)
  if valid_603998 != nil:
    section.add "restapi_id", valid_603998
  var valid_603999 = path.getOrDefault("resource_id")
  valid_603999 = validateParameter(valid_603999, JString, required = true,
                                 default = nil)
  if valid_603999 != nil:
    section.add "resource_id", valid_603999
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604000 = header.getOrDefault("X-Amz-Date")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Date", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Security-Token")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Security-Token", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Content-Sha256", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Algorithm")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Algorithm", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Signature")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Signature", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-SignedHeaders", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Credential")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Credential", valid_604006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604007: Call_GetIntegration_603994; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_604007.validator(path, query, header, formData, body)
  let scheme = call_604007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604007.url(scheme.get, call_604007.host, call_604007.base,
                         call_604007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604007, url, valid)

proc call*(call_604008: Call_GetIntegration_603994; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_604009 = newJObject()
  add(path_604009, "http_method", newJString(httpMethod))
  add(path_604009, "restapi_id", newJString(restapiId))
  add(path_604009, "resource_id", newJString(resourceId))
  result = call_604008.call(path_604009, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_603994(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_603995, base: "/", url: url_GetIntegration_603996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_604044 = ref object of OpenApiRestCall_602450
proc url_UpdateIntegration_604046(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_604045(path: JsonNode; query: JsonNode;
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
  var valid_604047 = path.getOrDefault("http_method")
  valid_604047 = validateParameter(valid_604047, JString, required = true,
                                 default = nil)
  if valid_604047 != nil:
    section.add "http_method", valid_604047
  var valid_604048 = path.getOrDefault("restapi_id")
  valid_604048 = validateParameter(valid_604048, JString, required = true,
                                 default = nil)
  if valid_604048 != nil:
    section.add "restapi_id", valid_604048
  var valid_604049 = path.getOrDefault("resource_id")
  valid_604049 = validateParameter(valid_604049, JString, required = true,
                                 default = nil)
  if valid_604049 != nil:
    section.add "resource_id", valid_604049
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604050 = header.getOrDefault("X-Amz-Date")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Date", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Security-Token")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Security-Token", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Content-Sha256", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-Algorithm")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Algorithm", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Signature")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Signature", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-SignedHeaders", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Credential")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Credential", valid_604056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604058: Call_UpdateIntegration_604044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_604058.validator(path, query, header, formData, body)
  let scheme = call_604058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604058.url(scheme.get, call_604058.host, call_604058.base,
                         call_604058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604058, url, valid)

proc call*(call_604059: Call_UpdateIntegration_604044; httpMethod: string;
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
  var path_604060 = newJObject()
  var body_604061 = newJObject()
  add(path_604060, "http_method", newJString(httpMethod))
  if body != nil:
    body_604061 = body
  add(path_604060, "restapi_id", newJString(restapiId))
  add(path_604060, "resource_id", newJString(resourceId))
  result = call_604059.call(path_604060, nil, nil, nil, body_604061)

var updateIntegration* = Call_UpdateIntegration_604044(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_604045, base: "/",
    url: url_UpdateIntegration_604046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_604028 = ref object of OpenApiRestCall_602450
proc url_DeleteIntegration_604030(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_604029(path: JsonNode; query: JsonNode;
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
  var valid_604031 = path.getOrDefault("http_method")
  valid_604031 = validateParameter(valid_604031, JString, required = true,
                                 default = nil)
  if valid_604031 != nil:
    section.add "http_method", valid_604031
  var valid_604032 = path.getOrDefault("restapi_id")
  valid_604032 = validateParameter(valid_604032, JString, required = true,
                                 default = nil)
  if valid_604032 != nil:
    section.add "restapi_id", valid_604032
  var valid_604033 = path.getOrDefault("resource_id")
  valid_604033 = validateParameter(valid_604033, JString, required = true,
                                 default = nil)
  if valid_604033 != nil:
    section.add "resource_id", valid_604033
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604034 = header.getOrDefault("X-Amz-Date")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Date", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Security-Token")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Security-Token", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Content-Sha256", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Algorithm")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Algorithm", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Signature")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Signature", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-SignedHeaders", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Credential")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Credential", valid_604040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604041: Call_DeleteIntegration_604028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_604041.validator(path, query, header, formData, body)
  let scheme = call_604041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604041.url(scheme.get, call_604041.host, call_604041.base,
                         call_604041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604041, url, valid)

proc call*(call_604042: Call_DeleteIntegration_604028; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_604043 = newJObject()
  add(path_604043, "http_method", newJString(httpMethod))
  add(path_604043, "restapi_id", newJString(restapiId))
  add(path_604043, "resource_id", newJString(resourceId))
  result = call_604042.call(path_604043, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_604028(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_604029, base: "/",
    url: url_DeleteIntegration_604030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_604079 = ref object of OpenApiRestCall_602450
proc url_PutIntegrationResponse_604081(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegrationResponse_604080(path: JsonNode; query: JsonNode;
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
  var valid_604082 = path.getOrDefault("http_method")
  valid_604082 = validateParameter(valid_604082, JString, required = true,
                                 default = nil)
  if valid_604082 != nil:
    section.add "http_method", valid_604082
  var valid_604083 = path.getOrDefault("status_code")
  valid_604083 = validateParameter(valid_604083, JString, required = true,
                                 default = nil)
  if valid_604083 != nil:
    section.add "status_code", valid_604083
  var valid_604084 = path.getOrDefault("restapi_id")
  valid_604084 = validateParameter(valid_604084, JString, required = true,
                                 default = nil)
  if valid_604084 != nil:
    section.add "restapi_id", valid_604084
  var valid_604085 = path.getOrDefault("resource_id")
  valid_604085 = validateParameter(valid_604085, JString, required = true,
                                 default = nil)
  if valid_604085 != nil:
    section.add "resource_id", valid_604085
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604086 = header.getOrDefault("X-Amz-Date")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Date", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Security-Token")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Security-Token", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Content-Sha256", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Algorithm")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Algorithm", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Signature")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Signature", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-SignedHeaders", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Credential")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Credential", valid_604092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604094: Call_PutIntegrationResponse_604079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_604094.validator(path, query, header, formData, body)
  let scheme = call_604094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604094.url(scheme.get, call_604094.host, call_604094.base,
                         call_604094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604094, url, valid)

proc call*(call_604095: Call_PutIntegrationResponse_604079; httpMethod: string;
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
  var path_604096 = newJObject()
  var body_604097 = newJObject()
  add(path_604096, "http_method", newJString(httpMethod))
  add(path_604096, "status_code", newJString(statusCode))
  if body != nil:
    body_604097 = body
  add(path_604096, "restapi_id", newJString(restapiId))
  add(path_604096, "resource_id", newJString(resourceId))
  result = call_604095.call(path_604096, nil, nil, nil, body_604097)

var putIntegrationResponse* = Call_PutIntegrationResponse_604079(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_604080, base: "/",
    url: url_PutIntegrationResponse_604081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_604062 = ref object of OpenApiRestCall_602450
proc url_GetIntegrationResponse_604064(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_604063(path: JsonNode; query: JsonNode;
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
  var valid_604065 = path.getOrDefault("http_method")
  valid_604065 = validateParameter(valid_604065, JString, required = true,
                                 default = nil)
  if valid_604065 != nil:
    section.add "http_method", valid_604065
  var valid_604066 = path.getOrDefault("status_code")
  valid_604066 = validateParameter(valid_604066, JString, required = true,
                                 default = nil)
  if valid_604066 != nil:
    section.add "status_code", valid_604066
  var valid_604067 = path.getOrDefault("restapi_id")
  valid_604067 = validateParameter(valid_604067, JString, required = true,
                                 default = nil)
  if valid_604067 != nil:
    section.add "restapi_id", valid_604067
  var valid_604068 = path.getOrDefault("resource_id")
  valid_604068 = validateParameter(valid_604068, JString, required = true,
                                 default = nil)
  if valid_604068 != nil:
    section.add "resource_id", valid_604068
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604069 = header.getOrDefault("X-Amz-Date")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Date", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Security-Token")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Security-Token", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Content-Sha256", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Algorithm")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Algorithm", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Signature")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Signature", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-SignedHeaders", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Credential")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Credential", valid_604075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604076: Call_GetIntegrationResponse_604062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_604076.validator(path, query, header, formData, body)
  let scheme = call_604076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604076.url(scheme.get, call_604076.host, call_604076.base,
                         call_604076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604076, url, valid)

proc call*(call_604077: Call_GetIntegrationResponse_604062; httpMethod: string;
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
  var path_604078 = newJObject()
  add(path_604078, "http_method", newJString(httpMethod))
  add(path_604078, "status_code", newJString(statusCode))
  add(path_604078, "restapi_id", newJString(restapiId))
  add(path_604078, "resource_id", newJString(resourceId))
  result = call_604077.call(path_604078, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_604062(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_604063, base: "/",
    url: url_GetIntegrationResponse_604064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_604115 = ref object of OpenApiRestCall_602450
proc url_UpdateIntegrationResponse_604117(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_604116(path: JsonNode; query: JsonNode;
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
  var valid_604118 = path.getOrDefault("http_method")
  valid_604118 = validateParameter(valid_604118, JString, required = true,
                                 default = nil)
  if valid_604118 != nil:
    section.add "http_method", valid_604118
  var valid_604119 = path.getOrDefault("status_code")
  valid_604119 = validateParameter(valid_604119, JString, required = true,
                                 default = nil)
  if valid_604119 != nil:
    section.add "status_code", valid_604119
  var valid_604120 = path.getOrDefault("restapi_id")
  valid_604120 = validateParameter(valid_604120, JString, required = true,
                                 default = nil)
  if valid_604120 != nil:
    section.add "restapi_id", valid_604120
  var valid_604121 = path.getOrDefault("resource_id")
  valid_604121 = validateParameter(valid_604121, JString, required = true,
                                 default = nil)
  if valid_604121 != nil:
    section.add "resource_id", valid_604121
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604122 = header.getOrDefault("X-Amz-Date")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Date", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Security-Token")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Security-Token", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Content-Sha256", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Algorithm")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Algorithm", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Signature")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Signature", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-SignedHeaders", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Credential")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Credential", valid_604128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604130: Call_UpdateIntegrationResponse_604115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_604130.validator(path, query, header, formData, body)
  let scheme = call_604130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604130.url(scheme.get, call_604130.host, call_604130.base,
                         call_604130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604130, url, valid)

proc call*(call_604131: Call_UpdateIntegrationResponse_604115; httpMethod: string;
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
  var path_604132 = newJObject()
  var body_604133 = newJObject()
  add(path_604132, "http_method", newJString(httpMethod))
  add(path_604132, "status_code", newJString(statusCode))
  if body != nil:
    body_604133 = body
  add(path_604132, "restapi_id", newJString(restapiId))
  add(path_604132, "resource_id", newJString(resourceId))
  result = call_604131.call(path_604132, nil, nil, nil, body_604133)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_604115(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_604116, base: "/",
    url: url_UpdateIntegrationResponse_604117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_604098 = ref object of OpenApiRestCall_602450
proc url_DeleteIntegrationResponse_604100(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_604099(path: JsonNode; query: JsonNode;
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
  var valid_604101 = path.getOrDefault("http_method")
  valid_604101 = validateParameter(valid_604101, JString, required = true,
                                 default = nil)
  if valid_604101 != nil:
    section.add "http_method", valid_604101
  var valid_604102 = path.getOrDefault("status_code")
  valid_604102 = validateParameter(valid_604102, JString, required = true,
                                 default = nil)
  if valid_604102 != nil:
    section.add "status_code", valid_604102
  var valid_604103 = path.getOrDefault("restapi_id")
  valid_604103 = validateParameter(valid_604103, JString, required = true,
                                 default = nil)
  if valid_604103 != nil:
    section.add "restapi_id", valid_604103
  var valid_604104 = path.getOrDefault("resource_id")
  valid_604104 = validateParameter(valid_604104, JString, required = true,
                                 default = nil)
  if valid_604104 != nil:
    section.add "resource_id", valid_604104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604105 = header.getOrDefault("X-Amz-Date")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Date", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Security-Token")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Security-Token", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Content-Sha256", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Algorithm")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Algorithm", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Signature")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Signature", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-SignedHeaders", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Credential")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Credential", valid_604111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604112: Call_DeleteIntegrationResponse_604098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_604112.validator(path, query, header, formData, body)
  let scheme = call_604112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604112.url(scheme.get, call_604112.host, call_604112.base,
                         call_604112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604112, url, valid)

proc call*(call_604113: Call_DeleteIntegrationResponse_604098; httpMethod: string;
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
  var path_604114 = newJObject()
  add(path_604114, "http_method", newJString(httpMethod))
  add(path_604114, "status_code", newJString(statusCode))
  add(path_604114, "restapi_id", newJString(restapiId))
  add(path_604114, "resource_id", newJString(resourceId))
  result = call_604113.call(path_604114, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_604098(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_604099, base: "/",
    url: url_DeleteIntegrationResponse_604100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_604150 = ref object of OpenApiRestCall_602450
proc url_PutMethod_604152(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutMethod_604151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604153 = path.getOrDefault("http_method")
  valid_604153 = validateParameter(valid_604153, JString, required = true,
                                 default = nil)
  if valid_604153 != nil:
    section.add "http_method", valid_604153
  var valid_604154 = path.getOrDefault("restapi_id")
  valid_604154 = validateParameter(valid_604154, JString, required = true,
                                 default = nil)
  if valid_604154 != nil:
    section.add "restapi_id", valid_604154
  var valid_604155 = path.getOrDefault("resource_id")
  valid_604155 = validateParameter(valid_604155, JString, required = true,
                                 default = nil)
  if valid_604155 != nil:
    section.add "resource_id", valid_604155
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604156 = header.getOrDefault("X-Amz-Date")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Date", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Security-Token")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Security-Token", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Content-Sha256", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Algorithm")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Algorithm", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Signature")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Signature", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-SignedHeaders", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Credential")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Credential", valid_604162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604164: Call_PutMethod_604150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_604164.validator(path, query, header, formData, body)
  let scheme = call_604164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604164.url(scheme.get, call_604164.host, call_604164.base,
                         call_604164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604164, url, valid)

proc call*(call_604165: Call_PutMethod_604150; httpMethod: string; body: JsonNode;
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
  var path_604166 = newJObject()
  var body_604167 = newJObject()
  add(path_604166, "http_method", newJString(httpMethod))
  if body != nil:
    body_604167 = body
  add(path_604166, "restapi_id", newJString(restapiId))
  add(path_604166, "resource_id", newJString(resourceId))
  result = call_604165.call(path_604166, nil, nil, nil, body_604167)

var putMethod* = Call_PutMethod_604150(name: "putMethod", meth: HttpMethod.HttpPut,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_PutMethod_604151,
                                    base: "/", url: url_PutMethod_604152,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_604168 = ref object of OpenApiRestCall_602450
proc url_TestInvokeMethod_604170(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_604169(path: JsonNode; query: JsonNode;
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
  var valid_604171 = path.getOrDefault("http_method")
  valid_604171 = validateParameter(valid_604171, JString, required = true,
                                 default = nil)
  if valid_604171 != nil:
    section.add "http_method", valid_604171
  var valid_604172 = path.getOrDefault("restapi_id")
  valid_604172 = validateParameter(valid_604172, JString, required = true,
                                 default = nil)
  if valid_604172 != nil:
    section.add "restapi_id", valid_604172
  var valid_604173 = path.getOrDefault("resource_id")
  valid_604173 = validateParameter(valid_604173, JString, required = true,
                                 default = nil)
  if valid_604173 != nil:
    section.add "resource_id", valid_604173
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604174 = header.getOrDefault("X-Amz-Date")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Date", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Security-Token")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Security-Token", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Content-Sha256", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Algorithm")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Algorithm", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Signature")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Signature", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-SignedHeaders", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Credential")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Credential", valid_604180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604182: Call_TestInvokeMethod_604168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_604182.validator(path, query, header, formData, body)
  let scheme = call_604182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604182.url(scheme.get, call_604182.host, call_604182.base,
                         call_604182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604182, url, valid)

proc call*(call_604183: Call_TestInvokeMethod_604168; httpMethod: string;
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
  var path_604184 = newJObject()
  var body_604185 = newJObject()
  add(path_604184, "http_method", newJString(httpMethod))
  if body != nil:
    body_604185 = body
  add(path_604184, "restapi_id", newJString(restapiId))
  add(path_604184, "resource_id", newJString(resourceId))
  result = call_604183.call(path_604184, nil, nil, nil, body_604185)

var testInvokeMethod* = Call_TestInvokeMethod_604168(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_604169, base: "/",
    url: url_TestInvokeMethod_604170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_604134 = ref object of OpenApiRestCall_602450
proc url_GetMethod_604136(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMethod_604135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604137 = path.getOrDefault("http_method")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = nil)
  if valid_604137 != nil:
    section.add "http_method", valid_604137
  var valid_604138 = path.getOrDefault("restapi_id")
  valid_604138 = validateParameter(valid_604138, JString, required = true,
                                 default = nil)
  if valid_604138 != nil:
    section.add "restapi_id", valid_604138
  var valid_604139 = path.getOrDefault("resource_id")
  valid_604139 = validateParameter(valid_604139, JString, required = true,
                                 default = nil)
  if valid_604139 != nil:
    section.add "resource_id", valid_604139
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604140 = header.getOrDefault("X-Amz-Date")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Date", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-Security-Token")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Security-Token", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Content-Sha256", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Algorithm")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Algorithm", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Signature")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Signature", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-SignedHeaders", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Credential")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Credential", valid_604146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604147: Call_GetMethod_604134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_604147.validator(path, query, header, formData, body)
  let scheme = call_604147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604147.url(scheme.get, call_604147.host, call_604147.base,
                         call_604147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604147, url, valid)

proc call*(call_604148: Call_GetMethod_604134; httpMethod: string; restapiId: string;
          resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_604149 = newJObject()
  add(path_604149, "http_method", newJString(httpMethod))
  add(path_604149, "restapi_id", newJString(restapiId))
  add(path_604149, "resource_id", newJString(resourceId))
  result = call_604148.call(path_604149, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_604134(name: "getMethod", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                    validator: validate_GetMethod_604135,
                                    base: "/", url: url_GetMethod_604136,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_604202 = ref object of OpenApiRestCall_602450
proc url_UpdateMethod_604204(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_604203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604205 = path.getOrDefault("http_method")
  valid_604205 = validateParameter(valid_604205, JString, required = true,
                                 default = nil)
  if valid_604205 != nil:
    section.add "http_method", valid_604205
  var valid_604206 = path.getOrDefault("restapi_id")
  valid_604206 = validateParameter(valid_604206, JString, required = true,
                                 default = nil)
  if valid_604206 != nil:
    section.add "restapi_id", valid_604206
  var valid_604207 = path.getOrDefault("resource_id")
  valid_604207 = validateParameter(valid_604207, JString, required = true,
                                 default = nil)
  if valid_604207 != nil:
    section.add "resource_id", valid_604207
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604208 = header.getOrDefault("X-Amz-Date")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Date", valid_604208
  var valid_604209 = header.getOrDefault("X-Amz-Security-Token")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Security-Token", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Content-Sha256", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Algorithm")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Algorithm", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Signature")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Signature", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-SignedHeaders", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Credential")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Credential", valid_604214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604216: Call_UpdateMethod_604202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_604216.validator(path, query, header, formData, body)
  let scheme = call_604216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604216.url(scheme.get, call_604216.host, call_604216.base,
                         call_604216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604216, url, valid)

proc call*(call_604217: Call_UpdateMethod_604202; httpMethod: string; body: JsonNode;
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
  var path_604218 = newJObject()
  var body_604219 = newJObject()
  add(path_604218, "http_method", newJString(httpMethod))
  if body != nil:
    body_604219 = body
  add(path_604218, "restapi_id", newJString(restapiId))
  add(path_604218, "resource_id", newJString(resourceId))
  result = call_604217.call(path_604218, nil, nil, nil, body_604219)

var updateMethod* = Call_UpdateMethod_604202(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_604203, base: "/", url: url_UpdateMethod_604204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_604186 = ref object of OpenApiRestCall_602450
proc url_DeleteMethod_604188(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_604187(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604189 = path.getOrDefault("http_method")
  valid_604189 = validateParameter(valid_604189, JString, required = true,
                                 default = nil)
  if valid_604189 != nil:
    section.add "http_method", valid_604189
  var valid_604190 = path.getOrDefault("restapi_id")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = nil)
  if valid_604190 != nil:
    section.add "restapi_id", valid_604190
  var valid_604191 = path.getOrDefault("resource_id")
  valid_604191 = validateParameter(valid_604191, JString, required = true,
                                 default = nil)
  if valid_604191 != nil:
    section.add "resource_id", valid_604191
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604192 = header.getOrDefault("X-Amz-Date")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Date", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Security-Token")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Security-Token", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Content-Sha256", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Algorithm")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Algorithm", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Signature")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Signature", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-SignedHeaders", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Credential")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Credential", valid_604198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604199: Call_DeleteMethod_604186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_604199.validator(path, query, header, formData, body)
  let scheme = call_604199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604199.url(scheme.get, call_604199.host, call_604199.base,
                         call_604199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604199, url, valid)

proc call*(call_604200: Call_DeleteMethod_604186; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_604201 = newJObject()
  add(path_604201, "http_method", newJString(httpMethod))
  add(path_604201, "restapi_id", newJString(restapiId))
  add(path_604201, "resource_id", newJString(resourceId))
  result = call_604200.call(path_604201, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_604186(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_604187, base: "/", url: url_DeleteMethod_604188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_604237 = ref object of OpenApiRestCall_602450
proc url_PutMethodResponse_604239(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_604238(path: JsonNode; query: JsonNode;
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
  var valid_604240 = path.getOrDefault("http_method")
  valid_604240 = validateParameter(valid_604240, JString, required = true,
                                 default = nil)
  if valid_604240 != nil:
    section.add "http_method", valid_604240
  var valid_604241 = path.getOrDefault("status_code")
  valid_604241 = validateParameter(valid_604241, JString, required = true,
                                 default = nil)
  if valid_604241 != nil:
    section.add "status_code", valid_604241
  var valid_604242 = path.getOrDefault("restapi_id")
  valid_604242 = validateParameter(valid_604242, JString, required = true,
                                 default = nil)
  if valid_604242 != nil:
    section.add "restapi_id", valid_604242
  var valid_604243 = path.getOrDefault("resource_id")
  valid_604243 = validateParameter(valid_604243, JString, required = true,
                                 default = nil)
  if valid_604243 != nil:
    section.add "resource_id", valid_604243
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604244 = header.getOrDefault("X-Amz-Date")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Date", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Security-Token")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Security-Token", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Content-Sha256", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Algorithm")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Algorithm", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Signature")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Signature", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-SignedHeaders", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Credential")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Credential", valid_604250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604252: Call_PutMethodResponse_604237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_604252.validator(path, query, header, formData, body)
  let scheme = call_604252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604252.url(scheme.get, call_604252.host, call_604252.base,
                         call_604252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604252, url, valid)

proc call*(call_604253: Call_PutMethodResponse_604237; httpMethod: string;
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
  var path_604254 = newJObject()
  var body_604255 = newJObject()
  add(path_604254, "http_method", newJString(httpMethod))
  add(path_604254, "status_code", newJString(statusCode))
  if body != nil:
    body_604255 = body
  add(path_604254, "restapi_id", newJString(restapiId))
  add(path_604254, "resource_id", newJString(resourceId))
  result = call_604253.call(path_604254, nil, nil, nil, body_604255)

var putMethodResponse* = Call_PutMethodResponse_604237(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_604238, base: "/",
    url: url_PutMethodResponse_604239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_604220 = ref object of OpenApiRestCall_602450
proc url_GetMethodResponse_604222(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_604221(path: JsonNode; query: JsonNode;
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
  var valid_604223 = path.getOrDefault("http_method")
  valid_604223 = validateParameter(valid_604223, JString, required = true,
                                 default = nil)
  if valid_604223 != nil:
    section.add "http_method", valid_604223
  var valid_604224 = path.getOrDefault("status_code")
  valid_604224 = validateParameter(valid_604224, JString, required = true,
                                 default = nil)
  if valid_604224 != nil:
    section.add "status_code", valid_604224
  var valid_604225 = path.getOrDefault("restapi_id")
  valid_604225 = validateParameter(valid_604225, JString, required = true,
                                 default = nil)
  if valid_604225 != nil:
    section.add "restapi_id", valid_604225
  var valid_604226 = path.getOrDefault("resource_id")
  valid_604226 = validateParameter(valid_604226, JString, required = true,
                                 default = nil)
  if valid_604226 != nil:
    section.add "resource_id", valid_604226
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604227 = header.getOrDefault("X-Amz-Date")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Date", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Security-Token")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Security-Token", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Content-Sha256", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Algorithm")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Algorithm", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Signature")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Signature", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-SignedHeaders", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Credential")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Credential", valid_604233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604234: Call_GetMethodResponse_604220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_604234.validator(path, query, header, formData, body)
  let scheme = call_604234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604234.url(scheme.get, call_604234.host, call_604234.base,
                         call_604234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604234, url, valid)

proc call*(call_604235: Call_GetMethodResponse_604220; httpMethod: string;
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
  var path_604236 = newJObject()
  add(path_604236, "http_method", newJString(httpMethod))
  add(path_604236, "status_code", newJString(statusCode))
  add(path_604236, "restapi_id", newJString(restapiId))
  add(path_604236, "resource_id", newJString(resourceId))
  result = call_604235.call(path_604236, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_604220(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_604221, base: "/",
    url: url_GetMethodResponse_604222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_604273 = ref object of OpenApiRestCall_602450
proc url_UpdateMethodResponse_604275(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_604274(path: JsonNode; query: JsonNode;
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
  var valid_604276 = path.getOrDefault("http_method")
  valid_604276 = validateParameter(valid_604276, JString, required = true,
                                 default = nil)
  if valid_604276 != nil:
    section.add "http_method", valid_604276
  var valid_604277 = path.getOrDefault("status_code")
  valid_604277 = validateParameter(valid_604277, JString, required = true,
                                 default = nil)
  if valid_604277 != nil:
    section.add "status_code", valid_604277
  var valid_604278 = path.getOrDefault("restapi_id")
  valid_604278 = validateParameter(valid_604278, JString, required = true,
                                 default = nil)
  if valid_604278 != nil:
    section.add "restapi_id", valid_604278
  var valid_604279 = path.getOrDefault("resource_id")
  valid_604279 = validateParameter(valid_604279, JString, required = true,
                                 default = nil)
  if valid_604279 != nil:
    section.add "resource_id", valid_604279
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604280 = header.getOrDefault("X-Amz-Date")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Date", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Security-Token")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Security-Token", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Content-Sha256", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Algorithm")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Algorithm", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Signature")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Signature", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-SignedHeaders", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Credential")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Credential", valid_604286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604288: Call_UpdateMethodResponse_604273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_604288.validator(path, query, header, formData, body)
  let scheme = call_604288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604288.url(scheme.get, call_604288.host, call_604288.base,
                         call_604288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604288, url, valid)

proc call*(call_604289: Call_UpdateMethodResponse_604273; httpMethod: string;
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
  var path_604290 = newJObject()
  var body_604291 = newJObject()
  add(path_604290, "http_method", newJString(httpMethod))
  add(path_604290, "status_code", newJString(statusCode))
  if body != nil:
    body_604291 = body
  add(path_604290, "restapi_id", newJString(restapiId))
  add(path_604290, "resource_id", newJString(resourceId))
  result = call_604289.call(path_604290, nil, nil, nil, body_604291)

var updateMethodResponse* = Call_UpdateMethodResponse_604273(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_604274, base: "/",
    url: url_UpdateMethodResponse_604275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_604256 = ref object of OpenApiRestCall_602450
proc url_DeleteMethodResponse_604258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_604257(path: JsonNode; query: JsonNode;
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
  var valid_604259 = path.getOrDefault("http_method")
  valid_604259 = validateParameter(valid_604259, JString, required = true,
                                 default = nil)
  if valid_604259 != nil:
    section.add "http_method", valid_604259
  var valid_604260 = path.getOrDefault("status_code")
  valid_604260 = validateParameter(valid_604260, JString, required = true,
                                 default = nil)
  if valid_604260 != nil:
    section.add "status_code", valid_604260
  var valid_604261 = path.getOrDefault("restapi_id")
  valid_604261 = validateParameter(valid_604261, JString, required = true,
                                 default = nil)
  if valid_604261 != nil:
    section.add "restapi_id", valid_604261
  var valid_604262 = path.getOrDefault("resource_id")
  valid_604262 = validateParameter(valid_604262, JString, required = true,
                                 default = nil)
  if valid_604262 != nil:
    section.add "resource_id", valid_604262
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604263 = header.getOrDefault("X-Amz-Date")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Date", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Security-Token")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Security-Token", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Content-Sha256", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Algorithm")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Algorithm", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Signature")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Signature", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-SignedHeaders", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Credential")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Credential", valid_604269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604270: Call_DeleteMethodResponse_604256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_604270.validator(path, query, header, formData, body)
  let scheme = call_604270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604270.url(scheme.get, call_604270.host, call_604270.base,
                         call_604270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604270, url, valid)

proc call*(call_604271: Call_DeleteMethodResponse_604256; httpMethod: string;
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
  var path_604272 = newJObject()
  add(path_604272, "http_method", newJString(httpMethod))
  add(path_604272, "status_code", newJString(statusCode))
  add(path_604272, "restapi_id", newJString(restapiId))
  add(path_604272, "resource_id", newJString(resourceId))
  result = call_604271.call(path_604272, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_604256(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_604257, base: "/",
    url: url_DeleteMethodResponse_604258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_604292 = ref object of OpenApiRestCall_602450
proc url_GetModel_604294(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_604293(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604295 = path.getOrDefault("model_name")
  valid_604295 = validateParameter(valid_604295, JString, required = true,
                                 default = nil)
  if valid_604295 != nil:
    section.add "model_name", valid_604295
  var valid_604296 = path.getOrDefault("restapi_id")
  valid_604296 = validateParameter(valid_604296, JString, required = true,
                                 default = nil)
  if valid_604296 != nil:
    section.add "restapi_id", valid_604296
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_604297 = query.getOrDefault("flatten")
  valid_604297 = validateParameter(valid_604297, JBool, required = false, default = nil)
  if valid_604297 != nil:
    section.add "flatten", valid_604297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604298 = header.getOrDefault("X-Amz-Date")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Date", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Security-Token")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Security-Token", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Content-Sha256", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Algorithm")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Algorithm", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Signature")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Signature", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-SignedHeaders", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Credential")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Credential", valid_604304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604305: Call_GetModel_604292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_604305.validator(path, query, header, formData, body)
  let scheme = call_604305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604305.url(scheme.get, call_604305.host, call_604305.base,
                         call_604305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604305, url, valid)

proc call*(call_604306: Call_GetModel_604292; modelName: string; restapiId: string;
          flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_604307 = newJObject()
  var query_604308 = newJObject()
  add(query_604308, "flatten", newJBool(flatten))
  add(path_604307, "model_name", newJString(modelName))
  add(path_604307, "restapi_id", newJString(restapiId))
  result = call_604306.call(path_604307, query_604308, nil, nil, nil)

var getModel* = Call_GetModel_604292(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                  validator: validate_GetModel_604293, base: "/",
                                  url: url_GetModel_604294,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_604324 = ref object of OpenApiRestCall_602450
proc url_UpdateModel_604326(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_604325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604327 = path.getOrDefault("model_name")
  valid_604327 = validateParameter(valid_604327, JString, required = true,
                                 default = nil)
  if valid_604327 != nil:
    section.add "model_name", valid_604327
  var valid_604328 = path.getOrDefault("restapi_id")
  valid_604328 = validateParameter(valid_604328, JString, required = true,
                                 default = nil)
  if valid_604328 != nil:
    section.add "restapi_id", valid_604328
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604329 = header.getOrDefault("X-Amz-Date")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Date", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Security-Token")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Security-Token", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Content-Sha256", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Algorithm")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Algorithm", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Signature")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Signature", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-SignedHeaders", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Credential")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Credential", valid_604335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604337: Call_UpdateModel_604324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_604337.validator(path, query, header, formData, body)
  let scheme = call_604337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604337.url(scheme.get, call_604337.host, call_604337.base,
                         call_604337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604337, url, valid)

proc call*(call_604338: Call_UpdateModel_604324; modelName: string; body: JsonNode;
          restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604339 = newJObject()
  var body_604340 = newJObject()
  add(path_604339, "model_name", newJString(modelName))
  if body != nil:
    body_604340 = body
  add(path_604339, "restapi_id", newJString(restapiId))
  result = call_604338.call(path_604339, nil, nil, nil, body_604340)

var updateModel* = Call_UpdateModel_604324(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_UpdateModel_604325,
                                        base: "/", url: url_UpdateModel_604326,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_604309 = ref object of OpenApiRestCall_602450
proc url_DeleteModel_604311(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_604310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604312 = path.getOrDefault("model_name")
  valid_604312 = validateParameter(valid_604312, JString, required = true,
                                 default = nil)
  if valid_604312 != nil:
    section.add "model_name", valid_604312
  var valid_604313 = path.getOrDefault("restapi_id")
  valid_604313 = validateParameter(valid_604313, JString, required = true,
                                 default = nil)
  if valid_604313 != nil:
    section.add "restapi_id", valid_604313
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604314 = header.getOrDefault("X-Amz-Date")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Date", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Security-Token")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Security-Token", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Content-Sha256", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Algorithm")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Algorithm", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Signature")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Signature", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-SignedHeaders", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Credential")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Credential", valid_604320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604321: Call_DeleteModel_604309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_604321.validator(path, query, header, formData, body)
  let scheme = call_604321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604321.url(scheme.get, call_604321.host, call_604321.base,
                         call_604321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604321, url, valid)

proc call*(call_604322: Call_DeleteModel_604309; modelName: string; restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604323 = newJObject()
  add(path_604323, "model_name", newJString(modelName))
  add(path_604323, "restapi_id", newJString(restapiId))
  result = call_604322.call(path_604323, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_604309(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                        validator: validate_DeleteModel_604310,
                                        base: "/", url: url_DeleteModel_604311,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_604341 = ref object of OpenApiRestCall_602450
proc url_GetRequestValidator_604343(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_604342(path: JsonNode; query: JsonNode;
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
  var valid_604344 = path.getOrDefault("requestvalidator_id")
  valid_604344 = validateParameter(valid_604344, JString, required = true,
                                 default = nil)
  if valid_604344 != nil:
    section.add "requestvalidator_id", valid_604344
  var valid_604345 = path.getOrDefault("restapi_id")
  valid_604345 = validateParameter(valid_604345, JString, required = true,
                                 default = nil)
  if valid_604345 != nil:
    section.add "restapi_id", valid_604345
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604346 = header.getOrDefault("X-Amz-Date")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Date", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Security-Token")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Security-Token", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Content-Sha256", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Algorithm")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Algorithm", valid_604349
  var valid_604350 = header.getOrDefault("X-Amz-Signature")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Signature", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-SignedHeaders", valid_604351
  var valid_604352 = header.getOrDefault("X-Amz-Credential")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Credential", valid_604352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604353: Call_GetRequestValidator_604341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604353.validator(path, query, header, formData, body)
  let scheme = call_604353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604353.url(scheme.get, call_604353.host, call_604353.base,
                         call_604353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604353, url, valid)

proc call*(call_604354: Call_GetRequestValidator_604341;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604355 = newJObject()
  add(path_604355, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_604355, "restapi_id", newJString(restapiId))
  result = call_604354.call(path_604355, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_604341(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_604342, base: "/",
    url: url_GetRequestValidator_604343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_604371 = ref object of OpenApiRestCall_602450
proc url_UpdateRequestValidator_604373(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRequestValidator_604372(path: JsonNode; query: JsonNode;
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
  var valid_604374 = path.getOrDefault("requestvalidator_id")
  valid_604374 = validateParameter(valid_604374, JString, required = true,
                                 default = nil)
  if valid_604374 != nil:
    section.add "requestvalidator_id", valid_604374
  var valid_604375 = path.getOrDefault("restapi_id")
  valid_604375 = validateParameter(valid_604375, JString, required = true,
                                 default = nil)
  if valid_604375 != nil:
    section.add "restapi_id", valid_604375
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604376 = header.getOrDefault("X-Amz-Date")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Date", valid_604376
  var valid_604377 = header.getOrDefault("X-Amz-Security-Token")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-Security-Token", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Content-Sha256", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Algorithm")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Algorithm", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Signature")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Signature", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-SignedHeaders", valid_604381
  var valid_604382 = header.getOrDefault("X-Amz-Credential")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-Credential", valid_604382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604384: Call_UpdateRequestValidator_604371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604384.validator(path, query, header, formData, body)
  let scheme = call_604384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604384.url(scheme.get, call_604384.host, call_604384.base,
                         call_604384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604384, url, valid)

proc call*(call_604385: Call_UpdateRequestValidator_604371;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604386 = newJObject()
  var body_604387 = newJObject()
  add(path_604386, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_604387 = body
  add(path_604386, "restapi_id", newJString(restapiId))
  result = call_604385.call(path_604386, nil, nil, nil, body_604387)

var updateRequestValidator* = Call_UpdateRequestValidator_604371(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_604372, base: "/",
    url: url_UpdateRequestValidator_604373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_604356 = ref object of OpenApiRestCall_602450
proc url_DeleteRequestValidator_604358(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRequestValidator_604357(path: JsonNode; query: JsonNode;
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
  var valid_604359 = path.getOrDefault("requestvalidator_id")
  valid_604359 = validateParameter(valid_604359, JString, required = true,
                                 default = nil)
  if valid_604359 != nil:
    section.add "requestvalidator_id", valid_604359
  var valid_604360 = path.getOrDefault("restapi_id")
  valid_604360 = validateParameter(valid_604360, JString, required = true,
                                 default = nil)
  if valid_604360 != nil:
    section.add "restapi_id", valid_604360
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_604368: Call_DeleteRequestValidator_604356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_604368.validator(path, query, header, formData, body)
  let scheme = call_604368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604368.url(scheme.get, call_604368.host, call_604368.base,
                         call_604368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604368, url, valid)

proc call*(call_604369: Call_DeleteRequestValidator_604356;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604370 = newJObject()
  add(path_604370, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_604370, "restapi_id", newJString(restapiId))
  result = call_604369.call(path_604370, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_604356(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_604357, base: "/",
    url: url_DeleteRequestValidator_604358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_604388 = ref object of OpenApiRestCall_602450
proc url_GetResource_604390(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_604389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604391 = path.getOrDefault("restapi_id")
  valid_604391 = validateParameter(valid_604391, JString, required = true,
                                 default = nil)
  if valid_604391 != nil:
    section.add "restapi_id", valid_604391
  var valid_604392 = path.getOrDefault("resource_id")
  valid_604392 = validateParameter(valid_604392, JString, required = true,
                                 default = nil)
  if valid_604392 != nil:
    section.add "resource_id", valid_604392
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_604393 = query.getOrDefault("embed")
  valid_604393 = validateParameter(valid_604393, JArray, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "embed", valid_604393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604394 = header.getOrDefault("X-Amz-Date")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Date", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Security-Token")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Security-Token", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Content-Sha256", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Algorithm")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Algorithm", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Signature")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Signature", valid_604398
  var valid_604399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-SignedHeaders", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Credential")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Credential", valid_604400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604401: Call_GetResource_604388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_604401.validator(path, query, header, formData, body)
  let scheme = call_604401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604401.url(scheme.get, call_604401.host, call_604401.base,
                         call_604401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604401, url, valid)

proc call*(call_604402: Call_GetResource_604388; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_604403 = newJObject()
  var query_604404 = newJObject()
  if embed != nil:
    query_604404.add "embed", embed
  add(path_604403, "restapi_id", newJString(restapiId))
  add(path_604403, "resource_id", newJString(resourceId))
  result = call_604402.call(path_604403, query_604404, nil, nil, nil)

var getResource* = Call_GetResource_604388(name: "getResource",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}",
                                        validator: validate_GetResource_604389,
                                        base: "/", url: url_GetResource_604390,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_604420 = ref object of OpenApiRestCall_602450
proc url_UpdateResource_604422(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_604421(path: JsonNode; query: JsonNode;
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
  var valid_604423 = path.getOrDefault("restapi_id")
  valid_604423 = validateParameter(valid_604423, JString, required = true,
                                 default = nil)
  if valid_604423 != nil:
    section.add "restapi_id", valid_604423
  var valid_604424 = path.getOrDefault("resource_id")
  valid_604424 = validateParameter(valid_604424, JString, required = true,
                                 default = nil)
  if valid_604424 != nil:
    section.add "resource_id", valid_604424
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604425 = header.getOrDefault("X-Amz-Date")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Date", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Security-Token")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Security-Token", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Content-Sha256", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Algorithm")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Algorithm", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Signature")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Signature", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-SignedHeaders", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Credential")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Credential", valid_604431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604433: Call_UpdateResource_604420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_604433.validator(path, query, header, formData, body)
  let scheme = call_604433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604433.url(scheme.get, call_604433.host, call_604433.base,
                         call_604433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604433, url, valid)

proc call*(call_604434: Call_UpdateResource_604420; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_604435 = newJObject()
  var body_604436 = newJObject()
  if body != nil:
    body_604436 = body
  add(path_604435, "restapi_id", newJString(restapiId))
  add(path_604435, "resource_id", newJString(resourceId))
  result = call_604434.call(path_604435, nil, nil, nil, body_604436)

var updateResource* = Call_UpdateResource_604420(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_604421, base: "/", url: url_UpdateResource_604422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_604405 = ref object of OpenApiRestCall_602450
proc url_DeleteResource_604407(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_604406(path: JsonNode; query: JsonNode;
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
  var valid_604408 = path.getOrDefault("restapi_id")
  valid_604408 = validateParameter(valid_604408, JString, required = true,
                                 default = nil)
  if valid_604408 != nil:
    section.add "restapi_id", valid_604408
  var valid_604409 = path.getOrDefault("resource_id")
  valid_604409 = validateParameter(valid_604409, JString, required = true,
                                 default = nil)
  if valid_604409 != nil:
    section.add "resource_id", valid_604409
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604410 = header.getOrDefault("X-Amz-Date")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Date", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Security-Token")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Security-Token", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Content-Sha256", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-Algorithm")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-Algorithm", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-Signature")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Signature", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-SignedHeaders", valid_604415
  var valid_604416 = header.getOrDefault("X-Amz-Credential")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-Credential", valid_604416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604417: Call_DeleteResource_604405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_604417.validator(path, query, header, formData, body)
  let scheme = call_604417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604417.url(scheme.get, call_604417.host, call_604417.base,
                         call_604417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604417, url, valid)

proc call*(call_604418: Call_DeleteResource_604405; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_604419 = newJObject()
  add(path_604419, "restapi_id", newJString(restapiId))
  add(path_604419, "resource_id", newJString(resourceId))
  result = call_604418.call(path_604419, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_604405(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_604406, base: "/", url: url_DeleteResource_604407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_604451 = ref object of OpenApiRestCall_602450
proc url_PutRestApi_604453(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutRestApi_604452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604454 = path.getOrDefault("restapi_id")
  valid_604454 = validateParameter(valid_604454, JString, required = true,
                                 default = nil)
  if valid_604454 != nil:
    section.add "restapi_id", valid_604454
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
  var valid_604455 = query.getOrDefault("parameters.0.value")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "parameters.0.value", valid_604455
  var valid_604456 = query.getOrDefault("parameters.2.value")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "parameters.2.value", valid_604456
  var valid_604457 = query.getOrDefault("parameters.1.key")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "parameters.1.key", valid_604457
  var valid_604458 = query.getOrDefault("mode")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = newJString("merge"))
  if valid_604458 != nil:
    section.add "mode", valid_604458
  var valid_604459 = query.getOrDefault("parameters.0.key")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "parameters.0.key", valid_604459
  var valid_604460 = query.getOrDefault("parameters.2.key")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "parameters.2.key", valid_604460
  var valid_604461 = query.getOrDefault("failonwarnings")
  valid_604461 = validateParameter(valid_604461, JBool, required = false, default = nil)
  if valid_604461 != nil:
    section.add "failonwarnings", valid_604461
  var valid_604462 = query.getOrDefault("parameters.1.value")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "parameters.1.value", valid_604462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604463 = header.getOrDefault("X-Amz-Date")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Date", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-Security-Token")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-Security-Token", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Content-Sha256", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Algorithm")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Algorithm", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Signature")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Signature", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-SignedHeaders", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Credential")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Credential", valid_604469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604471: Call_PutRestApi_604451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_604471.validator(path, query, header, formData, body)
  let scheme = call_604471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604471.url(scheme.get, call_604471.host, call_604471.base,
                         call_604471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604471, url, valid)

proc call*(call_604472: Call_PutRestApi_604451; body: JsonNode; restapiId: string;
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
  var path_604473 = newJObject()
  var query_604474 = newJObject()
  var body_604475 = newJObject()
  add(query_604474, "parameters.0.value", newJString(parameters0Value))
  add(query_604474, "parameters.2.value", newJString(parameters2Value))
  add(query_604474, "parameters.1.key", newJString(parameters1Key))
  add(query_604474, "mode", newJString(mode))
  add(query_604474, "parameters.0.key", newJString(parameters0Key))
  add(query_604474, "parameters.2.key", newJString(parameters2Key))
  add(query_604474, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604475 = body
  add(query_604474, "parameters.1.value", newJString(parameters1Value))
  add(path_604473, "restapi_id", newJString(restapiId))
  result = call_604472.call(path_604473, query_604474, nil, nil, body_604475)

var putRestApi* = Call_PutRestApi_604451(name: "putRestApi",
                                      meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_PutRestApi_604452,
                                      base: "/", url: url_PutRestApi_604453,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_604437 = ref object of OpenApiRestCall_602450
proc url_GetRestApi_604439(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRestApi_604438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604440 = path.getOrDefault("restapi_id")
  valid_604440 = validateParameter(valid_604440, JString, required = true,
                                 default = nil)
  if valid_604440 != nil:
    section.add "restapi_id", valid_604440
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604441 = header.getOrDefault("X-Amz-Date")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Date", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Security-Token")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Security-Token", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Content-Sha256", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Algorithm")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Algorithm", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Signature")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Signature", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-SignedHeaders", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Credential")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Credential", valid_604447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604448: Call_GetRestApi_604437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_604448.validator(path, query, header, formData, body)
  let scheme = call_604448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604448.url(scheme.get, call_604448.host, call_604448.base,
                         call_604448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604448, url, valid)

proc call*(call_604449: Call_GetRestApi_604437; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604450 = newJObject()
  add(path_604450, "restapi_id", newJString(restapiId))
  result = call_604449.call(path_604450, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_604437(name: "getRestApi",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}",
                                      validator: validate_GetRestApi_604438,
                                      base: "/", url: url_GetRestApi_604439,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_604490 = ref object of OpenApiRestCall_602450
proc url_UpdateRestApi_604492(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_604491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604493 = path.getOrDefault("restapi_id")
  valid_604493 = validateParameter(valid_604493, JString, required = true,
                                 default = nil)
  if valid_604493 != nil:
    section.add "restapi_id", valid_604493
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604494 = header.getOrDefault("X-Amz-Date")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-Date", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Security-Token")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Security-Token", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Content-Sha256", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Algorithm")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Algorithm", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Signature")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Signature", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-SignedHeaders", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Credential")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Credential", valid_604500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604502: Call_UpdateRestApi_604490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_604502.validator(path, query, header, formData, body)
  let scheme = call_604502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604502.url(scheme.get, call_604502.host, call_604502.base,
                         call_604502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604502, url, valid)

proc call*(call_604503: Call_UpdateRestApi_604490; body: JsonNode; restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604504 = newJObject()
  var body_604505 = newJObject()
  if body != nil:
    body_604505 = body
  add(path_604504, "restapi_id", newJString(restapiId))
  result = call_604503.call(path_604504, nil, nil, nil, body_604505)

var updateRestApi* = Call_UpdateRestApi_604490(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_604491,
    base: "/", url: url_UpdateRestApi_604492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_604476 = ref object of OpenApiRestCall_602450
proc url_DeleteRestApi_604478(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_604477(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604479 = path.getOrDefault("restapi_id")
  valid_604479 = validateParameter(valid_604479, JString, required = true,
                                 default = nil)
  if valid_604479 != nil:
    section.add "restapi_id", valid_604479
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604480 = header.getOrDefault("X-Amz-Date")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Date", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Security-Token")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Security-Token", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Content-Sha256", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Algorithm")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Algorithm", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Signature")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Signature", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-SignedHeaders", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-Credential")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-Credential", valid_604486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604487: Call_DeleteRestApi_604476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_604487.validator(path, query, header, formData, body)
  let scheme = call_604487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604487.url(scheme.get, call_604487.host, call_604487.base,
                         call_604487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604487, url, valid)

proc call*(call_604488: Call_DeleteRestApi_604476; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604489 = newJObject()
  add(path_604489, "restapi_id", newJString(restapiId))
  result = call_604488.call(path_604489, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_604476(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_604477,
    base: "/", url: url_DeleteRestApi_604478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_604506 = ref object of OpenApiRestCall_602450
proc url_GetStage_604508(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_604507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604509 = path.getOrDefault("stage_name")
  valid_604509 = validateParameter(valid_604509, JString, required = true,
                                 default = nil)
  if valid_604509 != nil:
    section.add "stage_name", valid_604509
  var valid_604510 = path.getOrDefault("restapi_id")
  valid_604510 = validateParameter(valid_604510, JString, required = true,
                                 default = nil)
  if valid_604510 != nil:
    section.add "restapi_id", valid_604510
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604511 = header.getOrDefault("X-Amz-Date")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Date", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-Security-Token")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-Security-Token", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Content-Sha256", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Algorithm")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Algorithm", valid_604514
  var valid_604515 = header.getOrDefault("X-Amz-Signature")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Signature", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-SignedHeaders", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Credential")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Credential", valid_604517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604518: Call_GetStage_604506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_604518.validator(path, query, header, formData, body)
  let scheme = call_604518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604518.url(scheme.get, call_604518.host, call_604518.base,
                         call_604518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604518, url, valid)

proc call*(call_604519: Call_GetStage_604506; stageName: string; restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604520 = newJObject()
  add(path_604520, "stage_name", newJString(stageName))
  add(path_604520, "restapi_id", newJString(restapiId))
  result = call_604519.call(path_604520, nil, nil, nil, nil)

var getStage* = Call_GetStage_604506(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                  validator: validate_GetStage_604507, base: "/",
                                  url: url_GetStage_604508,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_604536 = ref object of OpenApiRestCall_602450
proc url_UpdateStage_604538(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_604537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604539 = path.getOrDefault("stage_name")
  valid_604539 = validateParameter(valid_604539, JString, required = true,
                                 default = nil)
  if valid_604539 != nil:
    section.add "stage_name", valid_604539
  var valid_604540 = path.getOrDefault("restapi_id")
  valid_604540 = validateParameter(valid_604540, JString, required = true,
                                 default = nil)
  if valid_604540 != nil:
    section.add "restapi_id", valid_604540
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604541 = header.getOrDefault("X-Amz-Date")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Date", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Security-Token")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Security-Token", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Content-Sha256", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Algorithm")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Algorithm", valid_604544
  var valid_604545 = header.getOrDefault("X-Amz-Signature")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-Signature", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-SignedHeaders", valid_604546
  var valid_604547 = header.getOrDefault("X-Amz-Credential")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Credential", valid_604547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604549: Call_UpdateStage_604536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_604549.validator(path, query, header, formData, body)
  let scheme = call_604549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604549.url(scheme.get, call_604549.host, call_604549.base,
                         call_604549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604549, url, valid)

proc call*(call_604550: Call_UpdateStage_604536; body: JsonNode; stageName: string;
          restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604551 = newJObject()
  var body_604552 = newJObject()
  if body != nil:
    body_604552 = body
  add(path_604551, "stage_name", newJString(stageName))
  add(path_604551, "restapi_id", newJString(restapiId))
  result = call_604550.call(path_604551, nil, nil, nil, body_604552)

var updateStage* = Call_UpdateStage_604536(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_UpdateStage_604537,
                                        base: "/", url: url_UpdateStage_604538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_604521 = ref object of OpenApiRestCall_602450
proc url_DeleteStage_604523(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_604522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604524 = path.getOrDefault("stage_name")
  valid_604524 = validateParameter(valid_604524, JString, required = true,
                                 default = nil)
  if valid_604524 != nil:
    section.add "stage_name", valid_604524
  var valid_604525 = path.getOrDefault("restapi_id")
  valid_604525 = validateParameter(valid_604525, JString, required = true,
                                 default = nil)
  if valid_604525 != nil:
    section.add "restapi_id", valid_604525
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604526 = header.getOrDefault("X-Amz-Date")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Date", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Security-Token")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Security-Token", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Content-Sha256", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Algorithm")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Algorithm", valid_604529
  var valid_604530 = header.getOrDefault("X-Amz-Signature")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Signature", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-SignedHeaders", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Credential")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Credential", valid_604532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604533: Call_DeleteStage_604521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_604533.validator(path, query, header, formData, body)
  let scheme = call_604533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604533.url(scheme.get, call_604533.host, call_604533.base,
                         call_604533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604533, url, valid)

proc call*(call_604534: Call_DeleteStage_604521; stageName: string; restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604535 = newJObject()
  add(path_604535, "stage_name", newJString(stageName))
  add(path_604535, "restapi_id", newJString(restapiId))
  result = call_604534.call(path_604535, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_604521(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                        validator: validate_DeleteStage_604522,
                                        base: "/", url: url_DeleteStage_604523,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_604553 = ref object of OpenApiRestCall_602450
proc url_GetUsagePlan_604555(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_604554(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604556 = path.getOrDefault("usageplanId")
  valid_604556 = validateParameter(valid_604556, JString, required = true,
                                 default = nil)
  if valid_604556 != nil:
    section.add "usageplanId", valid_604556
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604557 = header.getOrDefault("X-Amz-Date")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Date", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Security-Token")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Security-Token", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Content-Sha256", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-Algorithm")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-Algorithm", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Signature")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Signature", valid_604561
  var valid_604562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "X-Amz-SignedHeaders", valid_604562
  var valid_604563 = header.getOrDefault("X-Amz-Credential")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Credential", valid_604563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604564: Call_GetUsagePlan_604553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_604564.validator(path, query, header, formData, body)
  let scheme = call_604564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604564.url(scheme.get, call_604564.host, call_604564.base,
                         call_604564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604564, url, valid)

proc call*(call_604565: Call_GetUsagePlan_604553; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_604566 = newJObject()
  add(path_604566, "usageplanId", newJString(usageplanId))
  result = call_604565.call(path_604566, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_604553(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_604554,
    base: "/", url: url_GetUsagePlan_604555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_604581 = ref object of OpenApiRestCall_602450
proc url_UpdateUsagePlan_604583(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_604582(path: JsonNode; query: JsonNode;
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
  var valid_604584 = path.getOrDefault("usageplanId")
  valid_604584 = validateParameter(valid_604584, JString, required = true,
                                 default = nil)
  if valid_604584 != nil:
    section.add "usageplanId", valid_604584
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604585 = header.getOrDefault("X-Amz-Date")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Date", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Security-Token")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Security-Token", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Content-Sha256", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Algorithm")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Algorithm", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Signature")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Signature", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-SignedHeaders", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-Credential")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-Credential", valid_604591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604593: Call_UpdateUsagePlan_604581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_604593.validator(path, query, header, formData, body)
  let scheme = call_604593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604593.url(scheme.get, call_604593.host, call_604593.base,
                         call_604593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604593, url, valid)

proc call*(call_604594: Call_UpdateUsagePlan_604581; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_604595 = newJObject()
  var body_604596 = newJObject()
  add(path_604595, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_604596 = body
  result = call_604594.call(path_604595, nil, nil, nil, body_604596)

var updateUsagePlan* = Call_UpdateUsagePlan_604581(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_604582,
    base: "/", url: url_UpdateUsagePlan_604583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_604567 = ref object of OpenApiRestCall_602450
proc url_DeleteUsagePlan_604569(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_604568(path: JsonNode; query: JsonNode;
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
  var valid_604570 = path.getOrDefault("usageplanId")
  valid_604570 = validateParameter(valid_604570, JString, required = true,
                                 default = nil)
  if valid_604570 != nil:
    section.add "usageplanId", valid_604570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604571 = header.getOrDefault("X-Amz-Date")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Date", valid_604571
  var valid_604572 = header.getOrDefault("X-Amz-Security-Token")
  valid_604572 = validateParameter(valid_604572, JString, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "X-Amz-Security-Token", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Content-Sha256", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Algorithm")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Algorithm", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Signature")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Signature", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-SignedHeaders", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Credential")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Credential", valid_604577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604578: Call_DeleteUsagePlan_604567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_604578.validator(path, query, header, formData, body)
  let scheme = call_604578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604578.url(scheme.get, call_604578.host, call_604578.base,
                         call_604578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604578, url, valid)

proc call*(call_604579: Call_DeleteUsagePlan_604567; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_604580 = newJObject()
  add(path_604580, "usageplanId", newJString(usageplanId))
  result = call_604579.call(path_604580, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_604567(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_604568,
    base: "/", url: url_DeleteUsagePlan_604569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_604597 = ref object of OpenApiRestCall_602450
proc url_GetUsagePlanKey_604599(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_604598(path: JsonNode; query: JsonNode;
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
  var valid_604600 = path.getOrDefault("keyId")
  valid_604600 = validateParameter(valid_604600, JString, required = true,
                                 default = nil)
  if valid_604600 != nil:
    section.add "keyId", valid_604600
  var valid_604601 = path.getOrDefault("usageplanId")
  valid_604601 = validateParameter(valid_604601, JString, required = true,
                                 default = nil)
  if valid_604601 != nil:
    section.add "usageplanId", valid_604601
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604602 = header.getOrDefault("X-Amz-Date")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Date", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Security-Token")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Security-Token", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Content-Sha256", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Algorithm")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Algorithm", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-Signature")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-Signature", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-SignedHeaders", valid_604607
  var valid_604608 = header.getOrDefault("X-Amz-Credential")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Credential", valid_604608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604609: Call_GetUsagePlanKey_604597; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_604609.validator(path, query, header, formData, body)
  let scheme = call_604609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604609.url(scheme.get, call_604609.host, call_604609.base,
                         call_604609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604609, url, valid)

proc call*(call_604610: Call_GetUsagePlanKey_604597; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_604611 = newJObject()
  add(path_604611, "keyId", newJString(keyId))
  add(path_604611, "usageplanId", newJString(usageplanId))
  result = call_604610.call(path_604611, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_604597(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_604598, base: "/", url: url_GetUsagePlanKey_604599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_604612 = ref object of OpenApiRestCall_602450
proc url_DeleteUsagePlanKey_604614(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_604613(path: JsonNode; query: JsonNode;
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
  var valid_604615 = path.getOrDefault("keyId")
  valid_604615 = validateParameter(valid_604615, JString, required = true,
                                 default = nil)
  if valid_604615 != nil:
    section.add "keyId", valid_604615
  var valid_604616 = path.getOrDefault("usageplanId")
  valid_604616 = validateParameter(valid_604616, JString, required = true,
                                 default = nil)
  if valid_604616 != nil:
    section.add "usageplanId", valid_604616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604617 = header.getOrDefault("X-Amz-Date")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-Date", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Security-Token")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Security-Token", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Content-Sha256", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Algorithm")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Algorithm", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Signature")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Signature", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-SignedHeaders", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Credential")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Credential", valid_604623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604624: Call_DeleteUsagePlanKey_604612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_604624.validator(path, query, header, formData, body)
  let scheme = call_604624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604624.url(scheme.get, call_604624.host, call_604624.base,
                         call_604624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604624, url, valid)

proc call*(call_604625: Call_DeleteUsagePlanKey_604612; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_604626 = newJObject()
  add(path_604626, "keyId", newJString(keyId))
  add(path_604626, "usageplanId", newJString(usageplanId))
  result = call_604625.call(path_604626, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_604612(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_604613, base: "/",
    url: url_DeleteUsagePlanKey_604614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_604627 = ref object of OpenApiRestCall_602450
proc url_GetVpcLink_604629(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetVpcLink_604628(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604630 = path.getOrDefault("vpclink_id")
  valid_604630 = validateParameter(valid_604630, JString, required = true,
                                 default = nil)
  if valid_604630 != nil:
    section.add "vpclink_id", valid_604630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604631 = header.getOrDefault("X-Amz-Date")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Date", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-Security-Token")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Security-Token", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Content-Sha256", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Algorithm")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Algorithm", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Signature")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Signature", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-SignedHeaders", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Credential")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Credential", valid_604637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604638: Call_GetVpcLink_604627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_604638.validator(path, query, header, formData, body)
  let scheme = call_604638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604638.url(scheme.get, call_604638.host, call_604638.base,
                         call_604638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604638, url, valid)

proc call*(call_604639: Call_GetVpcLink_604627; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604640 = newJObject()
  add(path_604640, "vpclink_id", newJString(vpclinkId))
  result = call_604639.call(path_604640, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_604627(name: "getVpcLink",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/vpclinks/{vpclink_id}",
                                      validator: validate_GetVpcLink_604628,
                                      base: "/", url: url_GetVpcLink_604629,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_604655 = ref object of OpenApiRestCall_602450
proc url_UpdateVpcLink_604657(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_604656(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604658 = path.getOrDefault("vpclink_id")
  valid_604658 = validateParameter(valid_604658, JString, required = true,
                                 default = nil)
  if valid_604658 != nil:
    section.add "vpclink_id", valid_604658
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604659 = header.getOrDefault("X-Amz-Date")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "X-Amz-Date", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-Security-Token")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Security-Token", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-Content-Sha256", valid_604661
  var valid_604662 = header.getOrDefault("X-Amz-Algorithm")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Algorithm", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Signature")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Signature", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-SignedHeaders", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Credential")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Credential", valid_604665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604667: Call_UpdateVpcLink_604655; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_604667.validator(path, query, header, formData, body)
  let scheme = call_604667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604667.url(scheme.get, call_604667.host, call_604667.base,
                         call_604667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604667, url, valid)

proc call*(call_604668: Call_UpdateVpcLink_604655; body: JsonNode; vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604669 = newJObject()
  var body_604670 = newJObject()
  if body != nil:
    body_604670 = body
  add(path_604669, "vpclink_id", newJString(vpclinkId))
  result = call_604668.call(path_604669, nil, nil, nil, body_604670)

var updateVpcLink* = Call_UpdateVpcLink_604655(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_604656,
    base: "/", url: url_UpdateVpcLink_604657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_604641 = ref object of OpenApiRestCall_602450
proc url_DeleteVpcLink_604643(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_604642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604644 = path.getOrDefault("vpclink_id")
  valid_604644 = validateParameter(valid_604644, JString, required = true,
                                 default = nil)
  if valid_604644 != nil:
    section.add "vpclink_id", valid_604644
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604645 = header.getOrDefault("X-Amz-Date")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Date", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Security-Token")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Security-Token", valid_604646
  var valid_604647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "X-Amz-Content-Sha256", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Algorithm")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Algorithm", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Signature")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Signature", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-SignedHeaders", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-Credential")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-Credential", valid_604651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604652: Call_DeleteVpcLink_604641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_604652.validator(path, query, header, formData, body)
  let scheme = call_604652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604652.url(scheme.get, call_604652.host, call_604652.base,
                         call_604652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604652, url, valid)

proc call*(call_604653: Call_DeleteVpcLink_604641; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_604654 = newJObject()
  add(path_604654, "vpclink_id", newJString(vpclinkId))
  result = call_604653.call(path_604654, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_604641(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_604642,
    base: "/", url: url_DeleteVpcLink_604643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_604671 = ref object of OpenApiRestCall_602450
proc url_FlushStageAuthorizersCache_604673(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_604672(path: JsonNode; query: JsonNode;
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
  var valid_604674 = path.getOrDefault("stage_name")
  valid_604674 = validateParameter(valid_604674, JString, required = true,
                                 default = nil)
  if valid_604674 != nil:
    section.add "stage_name", valid_604674
  var valid_604675 = path.getOrDefault("restapi_id")
  valid_604675 = validateParameter(valid_604675, JString, required = true,
                                 default = nil)
  if valid_604675 != nil:
    section.add "restapi_id", valid_604675
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604676 = header.getOrDefault("X-Amz-Date")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Date", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Security-Token")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Security-Token", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Content-Sha256", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Algorithm")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Algorithm", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Signature")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Signature", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-SignedHeaders", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-Credential")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Credential", valid_604682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604683: Call_FlushStageAuthorizersCache_604671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_604683.validator(path, query, header, formData, body)
  let scheme = call_604683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604683.url(scheme.get, call_604683.host, call_604683.base,
                         call_604683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604683, url, valid)

proc call*(call_604684: Call_FlushStageAuthorizersCache_604671; stageName: string;
          restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_604685 = newJObject()
  add(path_604685, "stage_name", newJString(stageName))
  add(path_604685, "restapi_id", newJString(restapiId))
  result = call_604684.call(path_604685, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_604671(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_604672, base: "/",
    url: url_FlushStageAuthorizersCache_604673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_604686 = ref object of OpenApiRestCall_602450
proc url_FlushStageCache_604688(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_604687(path: JsonNode; query: JsonNode;
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
  var valid_604689 = path.getOrDefault("stage_name")
  valid_604689 = validateParameter(valid_604689, JString, required = true,
                                 default = nil)
  if valid_604689 != nil:
    section.add "stage_name", valid_604689
  var valid_604690 = path.getOrDefault("restapi_id")
  valid_604690 = validateParameter(valid_604690, JString, required = true,
                                 default = nil)
  if valid_604690 != nil:
    section.add "restapi_id", valid_604690
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604691 = header.getOrDefault("X-Amz-Date")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Date", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Security-Token")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Security-Token", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Content-Sha256", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Algorithm")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Algorithm", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Signature")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Signature", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-SignedHeaders", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Credential")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Credential", valid_604697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604698: Call_FlushStageCache_604686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_604698.validator(path, query, header, formData, body)
  let scheme = call_604698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604698.url(scheme.get, call_604698.host, call_604698.base,
                         call_604698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604698, url, valid)

proc call*(call_604699: Call_FlushStageCache_604686; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604700 = newJObject()
  add(path_604700, "stage_name", newJString(stageName))
  add(path_604700, "restapi_id", newJString(restapiId))
  result = call_604699.call(path_604700, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_604686(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_604687, base: "/", url: url_FlushStageCache_604688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_604716 = ref object of OpenApiRestCall_602450
proc url_GenerateClientCertificate_604718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateClientCertificate_604717(path: JsonNode; query: JsonNode;
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
  var valid_604719 = header.getOrDefault("X-Amz-Date")
  valid_604719 = validateParameter(valid_604719, JString, required = false,
                                 default = nil)
  if valid_604719 != nil:
    section.add "X-Amz-Date", valid_604719
  var valid_604720 = header.getOrDefault("X-Amz-Security-Token")
  valid_604720 = validateParameter(valid_604720, JString, required = false,
                                 default = nil)
  if valid_604720 != nil:
    section.add "X-Amz-Security-Token", valid_604720
  var valid_604721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Content-Sha256", valid_604721
  var valid_604722 = header.getOrDefault("X-Amz-Algorithm")
  valid_604722 = validateParameter(valid_604722, JString, required = false,
                                 default = nil)
  if valid_604722 != nil:
    section.add "X-Amz-Algorithm", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Signature")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Signature", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-SignedHeaders", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Credential")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Credential", valid_604725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604727: Call_GenerateClientCertificate_604716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_604727.validator(path, query, header, formData, body)
  let scheme = call_604727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604727.url(scheme.get, call_604727.host, call_604727.base,
                         call_604727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604727, url, valid)

proc call*(call_604728: Call_GenerateClientCertificate_604716; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_604729 = newJObject()
  if body != nil:
    body_604729 = body
  result = call_604728.call(nil, nil, nil, nil, body_604729)

var generateClientCertificate* = Call_GenerateClientCertificate_604716(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_604717, base: "/",
    url: url_GenerateClientCertificate_604718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_604701 = ref object of OpenApiRestCall_602450
proc url_GetClientCertificates_604703(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClientCertificates_604702(path: JsonNode; query: JsonNode;
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
  var valid_604704 = query.getOrDefault("position")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "position", valid_604704
  var valid_604705 = query.getOrDefault("limit")
  valid_604705 = validateParameter(valid_604705, JInt, required = false, default = nil)
  if valid_604705 != nil:
    section.add "limit", valid_604705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604706 = header.getOrDefault("X-Amz-Date")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Date", valid_604706
  var valid_604707 = header.getOrDefault("X-Amz-Security-Token")
  valid_604707 = validateParameter(valid_604707, JString, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "X-Amz-Security-Token", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Content-Sha256", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Algorithm")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Algorithm", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Signature")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Signature", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-SignedHeaders", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Credential")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Credential", valid_604712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604713: Call_GetClientCertificates_604701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_604713.validator(path, query, header, formData, body)
  let scheme = call_604713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604713.url(scheme.get, call_604713.host, call_604713.base,
                         call_604713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604713, url, valid)

proc call*(call_604714: Call_GetClientCertificates_604701; position: string = "";
          limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_604715 = newJObject()
  add(query_604715, "position", newJString(position))
  add(query_604715, "limit", newJInt(limit))
  result = call_604714.call(nil, query_604715, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_604701(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_604702, base: "/",
    url: url_GetClientCertificates_604703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_604730 = ref object of OpenApiRestCall_602450
proc url_GetAccount_604732(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccount_604731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604733 = header.getOrDefault("X-Amz-Date")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "X-Amz-Date", valid_604733
  var valid_604734 = header.getOrDefault("X-Amz-Security-Token")
  valid_604734 = validateParameter(valid_604734, JString, required = false,
                                 default = nil)
  if valid_604734 != nil:
    section.add "X-Amz-Security-Token", valid_604734
  var valid_604735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Content-Sha256", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Algorithm")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Algorithm", valid_604736
  var valid_604737 = header.getOrDefault("X-Amz-Signature")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "X-Amz-Signature", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-SignedHeaders", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Credential")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Credential", valid_604739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604740: Call_GetAccount_604730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_604740.validator(path, query, header, formData, body)
  let scheme = call_604740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604740.url(scheme.get, call_604740.host, call_604740.base,
                         call_604740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604740, url, valid)

proc call*(call_604741: Call_GetAccount_604730): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_604741.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_604730(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/account",
                                      validator: validate_GetAccount_604731,
                                      base: "/", url: url_GetAccount_604732,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_604742 = ref object of OpenApiRestCall_602450
proc url_UpdateAccount_604744(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAccount_604743(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604745 = header.getOrDefault("X-Amz-Date")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "X-Amz-Date", valid_604745
  var valid_604746 = header.getOrDefault("X-Amz-Security-Token")
  valid_604746 = validateParameter(valid_604746, JString, required = false,
                                 default = nil)
  if valid_604746 != nil:
    section.add "X-Amz-Security-Token", valid_604746
  var valid_604747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604747 = validateParameter(valid_604747, JString, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "X-Amz-Content-Sha256", valid_604747
  var valid_604748 = header.getOrDefault("X-Amz-Algorithm")
  valid_604748 = validateParameter(valid_604748, JString, required = false,
                                 default = nil)
  if valid_604748 != nil:
    section.add "X-Amz-Algorithm", valid_604748
  var valid_604749 = header.getOrDefault("X-Amz-Signature")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "X-Amz-Signature", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-SignedHeaders", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Credential")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Credential", valid_604751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604753: Call_UpdateAccount_604742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_604753.validator(path, query, header, formData, body)
  let scheme = call_604753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604753.url(scheme.get, call_604753.host, call_604753.base,
                         call_604753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604753, url, valid)

proc call*(call_604754: Call_UpdateAccount_604742; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_604755 = newJObject()
  if body != nil:
    body_604755 = body
  result = call_604754.call(nil, nil, nil, nil, body_604755)

var updateAccount* = Call_UpdateAccount_604742(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_604743, base: "/", url: url_UpdateAccount_604744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_604756 = ref object of OpenApiRestCall_602450
proc url_GetExport_604758(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_604757(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604759 = path.getOrDefault("export_type")
  valid_604759 = validateParameter(valid_604759, JString, required = true,
                                 default = nil)
  if valid_604759 != nil:
    section.add "export_type", valid_604759
  var valid_604760 = path.getOrDefault("stage_name")
  valid_604760 = validateParameter(valid_604760, JString, required = true,
                                 default = nil)
  if valid_604760 != nil:
    section.add "stage_name", valid_604760
  var valid_604761 = path.getOrDefault("restapi_id")
  valid_604761 = validateParameter(valid_604761, JString, required = true,
                                 default = nil)
  if valid_604761 != nil:
    section.add "restapi_id", valid_604761
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_604762 = query.getOrDefault("parameters.0.value")
  valid_604762 = validateParameter(valid_604762, JString, required = false,
                                 default = nil)
  if valid_604762 != nil:
    section.add "parameters.0.value", valid_604762
  var valid_604763 = query.getOrDefault("parameters.2.value")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "parameters.2.value", valid_604763
  var valid_604764 = query.getOrDefault("parameters.1.key")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "parameters.1.key", valid_604764
  var valid_604765 = query.getOrDefault("parameters.0.key")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "parameters.0.key", valid_604765
  var valid_604766 = query.getOrDefault("parameters.2.key")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "parameters.2.key", valid_604766
  var valid_604767 = query.getOrDefault("parameters.1.value")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "parameters.1.value", valid_604767
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
  var valid_604768 = header.getOrDefault("X-Amz-Date")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Date", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Security-Token")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Security-Token", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Content-Sha256", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-Algorithm")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Algorithm", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Signature")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Signature", valid_604772
  var valid_604773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-SignedHeaders", valid_604773
  var valid_604774 = header.getOrDefault("Accept")
  valid_604774 = validateParameter(valid_604774, JString, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "Accept", valid_604774
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

proc call*(call_604776: Call_GetExport_604756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_604776.validator(path, query, header, formData, body)
  let scheme = call_604776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604776.url(scheme.get, call_604776.host, call_604776.base,
                         call_604776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604776, url, valid)

proc call*(call_604777: Call_GetExport_604756; exportType: string; stageName: string;
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
  var path_604778 = newJObject()
  var query_604779 = newJObject()
  add(query_604779, "parameters.0.value", newJString(parameters0Value))
  add(query_604779, "parameters.2.value", newJString(parameters2Value))
  add(query_604779, "parameters.1.key", newJString(parameters1Key))
  add(query_604779, "parameters.0.key", newJString(parameters0Key))
  add(path_604778, "export_type", newJString(exportType))
  add(query_604779, "parameters.2.key", newJString(parameters2Key))
  add(path_604778, "stage_name", newJString(stageName))
  add(query_604779, "parameters.1.value", newJString(parameters1Value))
  add(path_604778, "restapi_id", newJString(restapiId))
  result = call_604777.call(path_604778, query_604779, nil, nil, nil)

var getExport* = Call_GetExport_604756(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                    validator: validate_GetExport_604757,
                                    base: "/", url: url_GetExport_604758,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_604780 = ref object of OpenApiRestCall_602450
proc url_GetGatewayResponses_604782(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_604781(path: JsonNode; query: JsonNode;
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
  var valid_604783 = path.getOrDefault("restapi_id")
  valid_604783 = validateParameter(valid_604783, JString, required = true,
                                 default = nil)
  if valid_604783 != nil:
    section.add "restapi_id", valid_604783
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
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

proc call*(call_604793: Call_GetGatewayResponses_604780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_604793.validator(path, query, header, formData, body)
  let scheme = call_604793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604793.url(scheme.get, call_604793.host, call_604793.base,
                         call_604793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604793, url, valid)

proc call*(call_604794: Call_GetGatewayResponses_604780; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604795 = newJObject()
  var query_604796 = newJObject()
  add(query_604796, "position", newJString(position))
  add(query_604796, "limit", newJInt(limit))
  add(path_604795, "restapi_id", newJString(restapiId))
  result = call_604794.call(path_604795, query_604796, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_604780(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_604781, base: "/",
    url: url_GetGatewayResponses_604782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_604797 = ref object of OpenApiRestCall_602450
proc url_GetModelTemplate_604799(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_604798(path: JsonNode; query: JsonNode;
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
  var valid_604800 = path.getOrDefault("model_name")
  valid_604800 = validateParameter(valid_604800, JString, required = true,
                                 default = nil)
  if valid_604800 != nil:
    section.add "model_name", valid_604800
  var valid_604801 = path.getOrDefault("restapi_id")
  valid_604801 = validateParameter(valid_604801, JString, required = true,
                                 default = nil)
  if valid_604801 != nil:
    section.add "restapi_id", valid_604801
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604802 = header.getOrDefault("X-Amz-Date")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Date", valid_604802
  var valid_604803 = header.getOrDefault("X-Amz-Security-Token")
  valid_604803 = validateParameter(valid_604803, JString, required = false,
                                 default = nil)
  if valid_604803 != nil:
    section.add "X-Amz-Security-Token", valid_604803
  var valid_604804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "X-Amz-Content-Sha256", valid_604804
  var valid_604805 = header.getOrDefault("X-Amz-Algorithm")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "X-Amz-Algorithm", valid_604805
  var valid_604806 = header.getOrDefault("X-Amz-Signature")
  valid_604806 = validateParameter(valid_604806, JString, required = false,
                                 default = nil)
  if valid_604806 != nil:
    section.add "X-Amz-Signature", valid_604806
  var valid_604807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "X-Amz-SignedHeaders", valid_604807
  var valid_604808 = header.getOrDefault("X-Amz-Credential")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Credential", valid_604808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604809: Call_GetModelTemplate_604797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_604809.validator(path, query, header, formData, body)
  let scheme = call_604809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604809.url(scheme.get, call_604809.host, call_604809.base,
                         call_604809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604809, url, valid)

proc call*(call_604810: Call_GetModelTemplate_604797; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_604811 = newJObject()
  add(path_604811, "model_name", newJString(modelName))
  add(path_604811, "restapi_id", newJString(restapiId))
  result = call_604810.call(path_604811, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_604797(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_604798, base: "/",
    url: url_GetModelTemplate_604799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_604812 = ref object of OpenApiRestCall_602450
proc url_GetResources_604814(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_604813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604815 = path.getOrDefault("restapi_id")
  valid_604815 = validateParameter(valid_604815, JString, required = true,
                                 default = nil)
  if valid_604815 != nil:
    section.add "restapi_id", valid_604815
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_604816 = query.getOrDefault("embed")
  valid_604816 = validateParameter(valid_604816, JArray, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "embed", valid_604816
  var valid_604817 = query.getOrDefault("position")
  valid_604817 = validateParameter(valid_604817, JString, required = false,
                                 default = nil)
  if valid_604817 != nil:
    section.add "position", valid_604817
  var valid_604818 = query.getOrDefault("limit")
  valid_604818 = validateParameter(valid_604818, JInt, required = false, default = nil)
  if valid_604818 != nil:
    section.add "limit", valid_604818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604819 = header.getOrDefault("X-Amz-Date")
  valid_604819 = validateParameter(valid_604819, JString, required = false,
                                 default = nil)
  if valid_604819 != nil:
    section.add "X-Amz-Date", valid_604819
  var valid_604820 = header.getOrDefault("X-Amz-Security-Token")
  valid_604820 = validateParameter(valid_604820, JString, required = false,
                                 default = nil)
  if valid_604820 != nil:
    section.add "X-Amz-Security-Token", valid_604820
  var valid_604821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604821 = validateParameter(valid_604821, JString, required = false,
                                 default = nil)
  if valid_604821 != nil:
    section.add "X-Amz-Content-Sha256", valid_604821
  var valid_604822 = header.getOrDefault("X-Amz-Algorithm")
  valid_604822 = validateParameter(valid_604822, JString, required = false,
                                 default = nil)
  if valid_604822 != nil:
    section.add "X-Amz-Algorithm", valid_604822
  var valid_604823 = header.getOrDefault("X-Amz-Signature")
  valid_604823 = validateParameter(valid_604823, JString, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "X-Amz-Signature", valid_604823
  var valid_604824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-SignedHeaders", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Credential")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Credential", valid_604825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604826: Call_GetResources_604812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_604826.validator(path, query, header, formData, body)
  let scheme = call_604826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604826.url(scheme.get, call_604826.host, call_604826.base,
                         call_604826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604826, url, valid)

proc call*(call_604827: Call_GetResources_604812; restapiId: string;
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
  var path_604828 = newJObject()
  var query_604829 = newJObject()
  if embed != nil:
    query_604829.add "embed", embed
  add(query_604829, "position", newJString(position))
  add(query_604829, "limit", newJInt(limit))
  add(path_604828, "restapi_id", newJString(restapiId))
  result = call_604827.call(path_604828, query_604829, nil, nil, nil)

var getResources* = Call_GetResources_604812(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_604813,
    base: "/", url: url_GetResources_604814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_604830 = ref object of OpenApiRestCall_602450
proc url_GetSdk_604832(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_604831(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604833 = path.getOrDefault("sdk_type")
  valid_604833 = validateParameter(valid_604833, JString, required = true,
                                 default = nil)
  if valid_604833 != nil:
    section.add "sdk_type", valid_604833
  var valid_604834 = path.getOrDefault("stage_name")
  valid_604834 = validateParameter(valid_604834, JString, required = true,
                                 default = nil)
  if valid_604834 != nil:
    section.add "stage_name", valid_604834
  var valid_604835 = path.getOrDefault("restapi_id")
  valid_604835 = validateParameter(valid_604835, JString, required = true,
                                 default = nil)
  if valid_604835 != nil:
    section.add "restapi_id", valid_604835
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_604836 = query.getOrDefault("parameters.0.value")
  valid_604836 = validateParameter(valid_604836, JString, required = false,
                                 default = nil)
  if valid_604836 != nil:
    section.add "parameters.0.value", valid_604836
  var valid_604837 = query.getOrDefault("parameters.2.value")
  valid_604837 = validateParameter(valid_604837, JString, required = false,
                                 default = nil)
  if valid_604837 != nil:
    section.add "parameters.2.value", valid_604837
  var valid_604838 = query.getOrDefault("parameters.1.key")
  valid_604838 = validateParameter(valid_604838, JString, required = false,
                                 default = nil)
  if valid_604838 != nil:
    section.add "parameters.1.key", valid_604838
  var valid_604839 = query.getOrDefault("parameters.0.key")
  valid_604839 = validateParameter(valid_604839, JString, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "parameters.0.key", valid_604839
  var valid_604840 = query.getOrDefault("parameters.2.key")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "parameters.2.key", valid_604840
  var valid_604841 = query.getOrDefault("parameters.1.value")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "parameters.1.value", valid_604841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604842 = header.getOrDefault("X-Amz-Date")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Date", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Security-Token")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Security-Token", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Content-Sha256", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Algorithm")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Algorithm", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Signature")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Signature", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-SignedHeaders", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Credential")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Credential", valid_604848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604849: Call_GetSdk_604830; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_604849.validator(path, query, header, formData, body)
  let scheme = call_604849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604849.url(scheme.get, call_604849.host, call_604849.base,
                         call_604849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604849, url, valid)

proc call*(call_604850: Call_GetSdk_604830; sdkType: string; stageName: string;
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
  var path_604851 = newJObject()
  var query_604852 = newJObject()
  add(path_604851, "sdk_type", newJString(sdkType))
  add(query_604852, "parameters.0.value", newJString(parameters0Value))
  add(query_604852, "parameters.2.value", newJString(parameters2Value))
  add(query_604852, "parameters.1.key", newJString(parameters1Key))
  add(query_604852, "parameters.0.key", newJString(parameters0Key))
  add(query_604852, "parameters.2.key", newJString(parameters2Key))
  add(path_604851, "stage_name", newJString(stageName))
  add(query_604852, "parameters.1.value", newJString(parameters1Value))
  add(path_604851, "restapi_id", newJString(restapiId))
  result = call_604850.call(path_604851, query_604852, nil, nil, nil)

var getSdk* = Call_GetSdk_604830(name: "getSdk", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                              validator: validate_GetSdk_604831, base: "/",
                              url: url_GetSdk_604832,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_604853 = ref object of OpenApiRestCall_602450
proc url_GetSdkType_604855(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdkType_604854(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_604856 = path.getOrDefault("sdktype_id")
  valid_604856 = validateParameter(valid_604856, JString, required = true,
                                 default = nil)
  if valid_604856 != nil:
    section.add "sdktype_id", valid_604856
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604857 = header.getOrDefault("X-Amz-Date")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-Date", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Security-Token")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Security-Token", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Content-Sha256", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-Algorithm")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-Algorithm", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Signature")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Signature", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-SignedHeaders", valid_604862
  var valid_604863 = header.getOrDefault("X-Amz-Credential")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "X-Amz-Credential", valid_604863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604864: Call_GetSdkType_604853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604864.validator(path, query, header, formData, body)
  let scheme = call_604864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604864.url(scheme.get, call_604864.host, call_604864.base,
                         call_604864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604864, url, valid)

proc call*(call_604865: Call_GetSdkType_604853; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_604866 = newJObject()
  add(path_604866, "sdktype_id", newJString(sdktypeId))
  result = call_604865.call(path_604866, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_604853(name: "getSdkType",
                                      meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/sdktypes/{sdktype_id}",
                                      validator: validate_GetSdkType_604854,
                                      base: "/", url: url_GetSdkType_604855,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_604867 = ref object of OpenApiRestCall_602450
proc url_GetSdkTypes_604869(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSdkTypes_604868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604870 = query.getOrDefault("position")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "position", valid_604870
  var valid_604871 = query.getOrDefault("limit")
  valid_604871 = validateParameter(valid_604871, JInt, required = false, default = nil)
  if valid_604871 != nil:
    section.add "limit", valid_604871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604872 = header.getOrDefault("X-Amz-Date")
  valid_604872 = validateParameter(valid_604872, JString, required = false,
                                 default = nil)
  if valid_604872 != nil:
    section.add "X-Amz-Date", valid_604872
  var valid_604873 = header.getOrDefault("X-Amz-Security-Token")
  valid_604873 = validateParameter(valid_604873, JString, required = false,
                                 default = nil)
  if valid_604873 != nil:
    section.add "X-Amz-Security-Token", valid_604873
  var valid_604874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604874 = validateParameter(valid_604874, JString, required = false,
                                 default = nil)
  if valid_604874 != nil:
    section.add "X-Amz-Content-Sha256", valid_604874
  var valid_604875 = header.getOrDefault("X-Amz-Algorithm")
  valid_604875 = validateParameter(valid_604875, JString, required = false,
                                 default = nil)
  if valid_604875 != nil:
    section.add "X-Amz-Algorithm", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-Signature")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-Signature", valid_604876
  var valid_604877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-SignedHeaders", valid_604877
  var valid_604878 = header.getOrDefault("X-Amz-Credential")
  valid_604878 = validateParameter(valid_604878, JString, required = false,
                                 default = nil)
  if valid_604878 != nil:
    section.add "X-Amz-Credential", valid_604878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604879: Call_GetSdkTypes_604867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604879.validator(path, query, header, formData, body)
  let scheme = call_604879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604879.url(scheme.get, call_604879.host, call_604879.base,
                         call_604879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604879, url, valid)

proc call*(call_604880: Call_GetSdkTypes_604867; position: string = ""; limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_604881 = newJObject()
  add(query_604881, "position", newJString(position))
  add(query_604881, "limit", newJInt(limit))
  result = call_604880.call(nil, query_604881, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_604867(name: "getSdkTypes",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes",
                                        validator: validate_GetSdkTypes_604868,
                                        base: "/", url: url_GetSdkTypes_604869,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604899 = ref object of OpenApiRestCall_602450
proc url_TagResource_604901(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_604900(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604902 = path.getOrDefault("resource_arn")
  valid_604902 = validateParameter(valid_604902, JString, required = true,
                                 default = nil)
  if valid_604902 != nil:
    section.add "resource_arn", valid_604902
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604903 = header.getOrDefault("X-Amz-Date")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-Date", valid_604903
  var valid_604904 = header.getOrDefault("X-Amz-Security-Token")
  valid_604904 = validateParameter(valid_604904, JString, required = false,
                                 default = nil)
  if valid_604904 != nil:
    section.add "X-Amz-Security-Token", valid_604904
  var valid_604905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604905 = validateParameter(valid_604905, JString, required = false,
                                 default = nil)
  if valid_604905 != nil:
    section.add "X-Amz-Content-Sha256", valid_604905
  var valid_604906 = header.getOrDefault("X-Amz-Algorithm")
  valid_604906 = validateParameter(valid_604906, JString, required = false,
                                 default = nil)
  if valid_604906 != nil:
    section.add "X-Amz-Algorithm", valid_604906
  var valid_604907 = header.getOrDefault("X-Amz-Signature")
  valid_604907 = validateParameter(valid_604907, JString, required = false,
                                 default = nil)
  if valid_604907 != nil:
    section.add "X-Amz-Signature", valid_604907
  var valid_604908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604908 = validateParameter(valid_604908, JString, required = false,
                                 default = nil)
  if valid_604908 != nil:
    section.add "X-Amz-SignedHeaders", valid_604908
  var valid_604909 = header.getOrDefault("X-Amz-Credential")
  valid_604909 = validateParameter(valid_604909, JString, required = false,
                                 default = nil)
  if valid_604909 != nil:
    section.add "X-Amz-Credential", valid_604909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604911: Call_TagResource_604899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_604911.validator(path, query, header, formData, body)
  let scheme = call_604911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604911.url(scheme.get, call_604911.host, call_604911.base,
                         call_604911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604911, url, valid)

proc call*(call_604912: Call_TagResource_604899; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_604913 = newJObject()
  var body_604914 = newJObject()
  add(path_604913, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_604914 = body
  result = call_604912.call(path_604913, nil, nil, nil, body_604914)

var tagResource* = Call_TagResource_604899(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/tags/{resource_arn}",
                                        validator: validate_TagResource_604900,
                                        base: "/", url: url_TagResource_604901,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_604882 = ref object of OpenApiRestCall_602450
proc url_GetTags_604884(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_604883(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604885 = path.getOrDefault("resource_arn")
  valid_604885 = validateParameter(valid_604885, JString, required = true,
                                 default = nil)
  if valid_604885 != nil:
    section.add "resource_arn", valid_604885
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_604886 = query.getOrDefault("position")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "position", valid_604886
  var valid_604887 = query.getOrDefault("limit")
  valid_604887 = validateParameter(valid_604887, JInt, required = false, default = nil)
  if valid_604887 != nil:
    section.add "limit", valid_604887
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604888 = header.getOrDefault("X-Amz-Date")
  valid_604888 = validateParameter(valid_604888, JString, required = false,
                                 default = nil)
  if valid_604888 != nil:
    section.add "X-Amz-Date", valid_604888
  var valid_604889 = header.getOrDefault("X-Amz-Security-Token")
  valid_604889 = validateParameter(valid_604889, JString, required = false,
                                 default = nil)
  if valid_604889 != nil:
    section.add "X-Amz-Security-Token", valid_604889
  var valid_604890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604890 = validateParameter(valid_604890, JString, required = false,
                                 default = nil)
  if valid_604890 != nil:
    section.add "X-Amz-Content-Sha256", valid_604890
  var valid_604891 = header.getOrDefault("X-Amz-Algorithm")
  valid_604891 = validateParameter(valid_604891, JString, required = false,
                                 default = nil)
  if valid_604891 != nil:
    section.add "X-Amz-Algorithm", valid_604891
  var valid_604892 = header.getOrDefault("X-Amz-Signature")
  valid_604892 = validateParameter(valid_604892, JString, required = false,
                                 default = nil)
  if valid_604892 != nil:
    section.add "X-Amz-Signature", valid_604892
  var valid_604893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604893 = validateParameter(valid_604893, JString, required = false,
                                 default = nil)
  if valid_604893 != nil:
    section.add "X-Amz-SignedHeaders", valid_604893
  var valid_604894 = header.getOrDefault("X-Amz-Credential")
  valid_604894 = validateParameter(valid_604894, JString, required = false,
                                 default = nil)
  if valid_604894 != nil:
    section.add "X-Amz-Credential", valid_604894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604895: Call_GetTags_604882; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_604895.validator(path, query, header, formData, body)
  let scheme = call_604895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604895.url(scheme.get, call_604895.host, call_604895.base,
                         call_604895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604895, url, valid)

proc call*(call_604896: Call_GetTags_604882; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_604897 = newJObject()
  var query_604898 = newJObject()
  add(path_604897, "resource_arn", newJString(resourceArn))
  add(query_604898, "position", newJString(position))
  add(query_604898, "limit", newJInt(limit))
  result = call_604896.call(path_604897, query_604898, nil, nil, nil)

var getTags* = Call_GetTags_604882(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/tags/{resource_arn}",
                                validator: validate_GetTags_604883, base: "/",
                                url: url_GetTags_604884,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_604915 = ref object of OpenApiRestCall_602450
proc url_GetUsage_604917(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_604916(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604918 = path.getOrDefault("usageplanId")
  valid_604918 = validateParameter(valid_604918, JString, required = true,
                                 default = nil)
  if valid_604918 != nil:
    section.add "usageplanId", valid_604918
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
  var valid_604919 = query.getOrDefault("endDate")
  valid_604919 = validateParameter(valid_604919, JString, required = true,
                                 default = nil)
  if valid_604919 != nil:
    section.add "endDate", valid_604919
  var valid_604920 = query.getOrDefault("startDate")
  valid_604920 = validateParameter(valid_604920, JString, required = true,
                                 default = nil)
  if valid_604920 != nil:
    section.add "startDate", valid_604920
  var valid_604921 = query.getOrDefault("keyId")
  valid_604921 = validateParameter(valid_604921, JString, required = false,
                                 default = nil)
  if valid_604921 != nil:
    section.add "keyId", valid_604921
  var valid_604922 = query.getOrDefault("position")
  valid_604922 = validateParameter(valid_604922, JString, required = false,
                                 default = nil)
  if valid_604922 != nil:
    section.add "position", valid_604922
  var valid_604923 = query.getOrDefault("limit")
  valid_604923 = validateParameter(valid_604923, JInt, required = false, default = nil)
  if valid_604923 != nil:
    section.add "limit", valid_604923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604924 = header.getOrDefault("X-Amz-Date")
  valid_604924 = validateParameter(valid_604924, JString, required = false,
                                 default = nil)
  if valid_604924 != nil:
    section.add "X-Amz-Date", valid_604924
  var valid_604925 = header.getOrDefault("X-Amz-Security-Token")
  valid_604925 = validateParameter(valid_604925, JString, required = false,
                                 default = nil)
  if valid_604925 != nil:
    section.add "X-Amz-Security-Token", valid_604925
  var valid_604926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604926 = validateParameter(valid_604926, JString, required = false,
                                 default = nil)
  if valid_604926 != nil:
    section.add "X-Amz-Content-Sha256", valid_604926
  var valid_604927 = header.getOrDefault("X-Amz-Algorithm")
  valid_604927 = validateParameter(valid_604927, JString, required = false,
                                 default = nil)
  if valid_604927 != nil:
    section.add "X-Amz-Algorithm", valid_604927
  var valid_604928 = header.getOrDefault("X-Amz-Signature")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "X-Amz-Signature", valid_604928
  var valid_604929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604929 = validateParameter(valid_604929, JString, required = false,
                                 default = nil)
  if valid_604929 != nil:
    section.add "X-Amz-SignedHeaders", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-Credential")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Credential", valid_604930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604931: Call_GetUsage_604915; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_604931.validator(path, query, header, formData, body)
  let scheme = call_604931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604931.url(scheme.get, call_604931.host, call_604931.base,
                         call_604931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604931, url, valid)

proc call*(call_604932: Call_GetUsage_604915; endDate: string; startDate: string;
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
  var path_604933 = newJObject()
  var query_604934 = newJObject()
  add(query_604934, "endDate", newJString(endDate))
  add(query_604934, "startDate", newJString(startDate))
  add(path_604933, "usageplanId", newJString(usageplanId))
  add(query_604934, "keyId", newJString(keyId))
  add(query_604934, "position", newJString(position))
  add(query_604934, "limit", newJInt(limit))
  result = call_604932.call(path_604933, query_604934, nil, nil, nil)

var getUsage* = Call_GetUsage_604915(name: "getUsage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                  validator: validate_GetUsage_604916, base: "/",
                                  url: url_GetUsage_604917,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_604935 = ref object of OpenApiRestCall_602450
proc url_ImportApiKeys_604937(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportApiKeys_604936(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604938 = query.getOrDefault("mode")
  valid_604938 = validateParameter(valid_604938, JString, required = true,
                                 default = newJString("import"))
  if valid_604938 != nil:
    section.add "mode", valid_604938
  var valid_604939 = query.getOrDefault("failonwarnings")
  valid_604939 = validateParameter(valid_604939, JBool, required = false, default = nil)
  if valid_604939 != nil:
    section.add "failonwarnings", valid_604939
  var valid_604940 = query.getOrDefault("format")
  valid_604940 = validateParameter(valid_604940, JString, required = true,
                                 default = newJString("csv"))
  if valid_604940 != nil:
    section.add "format", valid_604940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604941 = header.getOrDefault("X-Amz-Date")
  valid_604941 = validateParameter(valid_604941, JString, required = false,
                                 default = nil)
  if valid_604941 != nil:
    section.add "X-Amz-Date", valid_604941
  var valid_604942 = header.getOrDefault("X-Amz-Security-Token")
  valid_604942 = validateParameter(valid_604942, JString, required = false,
                                 default = nil)
  if valid_604942 != nil:
    section.add "X-Amz-Security-Token", valid_604942
  var valid_604943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604943 = validateParameter(valid_604943, JString, required = false,
                                 default = nil)
  if valid_604943 != nil:
    section.add "X-Amz-Content-Sha256", valid_604943
  var valid_604944 = header.getOrDefault("X-Amz-Algorithm")
  valid_604944 = validateParameter(valid_604944, JString, required = false,
                                 default = nil)
  if valid_604944 != nil:
    section.add "X-Amz-Algorithm", valid_604944
  var valid_604945 = header.getOrDefault("X-Amz-Signature")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "X-Amz-Signature", valid_604945
  var valid_604946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "X-Amz-SignedHeaders", valid_604946
  var valid_604947 = header.getOrDefault("X-Amz-Credential")
  valid_604947 = validateParameter(valid_604947, JString, required = false,
                                 default = nil)
  if valid_604947 != nil:
    section.add "X-Amz-Credential", valid_604947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604949: Call_ImportApiKeys_604935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_604949.validator(path, query, header, formData, body)
  let scheme = call_604949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604949.url(scheme.get, call_604949.host, call_604949.base,
                         call_604949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604949, url, valid)

proc call*(call_604950: Call_ImportApiKeys_604935; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_604951 = newJObject()
  var body_604952 = newJObject()
  add(query_604951, "mode", newJString(mode))
  add(query_604951, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604952 = body
  add(query_604951, "format", newJString(format))
  result = call_604950.call(nil, query_604951, nil, nil, body_604952)

var importApiKeys* = Call_ImportApiKeys_604935(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_604936,
    base: "/", url: url_ImportApiKeys_604937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_604953 = ref object of OpenApiRestCall_602450
proc url_ImportRestApi_604955(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportRestApi_604954(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604956 = query.getOrDefault("parameters.0.value")
  valid_604956 = validateParameter(valid_604956, JString, required = false,
                                 default = nil)
  if valid_604956 != nil:
    section.add "parameters.0.value", valid_604956
  var valid_604957 = query.getOrDefault("parameters.2.value")
  valid_604957 = validateParameter(valid_604957, JString, required = false,
                                 default = nil)
  if valid_604957 != nil:
    section.add "parameters.2.value", valid_604957
  var valid_604958 = query.getOrDefault("parameters.1.key")
  valid_604958 = validateParameter(valid_604958, JString, required = false,
                                 default = nil)
  if valid_604958 != nil:
    section.add "parameters.1.key", valid_604958
  var valid_604959 = query.getOrDefault("parameters.0.key")
  valid_604959 = validateParameter(valid_604959, JString, required = false,
                                 default = nil)
  if valid_604959 != nil:
    section.add "parameters.0.key", valid_604959
  assert query != nil, "query argument is necessary due to required `mode` field"
  var valid_604960 = query.getOrDefault("mode")
  valid_604960 = validateParameter(valid_604960, JString, required = true,
                                 default = newJString("import"))
  if valid_604960 != nil:
    section.add "mode", valid_604960
  var valid_604961 = query.getOrDefault("parameters.2.key")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "parameters.2.key", valid_604961
  var valid_604962 = query.getOrDefault("failonwarnings")
  valid_604962 = validateParameter(valid_604962, JBool, required = false, default = nil)
  if valid_604962 != nil:
    section.add "failonwarnings", valid_604962
  var valid_604963 = query.getOrDefault("parameters.1.value")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "parameters.1.value", valid_604963
  result.add "query", section
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

proc call*(call_604972: Call_ImportRestApi_604953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_604972.validator(path, query, header, formData, body)
  let scheme = call_604972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604972.url(scheme.get, call_604972.host, call_604972.base,
                         call_604972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604972, url, valid)

proc call*(call_604973: Call_ImportRestApi_604953; body: JsonNode;
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
  var query_604974 = newJObject()
  var body_604975 = newJObject()
  add(query_604974, "parameters.0.value", newJString(parameters0Value))
  add(query_604974, "parameters.2.value", newJString(parameters2Value))
  add(query_604974, "parameters.1.key", newJString(parameters1Key))
  add(query_604974, "parameters.0.key", newJString(parameters0Key))
  add(query_604974, "mode", newJString(mode))
  add(query_604974, "parameters.2.key", newJString(parameters2Key))
  add(query_604974, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_604975 = body
  add(query_604974, "parameters.1.value", newJString(parameters1Value))
  result = call_604973.call(nil, query_604974, nil, nil, body_604975)

var importRestApi* = Call_ImportRestApi_604953(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_604954,
    base: "/", url: url_ImportRestApi_604955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604976 = ref object of OpenApiRestCall_602450
proc url_UntagResource_604978(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_604977(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604979 = path.getOrDefault("resource_arn")
  valid_604979 = validateParameter(valid_604979, JString, required = true,
                                 default = nil)
  if valid_604979 != nil:
    section.add "resource_arn", valid_604979
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_604980 = query.getOrDefault("tagKeys")
  valid_604980 = validateParameter(valid_604980, JArray, required = true, default = nil)
  if valid_604980 != nil:
    section.add "tagKeys", valid_604980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604981 = header.getOrDefault("X-Amz-Date")
  valid_604981 = validateParameter(valid_604981, JString, required = false,
                                 default = nil)
  if valid_604981 != nil:
    section.add "X-Amz-Date", valid_604981
  var valid_604982 = header.getOrDefault("X-Amz-Security-Token")
  valid_604982 = validateParameter(valid_604982, JString, required = false,
                                 default = nil)
  if valid_604982 != nil:
    section.add "X-Amz-Security-Token", valid_604982
  var valid_604983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604983 = validateParameter(valid_604983, JString, required = false,
                                 default = nil)
  if valid_604983 != nil:
    section.add "X-Amz-Content-Sha256", valid_604983
  var valid_604984 = header.getOrDefault("X-Amz-Algorithm")
  valid_604984 = validateParameter(valid_604984, JString, required = false,
                                 default = nil)
  if valid_604984 != nil:
    section.add "X-Amz-Algorithm", valid_604984
  var valid_604985 = header.getOrDefault("X-Amz-Signature")
  valid_604985 = validateParameter(valid_604985, JString, required = false,
                                 default = nil)
  if valid_604985 != nil:
    section.add "X-Amz-Signature", valid_604985
  var valid_604986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604986 = validateParameter(valid_604986, JString, required = false,
                                 default = nil)
  if valid_604986 != nil:
    section.add "X-Amz-SignedHeaders", valid_604986
  var valid_604987 = header.getOrDefault("X-Amz-Credential")
  valid_604987 = validateParameter(valid_604987, JString, required = false,
                                 default = nil)
  if valid_604987 != nil:
    section.add "X-Amz-Credential", valid_604987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604988: Call_UntagResource_604976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_604988.validator(path, query, header, formData, body)
  let scheme = call_604988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604988.url(scheme.get, call_604988.host, call_604988.base,
                         call_604988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604988, url, valid)

proc call*(call_604989: Call_UntagResource_604976; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_604990 = newJObject()
  var query_604991 = newJObject()
  add(path_604990, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_604991.add "tagKeys", tagKeys
  result = call_604989.call(path_604990, query_604991, nil, nil, nil)

var untagResource* = Call_UntagResource_604976(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_604977,
    base: "/", url: url_UntagResource_604978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_604992 = ref object of OpenApiRestCall_602450
proc url_UpdateUsage_604994(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_604993(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604995 = path.getOrDefault("keyId")
  valid_604995 = validateParameter(valid_604995, JString, required = true,
                                 default = nil)
  if valid_604995 != nil:
    section.add "keyId", valid_604995
  var valid_604996 = path.getOrDefault("usageplanId")
  valid_604996 = validateParameter(valid_604996, JString, required = true,
                                 default = nil)
  if valid_604996 != nil:
    section.add "usageplanId", valid_604996
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604997 = header.getOrDefault("X-Amz-Date")
  valid_604997 = validateParameter(valid_604997, JString, required = false,
                                 default = nil)
  if valid_604997 != nil:
    section.add "X-Amz-Date", valid_604997
  var valid_604998 = header.getOrDefault("X-Amz-Security-Token")
  valid_604998 = validateParameter(valid_604998, JString, required = false,
                                 default = nil)
  if valid_604998 != nil:
    section.add "X-Amz-Security-Token", valid_604998
  var valid_604999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604999 = validateParameter(valid_604999, JString, required = false,
                                 default = nil)
  if valid_604999 != nil:
    section.add "X-Amz-Content-Sha256", valid_604999
  var valid_605000 = header.getOrDefault("X-Amz-Algorithm")
  valid_605000 = validateParameter(valid_605000, JString, required = false,
                                 default = nil)
  if valid_605000 != nil:
    section.add "X-Amz-Algorithm", valid_605000
  var valid_605001 = header.getOrDefault("X-Amz-Signature")
  valid_605001 = validateParameter(valid_605001, JString, required = false,
                                 default = nil)
  if valid_605001 != nil:
    section.add "X-Amz-Signature", valid_605001
  var valid_605002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605002 = validateParameter(valid_605002, JString, required = false,
                                 default = nil)
  if valid_605002 != nil:
    section.add "X-Amz-SignedHeaders", valid_605002
  var valid_605003 = header.getOrDefault("X-Amz-Credential")
  valid_605003 = validateParameter(valid_605003, JString, required = false,
                                 default = nil)
  if valid_605003 != nil:
    section.add "X-Amz-Credential", valid_605003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605005: Call_UpdateUsage_604992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_605005.validator(path, query, header, formData, body)
  let scheme = call_605005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605005.url(scheme.get, call_605005.host, call_605005.base,
                         call_605005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605005, url, valid)

proc call*(call_605006: Call_UpdateUsage_604992; keyId: string; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_605007 = newJObject()
  var body_605008 = newJObject()
  add(path_605007, "keyId", newJString(keyId))
  add(path_605007, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_605008 = body
  result = call_605006.call(path_605007, nil, nil, nil, body_605008)

var updateUsage* = Call_UpdateUsage_604992(name: "updateUsage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
                                        validator: validate_UpdateUsage_604993,
                                        base: "/", url: url_UpdateUsage_604994,
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
