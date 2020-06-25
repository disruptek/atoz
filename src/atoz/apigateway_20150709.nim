
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateApiKey_21626005 = ref object of OpenApiRestCall_21625418
proc url_CreateApiKey_21626007(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApiKey_21626006(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626008 = header.getOrDefault("X-Amz-Date")
  valid_21626008 = validateParameter(valid_21626008, JString, required = false,
                                   default = nil)
  if valid_21626008 != nil:
    section.add "X-Amz-Date", valid_21626008
  var valid_21626009 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Security-Token", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Algorithm", valid_21626011
  var valid_21626012 = header.getOrDefault("X-Amz-Signature")
  valid_21626012 = validateParameter(valid_21626012, JString, required = false,
                                   default = nil)
  if valid_21626012 != nil:
    section.add "X-Amz-Signature", valid_21626012
  var valid_21626013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Credential")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Credential", valid_21626014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626016: Call_CreateApiKey_21626005; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ## 
  let valid = call_21626016.validator(path, query, header, formData, body, _)
  let scheme = call_21626016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626016.makeUrl(scheme.get, call_21626016.host, call_21626016.base,
                               call_21626016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626016, uri, valid, _)

proc call*(call_21626017: Call_CreateApiKey_21626005; body: JsonNode): Recallable =
  ## createApiKey
  ## <p>Create an <a>ApiKey</a> resource. </p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-api-key.html">AWS CLI</a></div>
  ##   body: JObject (required)
  var body_21626018 = newJObject()
  if body != nil:
    body_21626018 = body
  result = call_21626017.call(nil, nil, nil, nil, body_21626018)

var createApiKey* = Call_CreateApiKey_21626005(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/apikeys",
    validator: validate_CreateApiKey_21626006, base: "/", makeUrl: url_CreateApiKey_21626007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKeys_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetApiKeys_21625764(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApiKeys_21625763(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625865 = query.getOrDefault("customerId")
  valid_21625865 = validateParameter(valid_21625865, JString, required = false,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "customerId", valid_21625865
  var valid_21625866 = query.getOrDefault("includeValues")
  valid_21625866 = validateParameter(valid_21625866, JBool, required = false,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "includeValues", valid_21625866
  var valid_21625867 = query.getOrDefault("name")
  valid_21625867 = validateParameter(valid_21625867, JString, required = false,
                                   default = nil)
  if valid_21625867 != nil:
    section.add "name", valid_21625867
  var valid_21625868 = query.getOrDefault("position")
  valid_21625868 = validateParameter(valid_21625868, JString, required = false,
                                   default = nil)
  if valid_21625868 != nil:
    section.add "position", valid_21625868
  var valid_21625869 = query.getOrDefault("limit")
  valid_21625869 = validateParameter(valid_21625869, JInt, required = false,
                                   default = nil)
  if valid_21625869 != nil:
    section.add "limit", valid_21625869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625870 = header.getOrDefault("X-Amz-Date")
  valid_21625870 = validateParameter(valid_21625870, JString, required = false,
                                   default = nil)
  if valid_21625870 != nil:
    section.add "X-Amz-Date", valid_21625870
  var valid_21625871 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625871 = validateParameter(valid_21625871, JString, required = false,
                                   default = nil)
  if valid_21625871 != nil:
    section.add "X-Amz-Security-Token", valid_21625871
  var valid_21625872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625872 = validateParameter(valid_21625872, JString, required = false,
                                   default = nil)
  if valid_21625872 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625872
  var valid_21625873 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Algorithm", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Signature")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Signature", valid_21625874
  var valid_21625875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625875
  var valid_21625876 = header.getOrDefault("X-Amz-Credential")
  valid_21625876 = validateParameter(valid_21625876, JString, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Credential", valid_21625876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625901: Call_GetApiKeys_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the current <a>ApiKeys</a> resource.
  ## 
  let valid = call_21625901.validator(path, query, header, formData, body, _)
  let scheme = call_21625901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625901.makeUrl(scheme.get, call_21625901.host, call_21625901.base,
                               call_21625901.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625901, uri, valid, _)

proc call*(call_21625964: Call_GetApiKeys_21625762; customerId: string = "";
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
  var query_21625966 = newJObject()
  add(query_21625966, "customerId", newJString(customerId))
  add(query_21625966, "includeValues", newJBool(includeValues))
  add(query_21625966, "name", newJString(name))
  add(query_21625966, "position", newJString(position))
  add(query_21625966, "limit", newJInt(limit))
  result = call_21625964.call(nil, query_21625966, nil, nil, nil)

var getApiKeys* = Call_GetApiKeys_21625762(name: "getApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/apikeys",
                                        validator: validate_GetApiKeys_21625763,
                                        base: "/", makeUrl: url_GetApiKeys_21625764,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_21626049 = ref object of OpenApiRestCall_21625418
proc url_CreateAuthorizer_21626051(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_21626050(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626052 = path.getOrDefault("restapi_id")
  valid_21626052 = validateParameter(valid_21626052, JString, required = true,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "restapi_id", valid_21626052
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626053 = header.getOrDefault("X-Amz-Date")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Date", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Security-Token", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Algorithm", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Signature")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Signature", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Credential")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Credential", valid_21626059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626061: Call_CreateAuthorizer_21626049; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_CreateAuthorizer_21626049; body: JsonNode;
          restapiId: string): Recallable =
  ## createAuthorizer
  ## <p>Adds a new <a>Authorizer</a> resource to an existing <a>RestApi</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-authorizer.html">AWS CLI</a></div>
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626063 = newJObject()
  var body_21626064 = newJObject()
  if body != nil:
    body_21626064 = body
  add(path_21626063, "restapi_id", newJString(restapiId))
  result = call_21626062.call(path_21626063, nil, nil, nil, body_21626064)

var createAuthorizer* = Call_CreateAuthorizer_21626049(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_CreateAuthorizer_21626050, base: "/",
    makeUrl: url_CreateAuthorizer_21626051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_21626019 = ref object of OpenApiRestCall_21625418
proc url_GetAuthorizers_21626021(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_21626020(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626035 = path.getOrDefault("restapi_id")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "restapi_id", valid_21626035
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626036 = query.getOrDefault("position")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "position", valid_21626036
  var valid_21626037 = query.getOrDefault("limit")
  valid_21626037 = validateParameter(valid_21626037, JInt, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "limit", valid_21626037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_GetAuthorizers_21626019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_GetAuthorizers_21626019; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getAuthorizers
  ## <p>Describe an existing <a>Authorizers</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizers.html">AWS CLI</a></div>
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626047 = newJObject()
  var query_21626048 = newJObject()
  add(query_21626048, "position", newJString(position))
  add(query_21626048, "limit", newJInt(limit))
  add(path_21626047, "restapi_id", newJString(restapiId))
  result = call_21626046.call(path_21626047, query_21626048, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_21626019(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers",
    validator: validate_GetAuthorizers_21626020, base: "/",
    makeUrl: url_GetAuthorizers_21626021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBasePathMapping_21626082 = ref object of OpenApiRestCall_21625418
proc url_CreateBasePathMapping_21626084(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_CreateBasePathMapping_21626083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626085 = path.getOrDefault("domain_name")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "domain_name", valid_21626085
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626094: Call_CreateBasePathMapping_21626082;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new <a>BasePathMapping</a> resource.
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_CreateBasePathMapping_21626082; domainName: string;
          body: JsonNode): Recallable =
  ## createBasePathMapping
  ## Creates a new <a>BasePathMapping</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to create.
  ##   body: JObject (required)
  var path_21626096 = newJObject()
  var body_21626097 = newJObject()
  add(path_21626096, "domain_name", newJString(domainName))
  if body != nil:
    body_21626097 = body
  result = call_21626095.call(path_21626096, nil, nil, nil, body_21626097)

var createBasePathMapping* = Call_CreateBasePathMapping_21626082(
    name: "createBasePathMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_CreateBasePathMapping_21626083, base: "/",
    makeUrl: url_CreateBasePathMapping_21626084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMappings_21626065 = ref object of OpenApiRestCall_21625418
proc url_GetBasePathMappings_21626067(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMappings_21626066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626068 = path.getOrDefault("domain_name")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "domain_name", valid_21626068
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626069 = query.getOrDefault("position")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "position", valid_21626069
  var valid_21626070 = query.getOrDefault("limit")
  valid_21626070 = validateParameter(valid_21626070, JInt, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "limit", valid_21626070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626078: Call_GetBasePathMappings_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ## 
  let valid = call_21626078.validator(path, query, header, formData, body, _)
  let scheme = call_21626078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626078.makeUrl(scheme.get, call_21626078.host, call_21626078.base,
                               call_21626078.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626078, uri, valid, _)

proc call*(call_21626079: Call_GetBasePathMappings_21626065; domainName: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getBasePathMappings
  ## Represents a collection of <a>BasePathMapping</a> resources.
  ##   domainName: string (required)
  ##             : [Required] The domain name of a <a>BasePathMapping</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_21626080 = newJObject()
  var query_21626081 = newJObject()
  add(path_21626080, "domain_name", newJString(domainName))
  add(query_21626081, "position", newJString(position))
  add(query_21626081, "limit", newJInt(limit))
  result = call_21626079.call(path_21626080, query_21626081, nil, nil, nil)

var getBasePathMappings* = Call_GetBasePathMappings_21626065(
    name: "getBasePathMappings", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings",
    validator: validate_GetBasePathMappings_21626066, base: "/",
    makeUrl: url_GetBasePathMappings_21626067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_21626115 = ref object of OpenApiRestCall_21625418
proc url_CreateDeployment_21626117(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_21626116(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626118 = path.getOrDefault("restapi_id")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "restapi_id", valid_21626118
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626119 = header.getOrDefault("X-Amz-Date")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Date", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Security-Token", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Algorithm", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Signature")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Signature", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Credential")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Credential", valid_21626125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626127: Call_CreateDeployment_21626115; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ## 
  let valid = call_21626127.validator(path, query, header, formData, body, _)
  let scheme = call_21626127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626127.makeUrl(scheme.get, call_21626127.host, call_21626127.base,
                               call_21626127.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626127, uri, valid, _)

proc call*(call_21626128: Call_CreateDeployment_21626115; body: JsonNode;
          restapiId: string): Recallable =
  ## createDeployment
  ## Creates a <a>Deployment</a> resource, which makes a specified <a>RestApi</a> callable over the internet.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626129 = newJObject()
  var body_21626130 = newJObject()
  if body != nil:
    body_21626130 = body
  add(path_21626129, "restapi_id", newJString(restapiId))
  result = call_21626128.call(path_21626129, nil, nil, nil, body_21626130)

var createDeployment* = Call_CreateDeployment_21626115(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_CreateDeployment_21626116, base: "/",
    makeUrl: url_CreateDeployment_21626117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_21626098 = ref object of OpenApiRestCall_21625418
proc url_GetDeployments_21626100(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_21626099(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626101 = path.getOrDefault("restapi_id")
  valid_21626101 = validateParameter(valid_21626101, JString, required = true,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "restapi_id", valid_21626101
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626102 = query.getOrDefault("position")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "position", valid_21626102
  var valid_21626103 = query.getOrDefault("limit")
  valid_21626103 = validateParameter(valid_21626103, JInt, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "limit", valid_21626103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626104 = header.getOrDefault("X-Amz-Date")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Date", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Security-Token", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Algorithm", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Signature")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Signature", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Credential")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Credential", valid_21626110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626111: Call_GetDeployments_21626098; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a <a>Deployments</a> collection.
  ## 
  let valid = call_21626111.validator(path, query, header, formData, body, _)
  let scheme = call_21626111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626111.makeUrl(scheme.get, call_21626111.host, call_21626111.base,
                               call_21626111.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626111, uri, valid, _)

proc call*(call_21626112: Call_GetDeployments_21626098; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getDeployments
  ## Gets information about a <a>Deployments</a> collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626113 = newJObject()
  var query_21626114 = newJObject()
  add(query_21626114, "position", newJString(position))
  add(query_21626114, "limit", newJInt(limit))
  add(path_21626113, "restapi_id", newJString(restapiId))
  result = call_21626112.call(path_21626113, query_21626114, nil, nil, nil)

var getDeployments* = Call_GetDeployments_21626098(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments",
    validator: validate_GetDeployments_21626099, base: "/",
    makeUrl: url_GetDeployments_21626100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportDocumentationParts_21626167 = ref object of OpenApiRestCall_21625418
proc url_ImportDocumentationParts_21626169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ImportDocumentationParts_21626168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_21626170 = path.getOrDefault("restapi_id")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "restapi_id", valid_21626170
  result.add "path", section
  ## parameters in `query` object:
  ##   mode: JString
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: JBool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  section = newJObject()
  var valid_21626171 = query.getOrDefault("mode")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = newJString("merge"))
  if valid_21626171 != nil:
    section.add "mode", valid_21626171
  var valid_21626172 = query.getOrDefault("failonwarnings")
  valid_21626172 = validateParameter(valid_21626172, JBool, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "failonwarnings", valid_21626172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626173 = header.getOrDefault("X-Amz-Date")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Date", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Security-Token", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Algorithm", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Signature")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Signature", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Credential")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Credential", valid_21626179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626181: Call_ImportDocumentationParts_21626167;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626181.validator(path, query, header, formData, body, _)
  let scheme = call_21626181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626181.makeUrl(scheme.get, call_21626181.host, call_21626181.base,
                               call_21626181.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626181, uri, valid, _)

proc call*(call_21626182: Call_ImportDocumentationParts_21626167; body: JsonNode;
          restapiId: string; mode: string = "merge"; failonwarnings: bool = false): Recallable =
  ## importDocumentationParts
  ##   mode: string
  ##       : A query parameter to indicate whether to overwrite (<code>OVERWRITE</code>) any existing <a>DocumentationParts</a> definition or to merge (<code>MERGE</code>) the new definition into the existing one. The default value is <code>MERGE</code>.
  ##   failonwarnings: bool
  ##                 : A query parameter to specify whether to rollback the documentation importation (<code>true</code>) or not (<code>false</code>) when a warning is encountered. The default value is <code>false</code>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626183 = newJObject()
  var query_21626184 = newJObject()
  var body_21626185 = newJObject()
  add(query_21626184, "mode", newJString(mode))
  add(query_21626184, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_21626185 = body
  add(path_21626183, "restapi_id", newJString(restapiId))
  result = call_21626182.call(path_21626183, query_21626184, nil, nil, body_21626185)

var importDocumentationParts* = Call_ImportDocumentationParts_21626167(
    name: "importDocumentationParts", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_ImportDocumentationParts_21626168, base: "/",
    makeUrl: url_ImportDocumentationParts_21626169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationPart_21626186 = ref object of OpenApiRestCall_21625418
proc url_CreateDocumentationPart_21626188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateDocumentationPart_21626187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_21626189 = path.getOrDefault("restapi_id")
  valid_21626189 = validateParameter(valid_21626189, JString, required = true,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "restapi_id", valid_21626189
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626190 = header.getOrDefault("X-Amz-Date")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Date", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Security-Token", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Algorithm", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Signature")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Signature", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Credential")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Credential", valid_21626196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_CreateDocumentationPart_21626186;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_CreateDocumentationPart_21626186; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationPart
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626200 = newJObject()
  var body_21626201 = newJObject()
  if body != nil:
    body_21626201 = body
  add(path_21626200, "restapi_id", newJString(restapiId))
  result = call_21626199.call(path_21626200, nil, nil, nil, body_21626201)

var createDocumentationPart* = Call_CreateDocumentationPart_21626186(
    name: "createDocumentationPart", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_CreateDocumentationPart_21626187, base: "/",
    makeUrl: url_CreateDocumentationPart_21626188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationParts_21626131 = ref object of OpenApiRestCall_21625418
proc url_GetDocumentationParts_21626133(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationParts_21626132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_21626134 = path.getOrDefault("restapi_id")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "restapi_id", valid_21626134
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
  var valid_21626149 = query.getOrDefault("type")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = newJString("API"))
  if valid_21626149 != nil:
    section.add "type", valid_21626149
  var valid_21626150 = query.getOrDefault("path")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "path", valid_21626150
  var valid_21626151 = query.getOrDefault("locationStatus")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = newJString("DOCUMENTED"))
  if valid_21626151 != nil:
    section.add "locationStatus", valid_21626151
  var valid_21626152 = query.getOrDefault("name")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "name", valid_21626152
  var valid_21626153 = query.getOrDefault("position")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "position", valid_21626153
  var valid_21626154 = query.getOrDefault("limit")
  valid_21626154 = validateParameter(valid_21626154, JInt, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "limit", valid_21626154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626155 = header.getOrDefault("X-Amz-Date")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Date", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Security-Token", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626162: Call_GetDocumentationParts_21626131;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626162.validator(path, query, header, formData, body, _)
  let scheme = call_21626162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626162.makeUrl(scheme.get, call_21626162.host, call_21626162.base,
                               call_21626162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626162, uri, valid, _)

proc call*(call_21626163: Call_GetDocumentationParts_21626131; restapiId: string;
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
  var path_21626164 = newJObject()
  var query_21626165 = newJObject()
  add(query_21626165, "type", newJString(`type`))
  add(query_21626165, "path", newJString(path))
  add(query_21626165, "locationStatus", newJString(locationStatus))
  add(query_21626165, "name", newJString(name))
  add(query_21626165, "position", newJString(position))
  add(query_21626165, "limit", newJInt(limit))
  add(path_21626164, "restapi_id", newJString(restapiId))
  result = call_21626163.call(path_21626164, query_21626165, nil, nil, nil)

var getDocumentationParts* = Call_GetDocumentationParts_21626131(
    name: "getDocumentationParts", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts",
    validator: validate_GetDocumentationParts_21626132, base: "/",
    makeUrl: url_GetDocumentationParts_21626133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocumentationVersion_21626219 = ref object of OpenApiRestCall_21625418
proc url_CreateDocumentationVersion_21626221(protocol: Scheme; host: string;
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

proc validate_CreateDocumentationVersion_21626220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_21626222 = path.getOrDefault("restapi_id")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "restapi_id", valid_21626222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626223 = header.getOrDefault("X-Amz-Date")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Date", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Security-Token", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Algorithm", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Signature")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Signature", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Credential")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Credential", valid_21626229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626231: Call_CreateDocumentationVersion_21626219;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626231.validator(path, query, header, formData, body, _)
  let scheme = call_21626231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626231.makeUrl(scheme.get, call_21626231.host, call_21626231.base,
                               call_21626231.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626231, uri, valid, _)

proc call*(call_21626232: Call_CreateDocumentationVersion_21626219; body: JsonNode;
          restapiId: string): Recallable =
  ## createDocumentationVersion
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626233 = newJObject()
  var body_21626234 = newJObject()
  if body != nil:
    body_21626234 = body
  add(path_21626233, "restapi_id", newJString(restapiId))
  result = call_21626232.call(path_21626233, nil, nil, nil, body_21626234)

var createDocumentationVersion* = Call_CreateDocumentationVersion_21626219(
    name: "createDocumentationVersion", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_CreateDocumentationVersion_21626220, base: "/",
    makeUrl: url_CreateDocumentationVersion_21626221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersions_21626202 = ref object of OpenApiRestCall_21625418
proc url_GetDocumentationVersions_21626204(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersions_21626203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restapi_id` field"
  var valid_21626205 = path.getOrDefault("restapi_id")
  valid_21626205 = validateParameter(valid_21626205, JString, required = true,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "restapi_id", valid_21626205
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626206 = query.getOrDefault("position")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "position", valid_21626206
  var valid_21626207 = query.getOrDefault("limit")
  valid_21626207 = validateParameter(valid_21626207, JInt, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "limit", valid_21626207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626208 = header.getOrDefault("X-Amz-Date")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Date", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Security-Token", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626215: Call_GetDocumentationVersions_21626202;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626215.validator(path, query, header, formData, body, _)
  let scheme = call_21626215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626215.makeUrl(scheme.get, call_21626215.host, call_21626215.base,
                               call_21626215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626215, uri, valid, _)

proc call*(call_21626216: Call_GetDocumentationVersions_21626202;
          restapiId: string; position: string = ""; limit: int = 0): Recallable =
  ## getDocumentationVersions
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626217 = newJObject()
  var query_21626218 = newJObject()
  add(query_21626218, "position", newJString(position))
  add(query_21626218, "limit", newJInt(limit))
  add(path_21626217, "restapi_id", newJString(restapiId))
  result = call_21626216.call(path_21626217, query_21626218, nil, nil, nil)

var getDocumentationVersions* = Call_GetDocumentationVersions_21626202(
    name: "getDocumentationVersions", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions",
    validator: validate_GetDocumentationVersions_21626203, base: "/",
    makeUrl: url_GetDocumentationVersions_21626204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_21626250 = ref object of OpenApiRestCall_21625418
proc url_CreateDomainName_21626252(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_21626251(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626253 = header.getOrDefault("X-Amz-Date")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Date", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Security-Token", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Algorithm", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Signature")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Signature", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Credential")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Credential", valid_21626259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626261: Call_CreateDomainName_21626250; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new domain name.
  ## 
  let valid = call_21626261.validator(path, query, header, formData, body, _)
  let scheme = call_21626261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626261.makeUrl(scheme.get, call_21626261.host, call_21626261.base,
                               call_21626261.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626261, uri, valid, _)

proc call*(call_21626262: Call_CreateDomainName_21626250; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a new domain name.
  ##   body: JObject (required)
  var body_21626263 = newJObject()
  if body != nil:
    body_21626263 = body
  result = call_21626262.call(nil, nil, nil, nil, body_21626263)

var createDomainName* = Call_CreateDomainName_21626250(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_CreateDomainName_21626251, base: "/",
    makeUrl: url_CreateDomainName_21626252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_21626235 = ref object of OpenApiRestCall_21625418
proc url_GetDomainNames_21626237(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_21626236(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626238 = query.getOrDefault("position")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "position", valid_21626238
  var valid_21626239 = query.getOrDefault("limit")
  valid_21626239 = validateParameter(valid_21626239, JInt, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "limit", valid_21626239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626240 = header.getOrDefault("X-Amz-Date")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Date", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Security-Token", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Algorithm", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Signature")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Signature", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Credential")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Credential", valid_21626246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626247: Call_GetDomainNames_21626235; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a collection of <a>DomainName</a> resources.
  ## 
  let valid = call_21626247.validator(path, query, header, formData, body, _)
  let scheme = call_21626247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626247.makeUrl(scheme.get, call_21626247.host, call_21626247.base,
                               call_21626247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626247, uri, valid, _)

proc call*(call_21626248: Call_GetDomainNames_21626235; position: string = "";
          limit: int = 0): Recallable =
  ## getDomainNames
  ## Represents a collection of <a>DomainName</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21626249 = newJObject()
  add(query_21626249, "position", newJString(position))
  add(query_21626249, "limit", newJInt(limit))
  result = call_21626248.call(nil, query_21626249, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_21626235(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames", validator: validate_GetDomainNames_21626236, base: "/",
    makeUrl: url_GetDomainNames_21626237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_21626281 = ref object of OpenApiRestCall_21625418
proc url_CreateModel_21626283(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_21626282(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626284 = path.getOrDefault("restapi_id")
  valid_21626284 = validateParameter(valid_21626284, JString, required = true,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "restapi_id", valid_21626284
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626285 = header.getOrDefault("X-Amz-Date")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Date", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Security-Token", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Algorithm", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Signature")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Signature", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Credential")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Credential", valid_21626291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626293: Call_CreateModel_21626281; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ## 
  let valid = call_21626293.validator(path, query, header, formData, body, _)
  let scheme = call_21626293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626293.makeUrl(scheme.get, call_21626293.host, call_21626293.base,
                               call_21626293.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626293, uri, valid, _)

proc call*(call_21626294: Call_CreateModel_21626281; body: JsonNode;
          restapiId: string): Recallable =
  ## createModel
  ## Adds a new <a>Model</a> resource to an existing <a>RestApi</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> will be created.
  var path_21626295 = newJObject()
  var body_21626296 = newJObject()
  if body != nil:
    body_21626296 = body
  add(path_21626295, "restapi_id", newJString(restapiId))
  result = call_21626294.call(path_21626295, nil, nil, nil, body_21626296)

var createModel* = Call_CreateModel_21626281(name: "createModel",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models", validator: validate_CreateModel_21626282,
    base: "/", makeUrl: url_CreateModel_21626283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_21626264 = ref object of OpenApiRestCall_21625418
proc url_GetModels_21626266(protocol: Scheme; host: string; base: string;
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

proc validate_GetModels_21626265(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626267 = path.getOrDefault("restapi_id")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "restapi_id", valid_21626267
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626268 = query.getOrDefault("position")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "position", valid_21626268
  var valid_21626269 = query.getOrDefault("limit")
  valid_21626269 = validateParameter(valid_21626269, JInt, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "limit", valid_21626269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626270 = header.getOrDefault("X-Amz-Date")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Date", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Security-Token", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Algorithm", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Signature")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Signature", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Credential")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Credential", valid_21626276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626277: Call_GetModels_21626264; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_21626277.validator(path, query, header, formData, body, _)
  let scheme = call_21626277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626277.makeUrl(scheme.get, call_21626277.host, call_21626277.base,
                               call_21626277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626277, uri, valid, _)

proc call*(call_21626278: Call_GetModels_21626264; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getModels
  ## Describes existing <a>Models</a> defined for a <a>RestApi</a> resource.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626279 = newJObject()
  var query_21626280 = newJObject()
  add(query_21626280, "position", newJString(position))
  add(query_21626280, "limit", newJInt(limit))
  add(path_21626279, "restapi_id", newJString(restapiId))
  result = call_21626278.call(path_21626279, query_21626280, nil, nil, nil)

var getModels* = Call_GetModels_21626264(name: "getModels", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}/models",
                                      validator: validate_GetModels_21626265,
                                      base: "/", makeUrl: url_GetModels_21626266,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRequestValidator_21626314 = ref object of OpenApiRestCall_21625418
proc url_CreateRequestValidator_21626316(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/requestvalidators")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRequestValidator_21626315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626317 = path.getOrDefault("restapi_id")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "restapi_id", valid_21626317
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626318 = header.getOrDefault("X-Amz-Date")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Date", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Security-Token", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_CreateRequestValidator_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_CreateRequestValidator_21626314; body: JsonNode;
          restapiId: string): Recallable =
  ## createRequestValidator
  ## Creates a <a>ReqeustValidator</a> of a given <a>RestApi</a>.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626328 = newJObject()
  var body_21626329 = newJObject()
  if body != nil:
    body_21626329 = body
  add(path_21626328, "restapi_id", newJString(restapiId))
  result = call_21626327.call(path_21626328, nil, nil, nil, body_21626329)

var createRequestValidator* = Call_CreateRequestValidator_21626314(
    name: "createRequestValidator", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_CreateRequestValidator_21626315, base: "/",
    makeUrl: url_CreateRequestValidator_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidators_21626297 = ref object of OpenApiRestCall_21625418
proc url_GetRequestValidators_21626299(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidators_21626298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626300 = path.getOrDefault("restapi_id")
  valid_21626300 = validateParameter(valid_21626300, JString, required = true,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "restapi_id", valid_21626300
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626301 = query.getOrDefault("position")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "position", valid_21626301
  var valid_21626302 = query.getOrDefault("limit")
  valid_21626302 = validateParameter(valid_21626302, JInt, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "limit", valid_21626302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626310: Call_GetRequestValidators_21626297; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ## 
  let valid = call_21626310.validator(path, query, header, formData, body, _)
  let scheme = call_21626310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626310.makeUrl(scheme.get, call_21626310.host, call_21626310.base,
                               call_21626310.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626310, uri, valid, _)

proc call*(call_21626311: Call_GetRequestValidators_21626297; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getRequestValidators
  ## Gets the <a>RequestValidators</a> collection of a given <a>RestApi</a>.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626312 = newJObject()
  var query_21626313 = newJObject()
  add(query_21626313, "position", newJString(position))
  add(query_21626313, "limit", newJInt(limit))
  add(path_21626312, "restapi_id", newJString(restapiId))
  result = call_21626311.call(path_21626312, query_21626313, nil, nil, nil)

var getRequestValidators* = Call_GetRequestValidators_21626297(
    name: "getRequestValidators", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators",
    validator: validate_GetRequestValidators_21626298, base: "/",
    makeUrl: url_GetRequestValidators_21626299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_21626330 = ref object of OpenApiRestCall_21625418
proc url_CreateResource_21626332(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResource_21626331(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626333 = path.getOrDefault("parent_id")
  valid_21626333 = validateParameter(valid_21626333, JString, required = true,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "parent_id", valid_21626333
  var valid_21626334 = path.getOrDefault("restapi_id")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "restapi_id", valid_21626334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626335 = header.getOrDefault("X-Amz-Date")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Date", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Security-Token", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626343: Call_CreateResource_21626330; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <a>Resource</a> resource.
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_CreateResource_21626330; parentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## createResource
  ## Creates a <a>Resource</a> resource.
  ##   parentId: string (required)
  ##           : [Required] The parent resource's identifier.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626345 = newJObject()
  var body_21626346 = newJObject()
  add(path_21626345, "parent_id", newJString(parentId))
  if body != nil:
    body_21626346 = body
  add(path_21626345, "restapi_id", newJString(restapiId))
  result = call_21626344.call(path_21626345, nil, nil, nil, body_21626346)

var createResource* = Call_CreateResource_21626330(name: "createResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{parent_id}",
    validator: validate_CreateResource_21626331, base: "/",
    makeUrl: url_CreateResource_21626332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRestApi_21626362 = ref object of OpenApiRestCall_21625418
proc url_CreateRestApi_21626364(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRestApi_21626363(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626365 = header.getOrDefault("X-Amz-Date")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Date", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Security-Token", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626373: Call_CreateRestApi_21626362; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new <a>RestApi</a> resource.
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_CreateRestApi_21626362; body: JsonNode): Recallable =
  ## createRestApi
  ## Creates a new <a>RestApi</a> resource.
  ##   body: JObject (required)
  var body_21626375 = newJObject()
  if body != nil:
    body_21626375 = body
  result = call_21626374.call(nil, nil, nil, nil, body_21626375)

var createRestApi* = Call_CreateRestApi_21626362(name: "createRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_CreateRestApi_21626363, base: "/",
    makeUrl: url_CreateRestApi_21626364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApis_21626347 = ref object of OpenApiRestCall_21625418
proc url_GetRestApis_21626349(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestApis_21626348(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626350 = query.getOrDefault("position")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "position", valid_21626350
  var valid_21626351 = query.getOrDefault("limit")
  valid_21626351 = validateParameter(valid_21626351, JInt, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "limit", valid_21626351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626352 = header.getOrDefault("X-Amz-Date")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Date", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Security-Token", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Algorithm", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Signature")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Signature", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Credential")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Credential", valid_21626358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626359: Call_GetRestApis_21626347; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the <a>RestApis</a> resources for your collection.
  ## 
  let valid = call_21626359.validator(path, query, header, formData, body, _)
  let scheme = call_21626359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626359.makeUrl(scheme.get, call_21626359.host, call_21626359.base,
                               call_21626359.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626359, uri, valid, _)

proc call*(call_21626360: Call_GetRestApis_21626347; position: string = "";
          limit: int = 0): Recallable =
  ## getRestApis
  ## Lists the <a>RestApis</a> resources for your collection.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21626361 = newJObject()
  add(query_21626361, "position", newJString(position))
  add(query_21626361, "limit", newJInt(limit))
  result = call_21626360.call(nil, query_21626361, nil, nil, nil)

var getRestApis* = Call_GetRestApis_21626347(name: "getRestApis",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis",
    validator: validate_GetRestApis_21626348, base: "/", makeUrl: url_GetRestApis_21626349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_21626392 = ref object of OpenApiRestCall_21625418
proc url_CreateStage_21626394(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_21626393(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626395 = path.getOrDefault("restapi_id")
  valid_21626395 = validateParameter(valid_21626395, JString, required = true,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "restapi_id", valid_21626395
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626396 = header.getOrDefault("X-Amz-Date")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Date", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Security-Token", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Algorithm", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Signature")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Signature", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Credential")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Credential", valid_21626402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626404: Call_CreateStage_21626392; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ## 
  let valid = call_21626404.validator(path, query, header, formData, body, _)
  let scheme = call_21626404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626404.makeUrl(scheme.get, call_21626404.host, call_21626404.base,
                               call_21626404.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626404, uri, valid, _)

proc call*(call_21626405: Call_CreateStage_21626392; body: JsonNode;
          restapiId: string): Recallable =
  ## createStage
  ## Creates a new <a>Stage</a> resource that references a pre-existing <a>Deployment</a> for the API. 
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626406 = newJObject()
  var body_21626407 = newJObject()
  if body != nil:
    body_21626407 = body
  add(path_21626406, "restapi_id", newJString(restapiId))
  result = call_21626405.call(path_21626406, nil, nil, nil, body_21626407)

var createStage* = Call_CreateStage_21626392(name: "createStage",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages", validator: validate_CreateStage_21626393,
    base: "/", makeUrl: url_CreateStage_21626394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_21626376 = ref object of OpenApiRestCall_21625418
proc url_GetStages_21626378(protocol: Scheme; host: string; base: string;
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

proc validate_GetStages_21626377(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626379 = path.getOrDefault("restapi_id")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "restapi_id", valid_21626379
  result.add "path", section
  ## parameters in `query` object:
  ##   deploymentId: JString
  ##               : The stages' deployment identifiers.
  section = newJObject()
  var valid_21626380 = query.getOrDefault("deploymentId")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "deploymentId", valid_21626380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626381 = header.getOrDefault("X-Amz-Date")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Date", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Security-Token", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Algorithm", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Signature")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Signature", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Credential")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Credential", valid_21626387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626388: Call_GetStages_21626376; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more <a>Stage</a> resources.
  ## 
  let valid = call_21626388.validator(path, query, header, formData, body, _)
  let scheme = call_21626388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626388.makeUrl(scheme.get, call_21626388.host, call_21626388.base,
                               call_21626388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626388, uri, valid, _)

proc call*(call_21626389: Call_GetStages_21626376; restapiId: string;
          deploymentId: string = ""): Recallable =
  ## getStages
  ## Gets information about one or more <a>Stage</a> resources.
  ##   deploymentId: string
  ##               : The stages' deployment identifiers.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626390 = newJObject()
  var query_21626391 = newJObject()
  add(query_21626391, "deploymentId", newJString(deploymentId))
  add(path_21626390, "restapi_id", newJString(restapiId))
  result = call_21626389.call(path_21626390, query_21626391, nil, nil, nil)

var getStages* = Call_GetStages_21626376(name: "getStages", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/restapis/{restapi_id}/stages",
                                      validator: validate_GetStages_21626377,
                                      base: "/", makeUrl: url_GetStages_21626378,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlan_21626424 = ref object of OpenApiRestCall_21625418
proc url_CreateUsagePlan_21626426(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUsagePlan_21626425(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626427 = header.getOrDefault("X-Amz-Date")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Date", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Security-Token", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Algorithm", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Signature")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Signature", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Credential")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Credential", valid_21626433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626435: Call_CreateUsagePlan_21626424; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ## 
  let valid = call_21626435.validator(path, query, header, formData, body, _)
  let scheme = call_21626435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626435.makeUrl(scheme.get, call_21626435.host, call_21626435.base,
                               call_21626435.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626435, uri, valid, _)

proc call*(call_21626436: Call_CreateUsagePlan_21626424; body: JsonNode): Recallable =
  ## createUsagePlan
  ## Creates a usage plan with the throttle and quota limits, as well as the associated API stages, specified in the payload. 
  ##   body: JObject (required)
  var body_21626437 = newJObject()
  if body != nil:
    body_21626437 = body
  result = call_21626436.call(nil, nil, nil, nil, body_21626437)

var createUsagePlan* = Call_CreateUsagePlan_21626424(name: "createUsagePlan",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_CreateUsagePlan_21626425, base: "/",
    makeUrl: url_CreateUsagePlan_21626426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlans_21626408 = ref object of OpenApiRestCall_21625418
proc url_GetUsagePlans_21626410(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUsagePlans_21626409(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626411 = query.getOrDefault("keyId")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "keyId", valid_21626411
  var valid_21626412 = query.getOrDefault("position")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "position", valid_21626412
  var valid_21626413 = query.getOrDefault("limit")
  valid_21626413 = validateParameter(valid_21626413, JInt, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "limit", valid_21626413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626414 = header.getOrDefault("X-Amz-Date")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Date", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Security-Token", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Algorithm", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Signature")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Signature", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Credential")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Credential", valid_21626420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626421: Call_GetUsagePlans_21626408; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all the usage plans of the caller's account.
  ## 
  let valid = call_21626421.validator(path, query, header, formData, body, _)
  let scheme = call_21626421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626421.makeUrl(scheme.get, call_21626421.host, call_21626421.base,
                               call_21626421.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626421, uri, valid, _)

proc call*(call_21626422: Call_GetUsagePlans_21626408; keyId: string = "";
          position: string = ""; limit: int = 0): Recallable =
  ## getUsagePlans
  ## Gets all the usage plans of the caller's account.
  ##   keyId: string
  ##        : The identifier of the API key associated with the usage plans.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21626423 = newJObject()
  add(query_21626423, "keyId", newJString(keyId))
  add(query_21626423, "position", newJString(position))
  add(query_21626423, "limit", newJInt(limit))
  result = call_21626422.call(nil, query_21626423, nil, nil, nil)

var getUsagePlans* = Call_GetUsagePlans_21626408(name: "getUsagePlans",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans", validator: validate_GetUsagePlans_21626409, base: "/",
    makeUrl: url_GetUsagePlans_21626410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUsagePlanKey_21626456 = ref object of OpenApiRestCall_21625418
proc url_CreateUsagePlanKey_21626458(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUsagePlanKey_21626457(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626459 = path.getOrDefault("usageplanId")
  valid_21626459 = validateParameter(valid_21626459, JString, required = true,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "usageplanId", valid_21626459
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626460 = header.getOrDefault("X-Amz-Date")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Date", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Security-Token", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Algorithm", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Signature")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Signature", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Credential")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Credential", valid_21626466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626468: Call_CreateUsagePlanKey_21626456; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_CreateUsagePlanKey_21626456; usageplanId: string;
          body: JsonNode): Recallable =
  ## createUsagePlanKey
  ## Creates a usage plan key for adding an existing API key to a usage plan.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-created <a>UsagePlanKey</a> resource representing a plan customer.
  ##   body: JObject (required)
  var path_21626470 = newJObject()
  var body_21626471 = newJObject()
  add(path_21626470, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_21626471 = body
  result = call_21626469.call(path_21626470, nil, nil, nil, body_21626471)

var createUsagePlanKey* = Call_CreateUsagePlanKey_21626456(
    name: "createUsagePlanKey", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/keys",
    validator: validate_CreateUsagePlanKey_21626457, base: "/",
    makeUrl: url_CreateUsagePlanKey_21626458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKeys_21626438 = ref object of OpenApiRestCall_21625418
proc url_GetUsagePlanKeys_21626440(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKeys_21626439(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626441 = path.getOrDefault("usageplanId")
  valid_21626441 = validateParameter(valid_21626441, JString, required = true,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "usageplanId", valid_21626441
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : A query parameter specifying the name of the to-be-returned usage plan keys.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21626442 = query.getOrDefault("name")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "name", valid_21626442
  var valid_21626443 = query.getOrDefault("position")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "position", valid_21626443
  var valid_21626444 = query.getOrDefault("limit")
  valid_21626444 = validateParameter(valid_21626444, JInt, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "limit", valid_21626444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626445 = header.getOrDefault("X-Amz-Date")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Date", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Security-Token", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Algorithm", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Signature")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Signature", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Credential")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Credential", valid_21626451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626452: Call_GetUsagePlanKeys_21626438; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all the usage plan keys representing the API keys added to a specified usage plan.
  ## 
  let valid = call_21626452.validator(path, query, header, formData, body, _)
  let scheme = call_21626452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626452.makeUrl(scheme.get, call_21626452.host, call_21626452.base,
                               call_21626452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626452, uri, valid, _)

proc call*(call_21626453: Call_GetUsagePlanKeys_21626438; usageplanId: string;
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
  var path_21626454 = newJObject()
  var query_21626455 = newJObject()
  add(path_21626454, "usageplanId", newJString(usageplanId))
  add(query_21626455, "name", newJString(name))
  add(query_21626455, "position", newJString(position))
  add(query_21626455, "limit", newJInt(limit))
  result = call_21626453.call(path_21626454, query_21626455, nil, nil, nil)

var getUsagePlanKeys* = Call_GetUsagePlanKeys_21626438(name: "getUsagePlanKeys",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys", validator: validate_GetUsagePlanKeys_21626439,
    base: "/", makeUrl: url_GetUsagePlanKeys_21626440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcLink_21626487 = ref object of OpenApiRestCall_21625418
proc url_CreateVpcLink_21626489(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVpcLink_21626488(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626490 = header.getOrDefault("X-Amz-Date")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Date", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Security-Token", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Algorithm", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Signature")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Signature", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Credential")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Credential", valid_21626496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_CreateVpcLink_21626487; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_CreateVpcLink_21626487; body: JsonNode): Recallable =
  ## createVpcLink
  ## Creates a VPC link, under the caller's account in a selected region, in an asynchronous operation that typically takes 2-4 minutes to complete and become operational. The caller must have permissions to create and update VPC Endpoint services.
  ##   body: JObject (required)
  var body_21626500 = newJObject()
  if body != nil:
    body_21626500 = body
  result = call_21626499.call(nil, nil, nil, nil, body_21626500)

var createVpcLink* = Call_CreateVpcLink_21626487(name: "createVpcLink",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_CreateVpcLink_21626488, base: "/",
    makeUrl: url_CreateVpcLink_21626489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLinks_21626472 = ref object of OpenApiRestCall_21625418
proc url_GetVpcLinks_21626474(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVpcLinks_21626473(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626475 = query.getOrDefault("position")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "position", valid_21626475
  var valid_21626476 = query.getOrDefault("limit")
  valid_21626476 = validateParameter(valid_21626476, JInt, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "limit", valid_21626476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626477 = header.getOrDefault("X-Amz-Date")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Date", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Security-Token", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Algorithm", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Signature")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Signature", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Credential")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Credential", valid_21626483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626484: Call_GetVpcLinks_21626472; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ## 
  let valid = call_21626484.validator(path, query, header, formData, body, _)
  let scheme = call_21626484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626484.makeUrl(scheme.get, call_21626484.host, call_21626484.base,
                               call_21626484.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626484, uri, valid, _)

proc call*(call_21626485: Call_GetVpcLinks_21626472; position: string = "";
          limit: int = 0): Recallable =
  ## getVpcLinks
  ## Gets the <a>VpcLinks</a> collection under the caller's account in a selected region.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21626486 = newJObject()
  add(query_21626486, "position", newJString(position))
  add(query_21626486, "limit", newJInt(limit))
  result = call_21626485.call(nil, query_21626486, nil, nil, nil)

var getVpcLinks* = Call_GetVpcLinks_21626472(name: "getVpcLinks",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/vpclinks",
    validator: validate_GetVpcLinks_21626473, base: "/", makeUrl: url_GetVpcLinks_21626474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiKey_21626501 = ref object of OpenApiRestCall_21625418
proc url_GetApiKey_21626503(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiKey_21626502(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_21626504 = path.getOrDefault("api_Key")
  valid_21626504 = validateParameter(valid_21626504, JString, required = true,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "api_Key", valid_21626504
  result.add "path", section
  ## parameters in `query` object:
  ##   includeValue: JBool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  section = newJObject()
  var valid_21626505 = query.getOrDefault("includeValue")
  valid_21626505 = validateParameter(valid_21626505, JBool, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "includeValue", valid_21626505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626506 = header.getOrDefault("X-Amz-Date")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Date", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Security-Token", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Algorithm", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Signature")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Signature", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Credential")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Credential", valid_21626512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626513: Call_GetApiKey_21626501; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the current <a>ApiKey</a> resource.
  ## 
  let valid = call_21626513.validator(path, query, header, formData, body, _)
  let scheme = call_21626513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626513.makeUrl(scheme.get, call_21626513.host, call_21626513.base,
                               call_21626513.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626513, uri, valid, _)

proc call*(call_21626514: Call_GetApiKey_21626501; apiKey: string;
          includeValue: bool = false): Recallable =
  ## getApiKey
  ## Gets information about the current <a>ApiKey</a> resource.
  ##   includeValue: bool
  ##               : A boolean flag to specify whether (<code>true</code>) or not (<code>false</code>) the result contains the key value.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource.
  var path_21626515 = newJObject()
  var query_21626516 = newJObject()
  add(query_21626516, "includeValue", newJBool(includeValue))
  add(path_21626515, "api_Key", newJString(apiKey))
  result = call_21626514.call(path_21626515, query_21626516, nil, nil, nil)

var getApiKey* = Call_GetApiKey_21626501(name: "getApiKey", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/apikeys/{api_Key}",
                                      validator: validate_GetApiKey_21626502,
                                      base: "/", makeUrl: url_GetApiKey_21626503,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_21626531 = ref object of OpenApiRestCall_21625418
proc url_UpdateApiKey_21626533(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_21626532(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_21626534 = path.getOrDefault("api_Key")
  valid_21626534 = validateParameter(valid_21626534, JString, required = true,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "api_Key", valid_21626534
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626535 = header.getOrDefault("X-Amz-Date")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Date", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Security-Token", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Algorithm", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Signature")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Signature", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Credential")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Credential", valid_21626541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626543: Call_UpdateApiKey_21626531; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about an <a>ApiKey</a> resource.
  ## 
  let valid = call_21626543.validator(path, query, header, formData, body, _)
  let scheme = call_21626543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626543.makeUrl(scheme.get, call_21626543.host, call_21626543.base,
                               call_21626543.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626543, uri, valid, _)

proc call*(call_21626544: Call_UpdateApiKey_21626531; apiKey: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Changes information about an <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be updated.
  ##   body: JObject (required)
  var path_21626545 = newJObject()
  var body_21626546 = newJObject()
  add(path_21626545, "api_Key", newJString(apiKey))
  if body != nil:
    body_21626546 = body
  result = call_21626544.call(path_21626545, nil, nil, nil, body_21626546)

var updateApiKey* = Call_UpdateApiKey_21626531(name: "updateApiKey",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_UpdateApiKey_21626532,
    base: "/", makeUrl: url_UpdateApiKey_21626533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_21626517 = ref object of OpenApiRestCall_21625418
proc url_DeleteApiKey_21626519(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_21626518(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   api_Key: JString (required)
  ##          : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `api_Key` field"
  var valid_21626520 = path.getOrDefault("api_Key")
  valid_21626520 = validateParameter(valid_21626520, JString, required = true,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "api_Key", valid_21626520
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626521 = header.getOrDefault("X-Amz-Date")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Date", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Security-Token", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Algorithm", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Signature")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Signature", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Credential")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Credential", valid_21626527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626528: Call_DeleteApiKey_21626517; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the <a>ApiKey</a> resource.
  ## 
  let valid = call_21626528.validator(path, query, header, formData, body, _)
  let scheme = call_21626528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626528.makeUrl(scheme.get, call_21626528.host, call_21626528.base,
                               call_21626528.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626528, uri, valid, _)

proc call*(call_21626529: Call_DeleteApiKey_21626517; apiKey: string): Recallable =
  ## deleteApiKey
  ## Deletes the <a>ApiKey</a> resource.
  ##   apiKey: string (required)
  ##         : [Required] The identifier of the <a>ApiKey</a> resource to be deleted.
  var path_21626530 = newJObject()
  add(path_21626530, "api_Key", newJString(apiKey))
  result = call_21626529.call(path_21626530, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_21626517(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/apikeys/{api_Key}", validator: validate_DeleteApiKey_21626518,
    base: "/", makeUrl: url_DeleteApiKey_21626519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeAuthorizer_21626562 = ref object of OpenApiRestCall_21625418
proc url_TestInvokeAuthorizer_21626564(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeAuthorizer_21626563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626565 = path.getOrDefault("authorizer_id")
  valid_21626565 = validateParameter(valid_21626565, JString, required = true,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "authorizer_id", valid_21626565
  var valid_21626566 = path.getOrDefault("restapi_id")
  valid_21626566 = validateParameter(valid_21626566, JString, required = true,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "restapi_id", valid_21626566
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626567 = header.getOrDefault("X-Amz-Date")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Date", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Security-Token", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Algorithm", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Signature")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Signature", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Credential")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Credential", valid_21626573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626575: Call_TestInvokeAuthorizer_21626562; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ## 
  let valid = call_21626575.validator(path, query, header, formData, body, _)
  let scheme = call_21626575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626575.makeUrl(scheme.get, call_21626575.host, call_21626575.base,
                               call_21626575.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626575, uri, valid, _)

proc call*(call_21626576: Call_TestInvokeAuthorizer_21626562; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## testInvokeAuthorizer
  ## <p>Simulate the execution of an <a>Authorizer</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.</p> <div class="seeAlso"> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html">Use Lambda Function as Authorizer</a> <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html">Use Cognito User Pool as Authorizer</a> </div>
  ##   authorizerId: string (required)
  ##               : [Required] Specifies a test invoke authorizer request's <a>Authorizer</a> ID.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626577 = newJObject()
  var body_21626578 = newJObject()
  add(path_21626577, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_21626578 = body
  add(path_21626577, "restapi_id", newJString(restapiId))
  result = call_21626576.call(path_21626577, nil, nil, nil, body_21626578)

var testInvokeAuthorizer* = Call_TestInvokeAuthorizer_21626562(
    name: "testInvokeAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_TestInvokeAuthorizer_21626563, base: "/",
    makeUrl: url_TestInvokeAuthorizer_21626564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_21626547 = ref object of OpenApiRestCall_21625418
proc url_GetAuthorizer_21626549(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_21626548(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626550 = path.getOrDefault("authorizer_id")
  valid_21626550 = validateParameter(valid_21626550, JString, required = true,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "authorizer_id", valid_21626550
  var valid_21626551 = path.getOrDefault("restapi_id")
  valid_21626551 = validateParameter(valid_21626551, JString, required = true,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "restapi_id", valid_21626551
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626552 = header.getOrDefault("X-Amz-Date")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Date", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Security-Token", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Algorithm", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Signature")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Signature", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Credential")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Credential", valid_21626558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626559: Call_GetAuthorizer_21626547; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_21626559.validator(path, query, header, formData, body, _)
  let scheme = call_21626559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626559.makeUrl(scheme.get, call_21626559.host, call_21626559.base,
                               call_21626559.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626559, uri, valid, _)

proc call*(call_21626560: Call_GetAuthorizer_21626547; authorizerId: string;
          restapiId: string): Recallable =
  ## getAuthorizer
  ## <p>Describe an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/get-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626561 = newJObject()
  add(path_21626561, "authorizer_id", newJString(authorizerId))
  add(path_21626561, "restapi_id", newJString(restapiId))
  result = call_21626560.call(path_21626561, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_21626547(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_GetAuthorizer_21626548, base: "/",
    makeUrl: url_GetAuthorizer_21626549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_21626594 = ref object of OpenApiRestCall_21625418
proc url_UpdateAuthorizer_21626596(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_21626595(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626597 = path.getOrDefault("authorizer_id")
  valid_21626597 = validateParameter(valid_21626597, JString, required = true,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "authorizer_id", valid_21626597
  var valid_21626598 = path.getOrDefault("restapi_id")
  valid_21626598 = validateParameter(valid_21626598, JString, required = true,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "restapi_id", valid_21626598
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626599 = header.getOrDefault("X-Amz-Date")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Date", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Security-Token", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Algorithm", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Signature")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Signature", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Credential")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Credential", valid_21626605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626607: Call_UpdateAuthorizer_21626594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_21626607.validator(path, query, header, formData, body, _)
  let scheme = call_21626607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626607.makeUrl(scheme.get, call_21626607.host, call_21626607.base,
                               call_21626607.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626607, uri, valid, _)

proc call*(call_21626608: Call_UpdateAuthorizer_21626594; authorizerId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateAuthorizer
  ## <p>Updates an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/update-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626609 = newJObject()
  var body_21626610 = newJObject()
  add(path_21626609, "authorizer_id", newJString(authorizerId))
  if body != nil:
    body_21626610 = body
  add(path_21626609, "restapi_id", newJString(restapiId))
  result = call_21626608.call(path_21626609, nil, nil, nil, body_21626610)

var updateAuthorizer* = Call_UpdateAuthorizer_21626594(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_UpdateAuthorizer_21626595, base: "/",
    makeUrl: url_UpdateAuthorizer_21626596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_21626579 = ref object of OpenApiRestCall_21625418
proc url_DeleteAuthorizer_21626581(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_21626580(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626582 = path.getOrDefault("authorizer_id")
  valid_21626582 = validateParameter(valid_21626582, JString, required = true,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "authorizer_id", valid_21626582
  var valid_21626583 = path.getOrDefault("restapi_id")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "restapi_id", valid_21626583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626584 = header.getOrDefault("X-Amz-Date")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Date", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Security-Token", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Algorithm", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Signature")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Signature", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Credential")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Credential", valid_21626590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626591: Call_DeleteAuthorizer_21626579; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_DeleteAuthorizer_21626579; authorizerId: string;
          restapiId: string): Recallable =
  ## deleteAuthorizer
  ## <p>Deletes an existing <a>Authorizer</a> resource.</p> <div class="seeAlso"><a href="https://docs.aws.amazon.com/cli/latest/reference/apigateway/delete-authorizer.html">AWS CLI</a></div>
  ##   authorizerId: string (required)
  ##               : [Required] The identifier of the <a>Authorizer</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626593 = newJObject()
  add(path_21626593, "authorizer_id", newJString(authorizerId))
  add(path_21626593, "restapi_id", newJString(restapiId))
  result = call_21626592.call(path_21626593, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_21626579(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/authorizers/{authorizer_id}",
    validator: validate_DeleteAuthorizer_21626580, base: "/",
    makeUrl: url_DeleteAuthorizer_21626581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBasePathMapping_21626611 = ref object of OpenApiRestCall_21625418
proc url_GetBasePathMapping_21626613(protocol: Scheme; host: string; base: string;
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

proc validate_GetBasePathMapping_21626612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626614 = path.getOrDefault("base_path")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "base_path", valid_21626614
  var valid_21626615 = path.getOrDefault("domain_name")
  valid_21626615 = validateParameter(valid_21626615, JString, required = true,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "domain_name", valid_21626615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626616 = header.getOrDefault("X-Amz-Date")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Date", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Security-Token", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Algorithm", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Signature")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Signature", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Credential")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Credential", valid_21626622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626623: Call_GetBasePathMapping_21626611; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe a <a>BasePathMapping</a> resource.
  ## 
  let valid = call_21626623.validator(path, query, header, formData, body, _)
  let scheme = call_21626623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626623.makeUrl(scheme.get, call_21626623.host, call_21626623.base,
                               call_21626623.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626623, uri, valid, _)

proc call*(call_21626624: Call_GetBasePathMapping_21626611; basePath: string;
          domainName: string): Recallable =
  ## getBasePathMapping
  ## Describe a <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : [Required] The base path name that callers of the API must provide as part of the URL after the domain name. This value must be unique for all of the mappings across a single API. Specify '(none)' if you do not want callers to specify any base path name after the domain name.
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to be described.
  var path_21626625 = newJObject()
  add(path_21626625, "base_path", newJString(basePath))
  add(path_21626625, "domain_name", newJString(domainName))
  result = call_21626624.call(path_21626625, nil, nil, nil, nil)

var getBasePathMapping* = Call_GetBasePathMapping_21626611(
    name: "getBasePathMapping", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_GetBasePathMapping_21626612, base: "/",
    makeUrl: url_GetBasePathMapping_21626613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBasePathMapping_21626641 = ref object of OpenApiRestCall_21625418
proc url_UpdateBasePathMapping_21626643(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_UpdateBasePathMapping_21626642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626644 = path.getOrDefault("base_path")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "base_path", valid_21626644
  var valid_21626645 = path.getOrDefault("domain_name")
  valid_21626645 = validateParameter(valid_21626645, JString, required = true,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "domain_name", valid_21626645
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626646 = header.getOrDefault("X-Amz-Date")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Date", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Security-Token", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Algorithm", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Signature")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Signature", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Credential")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Credential", valid_21626652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626654: Call_UpdateBasePathMapping_21626641;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_21626654.validator(path, query, header, formData, body, _)
  let scheme = call_21626654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626654.makeUrl(scheme.get, call_21626654.host, call_21626654.base,
                               call_21626654.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626654, uri, valid, _)

proc call*(call_21626655: Call_UpdateBasePathMapping_21626641; basePath: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateBasePathMapping
  ## Changes information about the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path of the <a>BasePathMapping</a> resource to change.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to change.
  ##   body: JObject (required)
  var path_21626656 = newJObject()
  var body_21626657 = newJObject()
  add(path_21626656, "base_path", newJString(basePath))
  add(path_21626656, "domain_name", newJString(domainName))
  if body != nil:
    body_21626657 = body
  result = call_21626655.call(path_21626656, nil, nil, nil, body_21626657)

var updateBasePathMapping* = Call_UpdateBasePathMapping_21626641(
    name: "updateBasePathMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_UpdateBasePathMapping_21626642, base: "/",
    makeUrl: url_UpdateBasePathMapping_21626643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBasePathMapping_21626626 = ref object of OpenApiRestCall_21625418
proc url_DeleteBasePathMapping_21626628(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_DeleteBasePathMapping_21626627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626629 = path.getOrDefault("base_path")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "base_path", valid_21626629
  var valid_21626630 = path.getOrDefault("domain_name")
  valid_21626630 = validateParameter(valid_21626630, JString, required = true,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "domain_name", valid_21626630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626631 = header.getOrDefault("X-Amz-Date")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Date", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Security-Token", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626638: Call_DeleteBasePathMapping_21626626;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the <a>BasePathMapping</a> resource.
  ## 
  let valid = call_21626638.validator(path, query, header, formData, body, _)
  let scheme = call_21626638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626638.makeUrl(scheme.get, call_21626638.host, call_21626638.base,
                               call_21626638.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626638, uri, valid, _)

proc call*(call_21626639: Call_DeleteBasePathMapping_21626626; basePath: string;
          domainName: string): Recallable =
  ## deleteBasePathMapping
  ## Deletes the <a>BasePathMapping</a> resource.
  ##   basePath: string (required)
  ##           : <p>[Required] The base path name of the <a>BasePathMapping</a> resource to delete.</p> <p>To specify an empty base path, set this parameter to <code>'(none)'</code>.</p>
  ##   domainName: string (required)
  ##             : [Required] The domain name of the <a>BasePathMapping</a> resource to delete.
  var path_21626640 = newJObject()
  add(path_21626640, "base_path", newJString(basePath))
  add(path_21626640, "domain_name", newJString(domainName))
  result = call_21626639.call(path_21626640, nil, nil, nil, nil)

var deleteBasePathMapping* = Call_DeleteBasePathMapping_21626626(
    name: "deleteBasePathMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}/basepathmappings/{base_path}",
    validator: validate_DeleteBasePathMapping_21626627, base: "/",
    makeUrl: url_DeleteBasePathMapping_21626628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificate_21626658 = ref object of OpenApiRestCall_21625418
proc url_GetClientCertificate_21626660(protocol: Scheme; host: string; base: string;
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

proc validate_GetClientCertificate_21626659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_21626661 = path.getOrDefault("clientcertificate_id")
  valid_21626661 = validateParameter(valid_21626661, JString, required = true,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "clientcertificate_id", valid_21626661
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Algorithm", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Signature")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Signature", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Credential")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Credential", valid_21626668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626669: Call_GetClientCertificate_21626658; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ## 
  let valid = call_21626669.validator(path, query, header, formData, body, _)
  let scheme = call_21626669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626669.makeUrl(scheme.get, call_21626669.host, call_21626669.base,
                               call_21626669.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626669, uri, valid, _)

proc call*(call_21626670: Call_GetClientCertificate_21626658;
          clientcertificateId: string): Recallable =
  ## getClientCertificate
  ## Gets information about the current <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be described.
  var path_21626671 = newJObject()
  add(path_21626671, "clientcertificate_id", newJString(clientcertificateId))
  result = call_21626670.call(path_21626671, nil, nil, nil, nil)

var getClientCertificate* = Call_GetClientCertificate_21626658(
    name: "getClientCertificate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_GetClientCertificate_21626659, base: "/",
    makeUrl: url_GetClientCertificate_21626660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClientCertificate_21626686 = ref object of OpenApiRestCall_21625418
proc url_UpdateClientCertificate_21626688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateClientCertificate_21626687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_21626689 = path.getOrDefault("clientcertificate_id")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "clientcertificate_id", valid_21626689
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626690 = header.getOrDefault("X-Amz-Date")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Date", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Security-Token", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Algorithm", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Signature")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Signature", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Credential")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Credential", valid_21626696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626698: Call_UpdateClientCertificate_21626686;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about an <a>ClientCertificate</a> resource.
  ## 
  let valid = call_21626698.validator(path, query, header, formData, body, _)
  let scheme = call_21626698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626698.makeUrl(scheme.get, call_21626698.host, call_21626698.base,
                               call_21626698.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626698, uri, valid, _)

proc call*(call_21626699: Call_UpdateClientCertificate_21626686;
          clientcertificateId: string; body: JsonNode): Recallable =
  ## updateClientCertificate
  ## Changes information about an <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be updated.
  ##   body: JObject (required)
  var path_21626700 = newJObject()
  var body_21626701 = newJObject()
  add(path_21626700, "clientcertificate_id", newJString(clientcertificateId))
  if body != nil:
    body_21626701 = body
  result = call_21626699.call(path_21626700, nil, nil, nil, body_21626701)

var updateClientCertificate* = Call_UpdateClientCertificate_21626686(
    name: "updateClientCertificate", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_UpdateClientCertificate_21626687, base: "/",
    makeUrl: url_UpdateClientCertificate_21626688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClientCertificate_21626672 = ref object of OpenApiRestCall_21625418
proc url_DeleteClientCertificate_21626674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteClientCertificate_21626673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clientcertificate_id: JString (required)
  ##                       : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clientcertificate_id` field"
  var valid_21626675 = path.getOrDefault("clientcertificate_id")
  valid_21626675 = validateParameter(valid_21626675, JString, required = true,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "clientcertificate_id", valid_21626675
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626676 = header.getOrDefault("X-Amz-Date")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Date", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Security-Token", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Algorithm", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Signature")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Signature", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Credential")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Credential", valid_21626682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626683: Call_DeleteClientCertificate_21626672;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the <a>ClientCertificate</a> resource.
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_DeleteClientCertificate_21626672;
          clientcertificateId: string): Recallable =
  ## deleteClientCertificate
  ## Deletes the <a>ClientCertificate</a> resource.
  ##   clientcertificateId: string (required)
  ##                      : [Required] The identifier of the <a>ClientCertificate</a> resource to be deleted.
  var path_21626685 = newJObject()
  add(path_21626685, "clientcertificate_id", newJString(clientcertificateId))
  result = call_21626684.call(path_21626685, nil, nil, nil, nil)

var deleteClientCertificate* = Call_DeleteClientCertificate_21626672(
    name: "deleteClientCertificate", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/clientcertificates/{clientcertificate_id}",
    validator: validate_DeleteClientCertificate_21626673, base: "/",
    makeUrl: url_DeleteClientCertificate_21626674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_21626702 = ref object of OpenApiRestCall_21625418
proc url_GetDeployment_21626704(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_21626703(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626705 = path.getOrDefault("deployment_id")
  valid_21626705 = validateParameter(valid_21626705, JString, required = true,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "deployment_id", valid_21626705
  var valid_21626706 = path.getOrDefault("restapi_id")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "restapi_id", valid_21626706
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  section = newJObject()
  var valid_21626707 = query.getOrDefault("embed")
  valid_21626707 = validateParameter(valid_21626707, JArray, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "embed", valid_21626707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626708 = header.getOrDefault("X-Amz-Date")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Date", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Security-Token", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626715: Call_GetDeployment_21626702; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a <a>Deployment</a> resource.
  ## 
  let valid = call_21626715.validator(path, query, header, formData, body, _)
  let scheme = call_21626715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626715.makeUrl(scheme.get, call_21626715.host, call_21626715.base,
                               call_21626715.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626715, uri, valid, _)

proc call*(call_21626716: Call_GetDeployment_21626702; deploymentId: string;
          restapiId: string; embed: JsonNode = nil): Recallable =
  ## getDeployment
  ## Gets information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to get information about.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified embedded resources of the returned <a>Deployment</a> resource in the response. In a REST API call, this <code>embed</code> parameter value is a list of comma-separated strings, as in <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=var1,var2</code>. The SDK and other platform-dependent libraries might use a different format for the list. Currently, this request supports only retrieval of the embedded API summary this way. Hence, the parameter value must be a single-valued list containing only the <code>"apisummary"</code> string. For example, <code>GET /restapis/{restapi_id}/deployments/{deployment_id}?embed=apisummary</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626717 = newJObject()
  var query_21626718 = newJObject()
  add(path_21626717, "deployment_id", newJString(deploymentId))
  if embed != nil:
    query_21626718.add "embed", embed
  add(path_21626717, "restapi_id", newJString(restapiId))
  result = call_21626716.call(path_21626717, query_21626718, nil, nil, nil)

var getDeployment* = Call_GetDeployment_21626702(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_GetDeployment_21626703, base: "/",
    makeUrl: url_GetDeployment_21626704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_21626734 = ref object of OpenApiRestCall_21625418
proc url_UpdateDeployment_21626736(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_21626735(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626737 = path.getOrDefault("deployment_id")
  valid_21626737 = validateParameter(valid_21626737, JString, required = true,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "deployment_id", valid_21626737
  var valid_21626738 = path.getOrDefault("restapi_id")
  valid_21626738 = validateParameter(valid_21626738, JString, required = true,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "restapi_id", valid_21626738
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626739 = header.getOrDefault("X-Amz-Date")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Date", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Security-Token", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Algorithm", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-Signature")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Signature", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Credential")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Credential", valid_21626745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626747: Call_UpdateDeployment_21626734; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about a <a>Deployment</a> resource.
  ## 
  let valid = call_21626747.validator(path, query, header, formData, body, _)
  let scheme = call_21626747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626747.makeUrl(scheme.get, call_21626747.host, call_21626747.base,
                               call_21626747.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626747, uri, valid, _)

proc call*(call_21626748: Call_UpdateDeployment_21626734; deploymentId: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateDeployment
  ## Changes information about a <a>Deployment</a> resource.
  ##   deploymentId: string (required)
  ##               : The replacement identifier for the <a>Deployment</a> resource to change information about.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626749 = newJObject()
  var body_21626750 = newJObject()
  add(path_21626749, "deployment_id", newJString(deploymentId))
  if body != nil:
    body_21626750 = body
  add(path_21626749, "restapi_id", newJString(restapiId))
  result = call_21626748.call(path_21626749, nil, nil, nil, body_21626750)

var updateDeployment* = Call_UpdateDeployment_21626734(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_UpdateDeployment_21626735, base: "/",
    makeUrl: url_UpdateDeployment_21626736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_21626719 = ref object of OpenApiRestCall_21625418
proc url_DeleteDeployment_21626721(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_21626720(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626722 = path.getOrDefault("deployment_id")
  valid_21626722 = validateParameter(valid_21626722, JString, required = true,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "deployment_id", valid_21626722
  var valid_21626723 = path.getOrDefault("restapi_id")
  valid_21626723 = validateParameter(valid_21626723, JString, required = true,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "restapi_id", valid_21626723
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626724 = header.getOrDefault("X-Amz-Date")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Date", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Security-Token", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Algorithm", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Signature")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Signature", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Credential")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Credential", valid_21626730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626731: Call_DeleteDeployment_21626719; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_DeleteDeployment_21626719; deploymentId: string;
          restapiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a <a>Deployment</a> resource. Deleting a deployment will only succeed if there are no <a>Stage</a> resources associated with it.
  ##   deploymentId: string (required)
  ##               : [Required] The identifier of the <a>Deployment</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626733 = newJObject()
  add(path_21626733, "deployment_id", newJString(deploymentId))
  add(path_21626733, "restapi_id", newJString(restapiId))
  result = call_21626732.call(path_21626733, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_21626719(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/deployments/{deployment_id}",
    validator: validate_DeleteDeployment_21626720, base: "/",
    makeUrl: url_DeleteDeployment_21626721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationPart_21626751 = ref object of OpenApiRestCall_21625418
proc url_GetDocumentationPart_21626753(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentationPart_21626752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_21626754 = path.getOrDefault("part_id")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "part_id", valid_21626754
  var valid_21626755 = path.getOrDefault("restapi_id")
  valid_21626755 = validateParameter(valid_21626755, JString, required = true,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "restapi_id", valid_21626755
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626756 = header.getOrDefault("X-Amz-Date")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Date", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Security-Token", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Algorithm", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Signature")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Signature", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Credential")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Credential", valid_21626762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626763: Call_GetDocumentationPart_21626751; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626763.validator(path, query, header, formData, body, _)
  let scheme = call_21626763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626763.makeUrl(scheme.get, call_21626763.host, call_21626763.base,
                               call_21626763.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626763, uri, valid, _)

proc call*(call_21626764: Call_GetDocumentationPart_21626751; partId: string;
          restapiId: string): Recallable =
  ## getDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626765 = newJObject()
  add(path_21626765, "part_id", newJString(partId))
  add(path_21626765, "restapi_id", newJString(restapiId))
  result = call_21626764.call(path_21626765, nil, nil, nil, nil)

var getDocumentationPart* = Call_GetDocumentationPart_21626751(
    name: "getDocumentationPart", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_GetDocumentationPart_21626752, base: "/",
    makeUrl: url_GetDocumentationPart_21626753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationPart_21626781 = ref object of OpenApiRestCall_21625418
proc url_UpdateDocumentationPart_21626783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateDocumentationPart_21626782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The identifier of the to-be-updated documentation part.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_21626784 = path.getOrDefault("part_id")
  valid_21626784 = validateParameter(valid_21626784, JString, required = true,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "part_id", valid_21626784
  var valid_21626785 = path.getOrDefault("restapi_id")
  valid_21626785 = validateParameter(valid_21626785, JString, required = true,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "restapi_id", valid_21626785
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626786 = header.getOrDefault("X-Amz-Date")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Date", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Security-Token", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Algorithm", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Signature")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Signature", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Credential")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Credential", valid_21626792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626794: Call_UpdateDocumentationPart_21626781;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626794.validator(path, query, header, formData, body, _)
  let scheme = call_21626794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626794.makeUrl(scheme.get, call_21626794.host, call_21626794.base,
                               call_21626794.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626794, uri, valid, _)

proc call*(call_21626795: Call_UpdateDocumentationPart_21626781; body: JsonNode;
          partId: string; restapiId: string): Recallable =
  ## updateDocumentationPart
  ##   body: JObject (required)
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-updated documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626796 = newJObject()
  var body_21626797 = newJObject()
  if body != nil:
    body_21626797 = body
  add(path_21626796, "part_id", newJString(partId))
  add(path_21626796, "restapi_id", newJString(restapiId))
  result = call_21626795.call(path_21626796, nil, nil, nil, body_21626797)

var updateDocumentationPart* = Call_UpdateDocumentationPart_21626781(
    name: "updateDocumentationPart", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_UpdateDocumentationPart_21626782, base: "/",
    makeUrl: url_UpdateDocumentationPart_21626783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationPart_21626766 = ref object of OpenApiRestCall_21625418
proc url_DeleteDocumentationPart_21626768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteDocumentationPart_21626767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   part_id: JString (required)
  ##          : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapi_id: JString (required)
  ##             : [Required] The string identifier of the associated <a>RestApi</a>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `part_id` field"
  var valid_21626769 = path.getOrDefault("part_id")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "part_id", valid_21626769
  var valid_21626770 = path.getOrDefault("restapi_id")
  valid_21626770 = validateParameter(valid_21626770, JString, required = true,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "restapi_id", valid_21626770
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626771 = header.getOrDefault("X-Amz-Date")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Date", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Security-Token", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Algorithm", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-Signature")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Signature", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Credential")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-Credential", valid_21626777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626778: Call_DeleteDocumentationPart_21626766;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626778.validator(path, query, header, formData, body, _)
  let scheme = call_21626778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626778.makeUrl(scheme.get, call_21626778.host, call_21626778.base,
                               call_21626778.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626778, uri, valid, _)

proc call*(call_21626779: Call_DeleteDocumentationPart_21626766; partId: string;
          restapiId: string): Recallable =
  ## deleteDocumentationPart
  ##   partId: string (required)
  ##         : [Required] The identifier of the to-be-deleted documentation part.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626780 = newJObject()
  add(path_21626780, "part_id", newJString(partId))
  add(path_21626780, "restapi_id", newJString(restapiId))
  result = call_21626779.call(path_21626780, nil, nil, nil, nil)

var deleteDocumentationPart* = Call_DeleteDocumentationPart_21626766(
    name: "deleteDocumentationPart", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/parts/{part_id}",
    validator: validate_DeleteDocumentationPart_21626767, base: "/",
    makeUrl: url_DeleteDocumentationPart_21626768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentationVersion_21626798 = ref object of OpenApiRestCall_21625418
proc url_GetDocumentationVersion_21626800(protocol: Scheme; host: string;
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

proc validate_GetDocumentationVersion_21626799(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626801 = path.getOrDefault("doc_version")
  valid_21626801 = validateParameter(valid_21626801, JString, required = true,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "doc_version", valid_21626801
  var valid_21626802 = path.getOrDefault("restapi_id")
  valid_21626802 = validateParameter(valid_21626802, JString, required = true,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "restapi_id", valid_21626802
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626803 = header.getOrDefault("X-Amz-Date")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Date", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Security-Token", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Algorithm", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Signature")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Signature", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Credential")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Credential", valid_21626809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626810: Call_GetDocumentationVersion_21626798;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626810.validator(path, query, header, formData, body, _)
  let scheme = call_21626810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626810.makeUrl(scheme.get, call_21626810.host, call_21626810.base,
                               call_21626810.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626810, uri, valid, _)

proc call*(call_21626811: Call_GetDocumentationVersion_21626798;
          docVersion: string; restapiId: string): Recallable =
  ## getDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-retrieved documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626812 = newJObject()
  add(path_21626812, "doc_version", newJString(docVersion))
  add(path_21626812, "restapi_id", newJString(restapiId))
  result = call_21626811.call(path_21626812, nil, nil, nil, nil)

var getDocumentationVersion* = Call_GetDocumentationVersion_21626798(
    name: "getDocumentationVersion", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_GetDocumentationVersion_21626799, base: "/",
    makeUrl: url_GetDocumentationVersion_21626800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentationVersion_21626828 = ref object of OpenApiRestCall_21625418
proc url_UpdateDocumentationVersion_21626830(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentationVersion_21626829(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626831 = path.getOrDefault("doc_version")
  valid_21626831 = validateParameter(valid_21626831, JString, required = true,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "doc_version", valid_21626831
  var valid_21626832 = path.getOrDefault("restapi_id")
  valid_21626832 = validateParameter(valid_21626832, JString, required = true,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "restapi_id", valid_21626832
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626833 = header.getOrDefault("X-Amz-Date")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Date", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Security-Token", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Algorithm", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Signature")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Signature", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Credential")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Credential", valid_21626839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626841: Call_UpdateDocumentationVersion_21626828;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626841.validator(path, query, header, formData, body, _)
  let scheme = call_21626841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626841.makeUrl(scheme.get, call_21626841.host, call_21626841.base,
                               call_21626841.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626841, uri, valid, _)

proc call*(call_21626842: Call_UpdateDocumentationVersion_21626828;
          docVersion: string; body: JsonNode; restapiId: string): Recallable =
  ## updateDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of the to-be-updated documentation version.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>..
  var path_21626843 = newJObject()
  var body_21626844 = newJObject()
  add(path_21626843, "doc_version", newJString(docVersion))
  if body != nil:
    body_21626844 = body
  add(path_21626843, "restapi_id", newJString(restapiId))
  result = call_21626842.call(path_21626843, nil, nil, nil, body_21626844)

var updateDocumentationVersion* = Call_UpdateDocumentationVersion_21626828(
    name: "updateDocumentationVersion", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_UpdateDocumentationVersion_21626829, base: "/",
    makeUrl: url_UpdateDocumentationVersion_21626830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocumentationVersion_21626813 = ref object of OpenApiRestCall_21625418
proc url_DeleteDocumentationVersion_21626815(protocol: Scheme; host: string;
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

proc validate_DeleteDocumentationVersion_21626814(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626816 = path.getOrDefault("doc_version")
  valid_21626816 = validateParameter(valid_21626816, JString, required = true,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "doc_version", valid_21626816
  var valid_21626817 = path.getOrDefault("restapi_id")
  valid_21626817 = validateParameter(valid_21626817, JString, required = true,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "restapi_id", valid_21626817
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626818 = header.getOrDefault("X-Amz-Date")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-Date", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Security-Token", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Algorithm", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Signature")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Signature", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Credential")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Credential", valid_21626824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626825: Call_DeleteDocumentationVersion_21626813;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626825.validator(path, query, header, formData, body, _)
  let scheme = call_21626825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626825.makeUrl(scheme.get, call_21626825.host, call_21626825.base,
                               call_21626825.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626825, uri, valid, _)

proc call*(call_21626826: Call_DeleteDocumentationVersion_21626813;
          docVersion: string; restapiId: string): Recallable =
  ## deleteDocumentationVersion
  ##   docVersion: string (required)
  ##             : [Required] The version identifier of a to-be-deleted documentation snapshot.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21626827 = newJObject()
  add(path_21626827, "doc_version", newJString(docVersion))
  add(path_21626827, "restapi_id", newJString(restapiId))
  result = call_21626826.call(path_21626827, nil, nil, nil, nil)

var deleteDocumentationVersion* = Call_DeleteDocumentationVersion_21626813(
    name: "deleteDocumentationVersion", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/documentation/versions/{doc_version}",
    validator: validate_DeleteDocumentationVersion_21626814, base: "/",
    makeUrl: url_DeleteDocumentationVersion_21626815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_21626845 = ref object of OpenApiRestCall_21625418
proc url_GetDomainName_21626847(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_21626846(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626848 = path.getOrDefault("domain_name")
  valid_21626848 = validateParameter(valid_21626848, JString, required = true,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "domain_name", valid_21626848
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626849 = header.getOrDefault("X-Amz-Date")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Date", valid_21626849
  var valid_21626850 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Security-Token", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Algorithm", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Signature")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Signature", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Credential")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Credential", valid_21626855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626856: Call_GetDomainName_21626845; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ## 
  let valid = call_21626856.validator(path, query, header, formData, body, _)
  let scheme = call_21626856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626856.makeUrl(scheme.get, call_21626856.host, call_21626856.base,
                               call_21626856.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626856, uri, valid, _)

proc call*(call_21626857: Call_GetDomainName_21626845; domainName: string): Recallable =
  ## getDomainName
  ## Represents a domain name that is contained in a simpler, more intuitive URL that can be called.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource.
  var path_21626858 = newJObject()
  add(path_21626858, "domain_name", newJString(domainName))
  result = call_21626857.call(path_21626858, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_21626845(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_GetDomainName_21626846,
    base: "/", makeUrl: url_GetDomainName_21626847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_21626873 = ref object of OpenApiRestCall_21625418
proc url_UpdateDomainName_21626875(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_21626874(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626876 = path.getOrDefault("domain_name")
  valid_21626876 = validateParameter(valid_21626876, JString, required = true,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "domain_name", valid_21626876
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626877 = header.getOrDefault("X-Amz-Date")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Date", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-Security-Token", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Algorithm", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Signature")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Signature", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Credential")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Credential", valid_21626883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626885: Call_UpdateDomainName_21626873; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about the <a>DomainName</a> resource.
  ## 
  let valid = call_21626885.validator(path, query, header, formData, body, _)
  let scheme = call_21626885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626885.makeUrl(scheme.get, call_21626885.host, call_21626885.base,
                               call_21626885.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626885, uri, valid, _)

proc call*(call_21626886: Call_UpdateDomainName_21626873; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Changes information about the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be changed.
  ##   body: JObject (required)
  var path_21626887 = newJObject()
  var body_21626888 = newJObject()
  add(path_21626887, "domain_name", newJString(domainName))
  if body != nil:
    body_21626888 = body
  result = call_21626886.call(path_21626887, nil, nil, nil, body_21626888)

var updateDomainName* = Call_UpdateDomainName_21626873(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_UpdateDomainName_21626874,
    base: "/", makeUrl: url_UpdateDomainName_21626875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_21626859 = ref object of OpenApiRestCall_21625418
proc url_DeleteDomainName_21626861(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_21626860(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626862 = path.getOrDefault("domain_name")
  valid_21626862 = validateParameter(valid_21626862, JString, required = true,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "domain_name", valid_21626862
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626863 = header.getOrDefault("X-Amz-Date")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Date", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Security-Token", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Algorithm", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Signature")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Signature", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Credential")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Credential", valid_21626869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626870: Call_DeleteDomainName_21626859; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the <a>DomainName</a> resource.
  ## 
  let valid = call_21626870.validator(path, query, header, formData, body, _)
  let scheme = call_21626870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626870.makeUrl(scheme.get, call_21626870.host, call_21626870.base,
                               call_21626870.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626870, uri, valid, _)

proc call*(call_21626871: Call_DeleteDomainName_21626859; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes the <a>DomainName</a> resource.
  ##   domainName: string (required)
  ##             : [Required] The name of the <a>DomainName</a> resource to be deleted.
  var path_21626872 = newJObject()
  add(path_21626872, "domain_name", newJString(domainName))
  result = call_21626871.call(path_21626872, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_21626859(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/domainnames/{domain_name}", validator: validate_DeleteDomainName_21626860,
    base: "/", makeUrl: url_DeleteDomainName_21626861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutGatewayResponse_21626904 = ref object of OpenApiRestCall_21625418
proc url_PutGatewayResponse_21626906(protocol: Scheme; host: string; base: string;
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

proc validate_PutGatewayResponse_21626905(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626907 = path.getOrDefault("response_type")
  valid_21626907 = validateParameter(valid_21626907, JString, required = true,
                                   default = newJString("DEFAULT_4XX"))
  if valid_21626907 != nil:
    section.add "response_type", valid_21626907
  var valid_21626908 = path.getOrDefault("restapi_id")
  valid_21626908 = validateParameter(valid_21626908, JString, required = true,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "restapi_id", valid_21626908
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626909 = header.getOrDefault("X-Amz-Date")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Date", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Security-Token", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Algorithm", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Signature")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Signature", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Credential")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Credential", valid_21626915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626917: Call_PutGatewayResponse_21626904; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a customization of a <a>GatewayResponse</a> of a specified response type and status code on the given <a>RestApi</a>.
  ## 
  let valid = call_21626917.validator(path, query, header, formData, body, _)
  let scheme = call_21626917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626917.makeUrl(scheme.get, call_21626917.host, call_21626917.base,
                               call_21626917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626917, uri, valid, _)

proc call*(call_21626918: Call_PutGatewayResponse_21626904; body: JsonNode;
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
  var path_21626919 = newJObject()
  var body_21626920 = newJObject()
  add(path_21626919, "response_type", newJString(responseType))
  if body != nil:
    body_21626920 = body
  add(path_21626919, "restapi_id", newJString(restapiId))
  result = call_21626918.call(path_21626919, nil, nil, nil, body_21626920)

var putGatewayResponse* = Call_PutGatewayResponse_21626904(
    name: "putGatewayResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_PutGatewayResponse_21626905, base: "/",
    makeUrl: url_PutGatewayResponse_21626906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponse_21626889 = ref object of OpenApiRestCall_21625418
proc url_GetGatewayResponse_21626891(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponse_21626890(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626892 = path.getOrDefault("response_type")
  valid_21626892 = validateParameter(valid_21626892, JString, required = true,
                                   default = newJString("DEFAULT_4XX"))
  if valid_21626892 != nil:
    section.add "response_type", valid_21626892
  var valid_21626893 = path.getOrDefault("restapi_id")
  valid_21626893 = validateParameter(valid_21626893, JString, required = true,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "restapi_id", valid_21626893
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626894 = header.getOrDefault("X-Amz-Date")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Date", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Security-Token", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Algorithm", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Signature")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Signature", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Credential")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Credential", valid_21626900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626901: Call_GetGatewayResponse_21626889; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_21626901.validator(path, query, header, formData, body, _)
  let scheme = call_21626901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626901.makeUrl(scheme.get, call_21626901.host, call_21626901.base,
                               call_21626901.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626901, uri, valid, _)

proc call*(call_21626902: Call_GetGatewayResponse_21626889; restapiId: string;
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
  var path_21626903 = newJObject()
  add(path_21626903, "response_type", newJString(responseType))
  add(path_21626903, "restapi_id", newJString(restapiId))
  result = call_21626902.call(path_21626903, nil, nil, nil, nil)

var getGatewayResponse* = Call_GetGatewayResponse_21626889(
    name: "getGatewayResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_GetGatewayResponse_21626890, base: "/",
    makeUrl: url_GetGatewayResponse_21626891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayResponse_21626936 = ref object of OpenApiRestCall_21625418
proc url_UpdateGatewayResponse_21626938(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_UpdateGatewayResponse_21626937(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626939 = path.getOrDefault("response_type")
  valid_21626939 = validateParameter(valid_21626939, JString, required = true,
                                   default = newJString("DEFAULT_4XX"))
  if valid_21626939 != nil:
    section.add "response_type", valid_21626939
  var valid_21626940 = path.getOrDefault("restapi_id")
  valid_21626940 = validateParameter(valid_21626940, JString, required = true,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "restapi_id", valid_21626940
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626941 = header.getOrDefault("X-Amz-Date")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Date", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Security-Token", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Algorithm", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Signature")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Signature", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Credential")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Credential", valid_21626947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626949: Call_UpdateGatewayResponse_21626936;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a>.
  ## 
  let valid = call_21626949.validator(path, query, header, formData, body, _)
  let scheme = call_21626949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626949.makeUrl(scheme.get, call_21626949.host, call_21626949.base,
                               call_21626949.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626949, uri, valid, _)

proc call*(call_21626950: Call_UpdateGatewayResponse_21626936; body: JsonNode;
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
  var path_21626951 = newJObject()
  var body_21626952 = newJObject()
  add(path_21626951, "response_type", newJString(responseType))
  if body != nil:
    body_21626952 = body
  add(path_21626951, "restapi_id", newJString(restapiId))
  result = call_21626950.call(path_21626951, nil, nil, nil, body_21626952)

var updateGatewayResponse* = Call_UpdateGatewayResponse_21626936(
    name: "updateGatewayResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_UpdateGatewayResponse_21626937, base: "/",
    makeUrl: url_UpdateGatewayResponse_21626938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayResponse_21626921 = ref object of OpenApiRestCall_21625418
proc url_DeleteGatewayResponse_21626923(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_DeleteGatewayResponse_21626922(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626924 = path.getOrDefault("response_type")
  valid_21626924 = validateParameter(valid_21626924, JString, required = true,
                                   default = newJString("DEFAULT_4XX"))
  if valid_21626924 != nil:
    section.add "response_type", valid_21626924
  var valid_21626925 = path.getOrDefault("restapi_id")
  valid_21626925 = validateParameter(valid_21626925, JString, required = true,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "restapi_id", valid_21626925
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626926 = header.getOrDefault("X-Amz-Date")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Date", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Security-Token", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Algorithm", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Signature")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Signature", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Credential")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Credential", valid_21626932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626933: Call_DeleteGatewayResponse_21626921;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Clears any customization of a <a>GatewayResponse</a> of a specified response type on the given <a>RestApi</a> and resets it with the default settings.
  ## 
  let valid = call_21626933.validator(path, query, header, formData, body, _)
  let scheme = call_21626933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626933.makeUrl(scheme.get, call_21626933.host, call_21626933.base,
                               call_21626933.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626933, uri, valid, _)

proc call*(call_21626934: Call_DeleteGatewayResponse_21626921; restapiId: string;
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
  var path_21626935 = newJObject()
  add(path_21626935, "response_type", newJString(responseType))
  add(path_21626935, "restapi_id", newJString(restapiId))
  result = call_21626934.call(path_21626935, nil, nil, nil, nil)

var deleteGatewayResponse* = Call_DeleteGatewayResponse_21626921(
    name: "deleteGatewayResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses/{response_type}",
    validator: validate_DeleteGatewayResponse_21626922, base: "/",
    makeUrl: url_DeleteGatewayResponse_21626923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegration_21626969 = ref object of OpenApiRestCall_21625418
proc url_PutIntegration_21626971(protocol: Scheme; host: string; base: string;
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

proc validate_PutIntegration_21626970(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626972 = path.getOrDefault("http_method")
  valid_21626972 = validateParameter(valid_21626972, JString, required = true,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "http_method", valid_21626972
  var valid_21626973 = path.getOrDefault("restapi_id")
  valid_21626973 = validateParameter(valid_21626973, JString, required = true,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "restapi_id", valid_21626973
  var valid_21626974 = path.getOrDefault("resource_id")
  valid_21626974 = validateParameter(valid_21626974, JString, required = true,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "resource_id", valid_21626974
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626975 = header.getOrDefault("X-Amz-Date")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Date", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Security-Token", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Algorithm", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Signature")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Signature", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Credential")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Credential", valid_21626981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626983: Call_PutIntegration_21626969; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets up a method's integration.
  ## 
  let valid = call_21626983.validator(path, query, header, formData, body, _)
  let scheme = call_21626983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626983.makeUrl(scheme.get, call_21626983.host, call_21626983.base,
                               call_21626983.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626983, uri, valid, _)

proc call*(call_21626984: Call_PutIntegration_21626969; httpMethod: string;
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
  var path_21626985 = newJObject()
  var body_21626986 = newJObject()
  add(path_21626985, "http_method", newJString(httpMethod))
  if body != nil:
    body_21626986 = body
  add(path_21626985, "restapi_id", newJString(restapiId))
  add(path_21626985, "resource_id", newJString(resourceId))
  result = call_21626984.call(path_21626985, nil, nil, nil, body_21626986)

var putIntegration* = Call_PutIntegration_21626969(name: "putIntegration",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_PutIntegration_21626970, base: "/",
    makeUrl: url_PutIntegration_21626971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_21626953 = ref object of OpenApiRestCall_21625418
proc url_GetIntegration_21626955(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_21626954(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626956 = path.getOrDefault("http_method")
  valid_21626956 = validateParameter(valid_21626956, JString, required = true,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "http_method", valid_21626956
  var valid_21626957 = path.getOrDefault("restapi_id")
  valid_21626957 = validateParameter(valid_21626957, JString, required = true,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "restapi_id", valid_21626957
  var valid_21626958 = path.getOrDefault("resource_id")
  valid_21626958 = validateParameter(valid_21626958, JString, required = true,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "resource_id", valid_21626958
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626959 = header.getOrDefault("X-Amz-Date")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Date", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Security-Token", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Algorithm", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Signature")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Signature", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Credential")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Credential", valid_21626965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626966: Call_GetIntegration_21626953; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the integration settings.
  ## 
  let valid = call_21626966.validator(path, query, header, formData, body, _)
  let scheme = call_21626966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626966.makeUrl(scheme.get, call_21626966.host, call_21626966.base,
                               call_21626966.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626966, uri, valid, _)

proc call*(call_21626967: Call_GetIntegration_21626953; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getIntegration
  ## Get the integration settings.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a get integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a get integration request's resource identifier
  var path_21626968 = newJObject()
  add(path_21626968, "http_method", newJString(httpMethod))
  add(path_21626968, "restapi_id", newJString(restapiId))
  add(path_21626968, "resource_id", newJString(resourceId))
  result = call_21626967.call(path_21626968, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_21626953(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_GetIntegration_21626954, base: "/",
    makeUrl: url_GetIntegration_21626955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_21627003 = ref object of OpenApiRestCall_21625418
proc url_UpdateIntegration_21627005(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_21627004(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627006 = path.getOrDefault("http_method")
  valid_21627006 = validateParameter(valid_21627006, JString, required = true,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "http_method", valid_21627006
  var valid_21627007 = path.getOrDefault("restapi_id")
  valid_21627007 = validateParameter(valid_21627007, JString, required = true,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "restapi_id", valid_21627007
  var valid_21627008 = path.getOrDefault("resource_id")
  valid_21627008 = validateParameter(valid_21627008, JString, required = true,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "resource_id", valid_21627008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627009 = header.getOrDefault("X-Amz-Date")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Date", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Security-Token", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Algorithm", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Signature")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Signature", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Credential")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Credential", valid_21627015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627017: Call_UpdateIntegration_21627003; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents an update integration.
  ## 
  let valid = call_21627017.validator(path, query, header, formData, body, _)
  let scheme = call_21627017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627017.makeUrl(scheme.get, call_21627017.host, call_21627017.base,
                               call_21627017.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627017, uri, valid, _)

proc call*(call_21627018: Call_UpdateIntegration_21627003; httpMethod: string;
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
  var path_21627019 = newJObject()
  var body_21627020 = newJObject()
  add(path_21627019, "http_method", newJString(httpMethod))
  if body != nil:
    body_21627020 = body
  add(path_21627019, "restapi_id", newJString(restapiId))
  add(path_21627019, "resource_id", newJString(resourceId))
  result = call_21627018.call(path_21627019, nil, nil, nil, body_21627020)

var updateIntegration* = Call_UpdateIntegration_21627003(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_UpdateIntegration_21627004, base: "/",
    makeUrl: url_UpdateIntegration_21627005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_21626987 = ref object of OpenApiRestCall_21625418
proc url_DeleteIntegration_21626989(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_21626988(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626990 = path.getOrDefault("http_method")
  valid_21626990 = validateParameter(valid_21626990, JString, required = true,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "http_method", valid_21626990
  var valid_21626991 = path.getOrDefault("restapi_id")
  valid_21626991 = validateParameter(valid_21626991, JString, required = true,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "restapi_id", valid_21626991
  var valid_21626992 = path.getOrDefault("resource_id")
  valid_21626992 = validateParameter(valid_21626992, JString, required = true,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "resource_id", valid_21626992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626993 = header.getOrDefault("X-Amz-Date")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Date", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Security-Token", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Algorithm", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Signature")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Signature", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Credential")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Credential", valid_21626999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627000: Call_DeleteIntegration_21626987; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a delete integration.
  ## 
  let valid = call_21627000.validator(path, query, header, formData, body, _)
  let scheme = call_21627000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627000.makeUrl(scheme.get, call_21627000.host, call_21627000.base,
                               call_21627000.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627000, uri, valid, _)

proc call*(call_21627001: Call_DeleteIntegration_21626987; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteIntegration
  ## Represents a delete integration.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies a delete integration request's HTTP method.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] Specifies a delete integration request's resource identifier.
  var path_21627002 = newJObject()
  add(path_21627002, "http_method", newJString(httpMethod))
  add(path_21627002, "restapi_id", newJString(restapiId))
  add(path_21627002, "resource_id", newJString(resourceId))
  result = call_21627001.call(path_21627002, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_21626987(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration",
    validator: validate_DeleteIntegration_21626988, base: "/",
    makeUrl: url_DeleteIntegration_21626989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntegrationResponse_21627038 = ref object of OpenApiRestCall_21625418
proc url_PutIntegrationResponse_21627040(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_PutIntegrationResponse_21627039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627041 = path.getOrDefault("http_method")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "http_method", valid_21627041
  var valid_21627042 = path.getOrDefault("status_code")
  valid_21627042 = validateParameter(valid_21627042, JString, required = true,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "status_code", valid_21627042
  var valid_21627043 = path.getOrDefault("restapi_id")
  valid_21627043 = validateParameter(valid_21627043, JString, required = true,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "restapi_id", valid_21627043
  var valid_21627044 = path.getOrDefault("resource_id")
  valid_21627044 = validateParameter(valid_21627044, JString, required = true,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "resource_id", valid_21627044
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627045 = header.getOrDefault("X-Amz-Date")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Date", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Security-Token", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Algorithm", valid_21627048
  var valid_21627049 = header.getOrDefault("X-Amz-Signature")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Signature", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Credential")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Credential", valid_21627051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627053: Call_PutIntegrationResponse_21627038;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a put integration.
  ## 
  let valid = call_21627053.validator(path, query, header, formData, body, _)
  let scheme = call_21627053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627053.makeUrl(scheme.get, call_21627053.host, call_21627053.base,
                               call_21627053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627053, uri, valid, _)

proc call*(call_21627054: Call_PutIntegrationResponse_21627038; httpMethod: string;
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
  var path_21627055 = newJObject()
  var body_21627056 = newJObject()
  add(path_21627055, "http_method", newJString(httpMethod))
  add(path_21627055, "status_code", newJString(statusCode))
  if body != nil:
    body_21627056 = body
  add(path_21627055, "restapi_id", newJString(restapiId))
  add(path_21627055, "resource_id", newJString(resourceId))
  result = call_21627054.call(path_21627055, nil, nil, nil, body_21627056)

var putIntegrationResponse* = Call_PutIntegrationResponse_21627038(
    name: "putIntegrationResponse", meth: HttpMethod.HttpPut,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_PutIntegrationResponse_21627039, base: "/",
    makeUrl: url_PutIntegrationResponse_21627040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_21627021 = ref object of OpenApiRestCall_21625418
proc url_GetIntegrationResponse_21627023(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_GetIntegrationResponse_21627022(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627024 = path.getOrDefault("http_method")
  valid_21627024 = validateParameter(valid_21627024, JString, required = true,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "http_method", valid_21627024
  var valid_21627025 = path.getOrDefault("status_code")
  valid_21627025 = validateParameter(valid_21627025, JString, required = true,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "status_code", valid_21627025
  var valid_21627026 = path.getOrDefault("restapi_id")
  valid_21627026 = validateParameter(valid_21627026, JString, required = true,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "restapi_id", valid_21627026
  var valid_21627027 = path.getOrDefault("resource_id")
  valid_21627027 = validateParameter(valid_21627027, JString, required = true,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "resource_id", valid_21627027
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627028 = header.getOrDefault("X-Amz-Date")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Date", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Security-Token", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Algorithm", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-Signature")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Signature", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Credential")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Credential", valid_21627034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627035: Call_GetIntegrationResponse_21627021;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a get integration response.
  ## 
  let valid = call_21627035.validator(path, query, header, formData, body, _)
  let scheme = call_21627035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627035.makeUrl(scheme.get, call_21627035.host, call_21627035.base,
                               call_21627035.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627035, uri, valid, _)

proc call*(call_21627036: Call_GetIntegrationResponse_21627021; httpMethod: string;
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
  var path_21627037 = newJObject()
  add(path_21627037, "http_method", newJString(httpMethod))
  add(path_21627037, "status_code", newJString(statusCode))
  add(path_21627037, "restapi_id", newJString(restapiId))
  add(path_21627037, "resource_id", newJString(resourceId))
  result = call_21627036.call(path_21627037, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_21627021(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_GetIntegrationResponse_21627022, base: "/",
    makeUrl: url_GetIntegrationResponse_21627023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_21627074 = ref object of OpenApiRestCall_21625418
proc url_UpdateIntegrationResponse_21627076(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_21627075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627077 = path.getOrDefault("http_method")
  valid_21627077 = validateParameter(valid_21627077, JString, required = true,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "http_method", valid_21627077
  var valid_21627078 = path.getOrDefault("status_code")
  valid_21627078 = validateParameter(valid_21627078, JString, required = true,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "status_code", valid_21627078
  var valid_21627079 = path.getOrDefault("restapi_id")
  valid_21627079 = validateParameter(valid_21627079, JString, required = true,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "restapi_id", valid_21627079
  var valid_21627080 = path.getOrDefault("resource_id")
  valid_21627080 = validateParameter(valid_21627080, JString, required = true,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "resource_id", valid_21627080
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627081 = header.getOrDefault("X-Amz-Date")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Date", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Security-Token", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Algorithm", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Signature")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Signature", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Credential")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Credential", valid_21627087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627089: Call_UpdateIntegrationResponse_21627074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents an update integration response.
  ## 
  let valid = call_21627089.validator(path, query, header, formData, body, _)
  let scheme = call_21627089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627089.makeUrl(scheme.get, call_21627089.host, call_21627089.base,
                               call_21627089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627089, uri, valid, _)

proc call*(call_21627090: Call_UpdateIntegrationResponse_21627074;
          httpMethod: string; statusCode: string; body: JsonNode; restapiId: string;
          resourceId: string): Recallable =
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
  var path_21627091 = newJObject()
  var body_21627092 = newJObject()
  add(path_21627091, "http_method", newJString(httpMethod))
  add(path_21627091, "status_code", newJString(statusCode))
  if body != nil:
    body_21627092 = body
  add(path_21627091, "restapi_id", newJString(restapiId))
  add(path_21627091, "resource_id", newJString(resourceId))
  result = call_21627090.call(path_21627091, nil, nil, nil, body_21627092)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_21627074(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_UpdateIntegrationResponse_21627075, base: "/",
    makeUrl: url_UpdateIntegrationResponse_21627076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_21627057 = ref object of OpenApiRestCall_21625418
proc url_DeleteIntegrationResponse_21627059(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_21627058(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627060 = path.getOrDefault("http_method")
  valid_21627060 = validateParameter(valid_21627060, JString, required = true,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "http_method", valid_21627060
  var valid_21627061 = path.getOrDefault("status_code")
  valid_21627061 = validateParameter(valid_21627061, JString, required = true,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "status_code", valid_21627061
  var valid_21627062 = path.getOrDefault("restapi_id")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "restapi_id", valid_21627062
  var valid_21627063 = path.getOrDefault("resource_id")
  valid_21627063 = validateParameter(valid_21627063, JString, required = true,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "resource_id", valid_21627063
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627064 = header.getOrDefault("X-Amz-Date")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Date", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Security-Token", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Algorithm", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Signature")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Signature", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Credential")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Credential", valid_21627070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627071: Call_DeleteIntegrationResponse_21627057;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Represents a delete integration response.
  ## 
  let valid = call_21627071.validator(path, query, header, formData, body, _)
  let scheme = call_21627071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627071.makeUrl(scheme.get, call_21627071.host, call_21627071.base,
                               call_21627071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627071, uri, valid, _)

proc call*(call_21627072: Call_DeleteIntegrationResponse_21627057;
          httpMethod: string; statusCode: string; restapiId: string;
          resourceId: string): Recallable =
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
  var path_21627073 = newJObject()
  add(path_21627073, "http_method", newJString(httpMethod))
  add(path_21627073, "status_code", newJString(statusCode))
  add(path_21627073, "restapi_id", newJString(restapiId))
  add(path_21627073, "resource_id", newJString(resourceId))
  result = call_21627072.call(path_21627073, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_21627057(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/integration/responses/{status_code}",
    validator: validate_DeleteIntegrationResponse_21627058, base: "/",
    makeUrl: url_DeleteIntegrationResponse_21627059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethod_21627109 = ref object of OpenApiRestCall_21625418
proc url_PutMethod_21627111(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethod_21627110(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627112 = path.getOrDefault("http_method")
  valid_21627112 = validateParameter(valid_21627112, JString, required = true,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "http_method", valid_21627112
  var valid_21627113 = path.getOrDefault("restapi_id")
  valid_21627113 = validateParameter(valid_21627113, JString, required = true,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "restapi_id", valid_21627113
  var valid_21627114 = path.getOrDefault("resource_id")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "resource_id", valid_21627114
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627115 = header.getOrDefault("X-Amz-Date")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Date", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Security-Token", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Algorithm", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Signature")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Signature", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Credential")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Credential", valid_21627121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627123: Call_PutMethod_21627109; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a method to an existing <a>Resource</a> resource.
  ## 
  let valid = call_21627123.validator(path, query, header, formData, body, _)
  let scheme = call_21627123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627123.makeUrl(scheme.get, call_21627123.host, call_21627123.base,
                               call_21627123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627123, uri, valid, _)

proc call*(call_21627124: Call_PutMethod_21627109; httpMethod: string;
          body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## putMethod
  ## Add a method to an existing <a>Resource</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the new <a>Method</a> resource.
  var path_21627125 = newJObject()
  var body_21627126 = newJObject()
  add(path_21627125, "http_method", newJString(httpMethod))
  if body != nil:
    body_21627126 = body
  add(path_21627125, "restapi_id", newJString(restapiId))
  add(path_21627125, "resource_id", newJString(resourceId))
  result = call_21627124.call(path_21627125, nil, nil, nil, body_21627126)

var putMethod* = Call_PutMethod_21627109(name: "putMethod", meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                      validator: validate_PutMethod_21627110,
                                      base: "/", makeUrl: url_PutMethod_21627111,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestInvokeMethod_21627127 = ref object of OpenApiRestCall_21625418
proc url_TestInvokeMethod_21627129(protocol: Scheme; host: string; base: string;
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

proc validate_TestInvokeMethod_21627128(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627130 = path.getOrDefault("http_method")
  valid_21627130 = validateParameter(valid_21627130, JString, required = true,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "http_method", valid_21627130
  var valid_21627131 = path.getOrDefault("restapi_id")
  valid_21627131 = validateParameter(valid_21627131, JString, required = true,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "restapi_id", valid_21627131
  var valid_21627132 = path.getOrDefault("resource_id")
  valid_21627132 = validateParameter(valid_21627132, JString, required = true,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "resource_id", valid_21627132
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627133 = header.getOrDefault("X-Amz-Date")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Date", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Security-Token", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Algorithm", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Signature")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Signature", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Credential")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Credential", valid_21627139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627141: Call_TestInvokeMethod_21627127; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Simulate the execution of a <a>Method</a> in your <a>RestApi</a> with headers, parameters, and an incoming request body.
  ## 
  let valid = call_21627141.validator(path, query, header, formData, body, _)
  let scheme = call_21627141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627141.makeUrl(scheme.get, call_21627141.host, call_21627141.base,
                               call_21627141.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627141, uri, valid, _)

proc call*(call_21627142: Call_TestInvokeMethod_21627127; httpMethod: string;
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
  var path_21627143 = newJObject()
  var body_21627144 = newJObject()
  add(path_21627143, "http_method", newJString(httpMethod))
  if body != nil:
    body_21627144 = body
  add(path_21627143, "restapi_id", newJString(restapiId))
  add(path_21627143, "resource_id", newJString(resourceId))
  result = call_21627142.call(path_21627143, nil, nil, nil, body_21627144)

var testInvokeMethod* = Call_TestInvokeMethod_21627127(name: "testInvokeMethod",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_TestInvokeMethod_21627128, base: "/",
    makeUrl: url_TestInvokeMethod_21627129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethod_21627093 = ref object of OpenApiRestCall_21625418
proc url_GetMethod_21627095(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethod_21627094(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627096 = path.getOrDefault("http_method")
  valid_21627096 = validateParameter(valid_21627096, JString, required = true,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "http_method", valid_21627096
  var valid_21627097 = path.getOrDefault("restapi_id")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "restapi_id", valid_21627097
  var valid_21627098 = path.getOrDefault("resource_id")
  valid_21627098 = validateParameter(valid_21627098, JString, required = true,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "resource_id", valid_21627098
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627099 = header.getOrDefault("X-Amz-Date")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Date", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Security-Token", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Algorithm", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Signature")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Signature", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Credential")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Credential", valid_21627105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627106: Call_GetMethod_21627093; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe an existing <a>Method</a> resource.
  ## 
  let valid = call_21627106.validator(path, query, header, formData, body, _)
  let scheme = call_21627106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627106.makeUrl(scheme.get, call_21627106.host, call_21627106.base,
                               call_21627106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627106, uri, valid, _)

proc call*(call_21627107: Call_GetMethod_21627093; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## getMethod
  ## Describe an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] Specifies the method request's HTTP method type.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_21627108 = newJObject()
  add(path_21627108, "http_method", newJString(httpMethod))
  add(path_21627108, "restapi_id", newJString(restapiId))
  add(path_21627108, "resource_id", newJString(resourceId))
  result = call_21627107.call(path_21627108, nil, nil, nil, nil)

var getMethod* = Call_GetMethod_21627093(name: "getMethod", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
                                      validator: validate_GetMethod_21627094,
                                      base: "/", makeUrl: url_GetMethod_21627095,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethod_21627161 = ref object of OpenApiRestCall_21625418
proc url_UpdateMethod_21627163(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethod_21627162(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627164 = path.getOrDefault("http_method")
  valid_21627164 = validateParameter(valid_21627164, JString, required = true,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "http_method", valid_21627164
  var valid_21627165 = path.getOrDefault("restapi_id")
  valid_21627165 = validateParameter(valid_21627165, JString, required = true,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "restapi_id", valid_21627165
  var valid_21627166 = path.getOrDefault("resource_id")
  valid_21627166 = validateParameter(valid_21627166, JString, required = true,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "resource_id", valid_21627166
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627167 = header.getOrDefault("X-Amz-Date")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Date", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Security-Token", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Algorithm", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Signature")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-Signature", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Credential")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Credential", valid_21627173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627175: Call_UpdateMethod_21627161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing <a>Method</a> resource.
  ## 
  let valid = call_21627175.validator(path, query, header, formData, body, _)
  let scheme = call_21627175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627175.makeUrl(scheme.get, call_21627175.host, call_21627175.base,
                               call_21627175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627175, uri, valid, _)

proc call*(call_21627176: Call_UpdateMethod_21627161; httpMethod: string;
          body: JsonNode; restapiId: string; resourceId: string): Recallable =
  ## updateMethod
  ## Updates an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_21627177 = newJObject()
  var body_21627178 = newJObject()
  add(path_21627177, "http_method", newJString(httpMethod))
  if body != nil:
    body_21627178 = body
  add(path_21627177, "restapi_id", newJString(restapiId))
  add(path_21627177, "resource_id", newJString(resourceId))
  result = call_21627176.call(path_21627177, nil, nil, nil, body_21627178)

var updateMethod* = Call_UpdateMethod_21627161(name: "updateMethod",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_UpdateMethod_21627162, base: "/", makeUrl: url_UpdateMethod_21627163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethod_21627145 = ref object of OpenApiRestCall_21625418
proc url_DeleteMethod_21627147(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethod_21627146(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627148 = path.getOrDefault("http_method")
  valid_21627148 = validateParameter(valid_21627148, JString, required = true,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "http_method", valid_21627148
  var valid_21627149 = path.getOrDefault("restapi_id")
  valid_21627149 = validateParameter(valid_21627149, JString, required = true,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "restapi_id", valid_21627149
  var valid_21627150 = path.getOrDefault("resource_id")
  valid_21627150 = validateParameter(valid_21627150, JString, required = true,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "resource_id", valid_21627150
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627151 = header.getOrDefault("X-Amz-Date")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Date", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Security-Token", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Algorithm", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Signature")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Signature", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Credential")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Credential", valid_21627157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627158: Call_DeleteMethod_21627145; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing <a>Method</a> resource.
  ## 
  let valid = call_21627158.validator(path, query, header, formData, body, _)
  let scheme = call_21627158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627158.makeUrl(scheme.get, call_21627158.host, call_21627158.base,
                               call_21627158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627158, uri, valid, _)

proc call*(call_21627159: Call_DeleteMethod_21627145; httpMethod: string;
          restapiId: string; resourceId: string): Recallable =
  ## deleteMethod
  ## Deletes an existing <a>Method</a> resource.
  ##   httpMethod: string (required)
  ##             : [Required] The HTTP verb of the <a>Method</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The <a>Resource</a> identifier for the <a>Method</a> resource.
  var path_21627160 = newJObject()
  add(path_21627160, "http_method", newJString(httpMethod))
  add(path_21627160, "restapi_id", newJString(restapiId))
  add(path_21627160, "resource_id", newJString(resourceId))
  result = call_21627159.call(path_21627160, nil, nil, nil, nil)

var deleteMethod* = Call_DeleteMethod_21627145(name: "deleteMethod",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}",
    validator: validate_DeleteMethod_21627146, base: "/", makeUrl: url_DeleteMethod_21627147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMethodResponse_21627196 = ref object of OpenApiRestCall_21625418
proc url_PutMethodResponse_21627198(protocol: Scheme; host: string; base: string;
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

proc validate_PutMethodResponse_21627197(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627199 = path.getOrDefault("http_method")
  valid_21627199 = validateParameter(valid_21627199, JString, required = true,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "http_method", valid_21627199
  var valid_21627200 = path.getOrDefault("status_code")
  valid_21627200 = validateParameter(valid_21627200, JString, required = true,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "status_code", valid_21627200
  var valid_21627201 = path.getOrDefault("restapi_id")
  valid_21627201 = validateParameter(valid_21627201, JString, required = true,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "restapi_id", valid_21627201
  var valid_21627202 = path.getOrDefault("resource_id")
  valid_21627202 = validateParameter(valid_21627202, JString, required = true,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "resource_id", valid_21627202
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627203 = header.getOrDefault("X-Amz-Date")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Date", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Security-Token", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Algorithm", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Signature")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Signature", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Credential")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Credential", valid_21627209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627211: Call_PutMethodResponse_21627196; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a <a>MethodResponse</a> to an existing <a>Method</a> resource.
  ## 
  let valid = call_21627211.validator(path, query, header, formData, body, _)
  let scheme = call_21627211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627211.makeUrl(scheme.get, call_21627211.host, call_21627211.base,
                               call_21627211.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627211, uri, valid, _)

proc call*(call_21627212: Call_PutMethodResponse_21627196; httpMethod: string;
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
  var path_21627213 = newJObject()
  var body_21627214 = newJObject()
  add(path_21627213, "http_method", newJString(httpMethod))
  add(path_21627213, "status_code", newJString(statusCode))
  if body != nil:
    body_21627214 = body
  add(path_21627213, "restapi_id", newJString(restapiId))
  add(path_21627213, "resource_id", newJString(resourceId))
  result = call_21627212.call(path_21627213, nil, nil, nil, body_21627214)

var putMethodResponse* = Call_PutMethodResponse_21627196(name: "putMethodResponse",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_PutMethodResponse_21627197, base: "/",
    makeUrl: url_PutMethodResponse_21627198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMethodResponse_21627179 = ref object of OpenApiRestCall_21625418
proc url_GetMethodResponse_21627181(protocol: Scheme; host: string; base: string;
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

proc validate_GetMethodResponse_21627180(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627182 = path.getOrDefault("http_method")
  valid_21627182 = validateParameter(valid_21627182, JString, required = true,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "http_method", valid_21627182
  var valid_21627183 = path.getOrDefault("status_code")
  valid_21627183 = validateParameter(valid_21627183, JString, required = true,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "status_code", valid_21627183
  var valid_21627184 = path.getOrDefault("restapi_id")
  valid_21627184 = validateParameter(valid_21627184, JString, required = true,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "restapi_id", valid_21627184
  var valid_21627185 = path.getOrDefault("resource_id")
  valid_21627185 = validateParameter(valid_21627185, JString, required = true,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "resource_id", valid_21627185
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627186 = header.getOrDefault("X-Amz-Date")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Date", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Security-Token", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Algorithm", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Signature")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Signature", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Credential")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Credential", valid_21627192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627193: Call_GetMethodResponse_21627179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a <a>MethodResponse</a> resource.
  ## 
  let valid = call_21627193.validator(path, query, header, formData, body, _)
  let scheme = call_21627193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627193.makeUrl(scheme.get, call_21627193.host, call_21627193.base,
                               call_21627193.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627193, uri, valid, _)

proc call*(call_21627194: Call_GetMethodResponse_21627179; httpMethod: string;
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
  var path_21627195 = newJObject()
  add(path_21627195, "http_method", newJString(httpMethod))
  add(path_21627195, "status_code", newJString(statusCode))
  add(path_21627195, "restapi_id", newJString(restapiId))
  add(path_21627195, "resource_id", newJString(resourceId))
  result = call_21627194.call(path_21627195, nil, nil, nil, nil)

var getMethodResponse* = Call_GetMethodResponse_21627179(name: "getMethodResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_GetMethodResponse_21627180, base: "/",
    makeUrl: url_GetMethodResponse_21627181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMethodResponse_21627232 = ref object of OpenApiRestCall_21625418
proc url_UpdateMethodResponse_21627234(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMethodResponse_21627233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627235 = path.getOrDefault("http_method")
  valid_21627235 = validateParameter(valid_21627235, JString, required = true,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "http_method", valid_21627235
  var valid_21627236 = path.getOrDefault("status_code")
  valid_21627236 = validateParameter(valid_21627236, JString, required = true,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "status_code", valid_21627236
  var valid_21627237 = path.getOrDefault("restapi_id")
  valid_21627237 = validateParameter(valid_21627237, JString, required = true,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "restapi_id", valid_21627237
  var valid_21627238 = path.getOrDefault("resource_id")
  valid_21627238 = validateParameter(valid_21627238, JString, required = true,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "resource_id", valid_21627238
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627239 = header.getOrDefault("X-Amz-Date")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Date", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Security-Token", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Algorithm", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Signature")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Signature", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-Credential")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-Credential", valid_21627245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627247: Call_UpdateMethodResponse_21627232; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_21627247.validator(path, query, header, formData, body, _)
  let scheme = call_21627247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627247.makeUrl(scheme.get, call_21627247.host, call_21627247.base,
                               call_21627247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627247, uri, valid, _)

proc call*(call_21627248: Call_UpdateMethodResponse_21627232; httpMethod: string;
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
  var path_21627249 = newJObject()
  var body_21627250 = newJObject()
  add(path_21627249, "http_method", newJString(httpMethod))
  add(path_21627249, "status_code", newJString(statusCode))
  if body != nil:
    body_21627250 = body
  add(path_21627249, "restapi_id", newJString(restapiId))
  add(path_21627249, "resource_id", newJString(resourceId))
  result = call_21627248.call(path_21627249, nil, nil, nil, body_21627250)

var updateMethodResponse* = Call_UpdateMethodResponse_21627232(
    name: "updateMethodResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_UpdateMethodResponse_21627233, base: "/",
    makeUrl: url_UpdateMethodResponse_21627234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMethodResponse_21627215 = ref object of OpenApiRestCall_21625418
proc url_DeleteMethodResponse_21627217(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMethodResponse_21627216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627218 = path.getOrDefault("http_method")
  valid_21627218 = validateParameter(valid_21627218, JString, required = true,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "http_method", valid_21627218
  var valid_21627219 = path.getOrDefault("status_code")
  valid_21627219 = validateParameter(valid_21627219, JString, required = true,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "status_code", valid_21627219
  var valid_21627220 = path.getOrDefault("restapi_id")
  valid_21627220 = validateParameter(valid_21627220, JString, required = true,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "restapi_id", valid_21627220
  var valid_21627221 = path.getOrDefault("resource_id")
  valid_21627221 = validateParameter(valid_21627221, JString, required = true,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "resource_id", valid_21627221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627222 = header.getOrDefault("X-Amz-Date")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Date", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Security-Token", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Algorithm", valid_21627225
  var valid_21627226 = header.getOrDefault("X-Amz-Signature")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-Signature", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Credential")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Credential", valid_21627228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627229: Call_DeleteMethodResponse_21627215; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing <a>MethodResponse</a> resource.
  ## 
  let valid = call_21627229.validator(path, query, header, formData, body, _)
  let scheme = call_21627229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627229.makeUrl(scheme.get, call_21627229.host, call_21627229.base,
                               call_21627229.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627229, uri, valid, _)

proc call*(call_21627230: Call_DeleteMethodResponse_21627215; httpMethod: string;
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
  var path_21627231 = newJObject()
  add(path_21627231, "http_method", newJString(httpMethod))
  add(path_21627231, "status_code", newJString(statusCode))
  add(path_21627231, "restapi_id", newJString(restapiId))
  add(path_21627231, "resource_id", newJString(resourceId))
  result = call_21627230.call(path_21627231, nil, nil, nil, nil)

var deleteMethodResponse* = Call_DeleteMethodResponse_21627215(
    name: "deleteMethodResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}/responses/{status_code}",
    validator: validate_DeleteMethodResponse_21627216, base: "/",
    makeUrl: url_DeleteMethodResponse_21627217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_21627251 = ref object of OpenApiRestCall_21625418
proc url_GetModel_21627253(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_21627252(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627254 = path.getOrDefault("model_name")
  valid_21627254 = validateParameter(valid_21627254, JString, required = true,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "model_name", valid_21627254
  var valid_21627255 = path.getOrDefault("restapi_id")
  valid_21627255 = validateParameter(valid_21627255, JString, required = true,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "restapi_id", valid_21627255
  result.add "path", section
  ## parameters in `query` object:
  ##   flatten: JBool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  section = newJObject()
  var valid_21627256 = query.getOrDefault("flatten")
  valid_21627256 = validateParameter(valid_21627256, JBool, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "flatten", valid_21627256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627257 = header.getOrDefault("X-Amz-Date")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Date", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Security-Token", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Algorithm", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-Signature")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Signature", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-Credential")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Credential", valid_21627263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627264: Call_GetModel_21627251; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ## 
  let valid = call_21627264.validator(path, query, header, formData, body, _)
  let scheme = call_21627264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627264.makeUrl(scheme.get, call_21627264.host, call_21627264.base,
                               call_21627264.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627264, uri, valid, _)

proc call*(call_21627265: Call_GetModel_21627251; modelName: string;
          restapiId: string; flatten: bool = false): Recallable =
  ## getModel
  ## Describes an existing model defined for a <a>RestApi</a> resource.
  ##   flatten: bool
  ##          : A query parameter of a Boolean value to resolve (<code>true</code>) all external model references and returns a flattened model schema or not (<code>false</code>) The default is <code>false</code>.
  ##   modelName: string (required)
  ##            : [Required] The name of the model as an identifier.
  ##   restapiId: string (required)
  ##            : [Required] The <a>RestApi</a> identifier under which the <a>Model</a> exists.
  var path_21627266 = newJObject()
  var query_21627267 = newJObject()
  add(query_21627267, "flatten", newJBool(flatten))
  add(path_21627266, "model_name", newJString(modelName))
  add(path_21627266, "restapi_id", newJString(restapiId))
  result = call_21627265.call(path_21627266, query_21627267, nil, nil, nil)

var getModel* = Call_GetModel_21627251(name: "getModel", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/models/{model_name}",
                                    validator: validate_GetModel_21627252,
                                    base: "/", makeUrl: url_GetModel_21627253,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_21627283 = ref object of OpenApiRestCall_21625418
proc url_UpdateModel_21627285(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_21627284(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627286 = path.getOrDefault("model_name")
  valid_21627286 = validateParameter(valid_21627286, JString, required = true,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "model_name", valid_21627286
  var valid_21627287 = path.getOrDefault("restapi_id")
  valid_21627287 = validateParameter(valid_21627287, JString, required = true,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "restapi_id", valid_21627287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627288 = header.getOrDefault("X-Amz-Date")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "X-Amz-Date", valid_21627288
  var valid_21627289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627289 = validateParameter(valid_21627289, JString, required = false,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "X-Amz-Security-Token", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Algorithm", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Signature")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Signature", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Credential")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Credential", valid_21627294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627296: Call_UpdateModel_21627283; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about a model.
  ## 
  let valid = call_21627296.validator(path, query, header, formData, body, _)
  let scheme = call_21627296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627296.makeUrl(scheme.get, call_21627296.host, call_21627296.base,
                               call_21627296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627296, uri, valid, _)

proc call*(call_21627297: Call_UpdateModel_21627283; modelName: string;
          body: JsonNode; restapiId: string): Recallable =
  ## updateModel
  ## Changes information about a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to update.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627298 = newJObject()
  var body_21627299 = newJObject()
  add(path_21627298, "model_name", newJString(modelName))
  if body != nil:
    body_21627299 = body
  add(path_21627298, "restapi_id", newJString(restapiId))
  result = call_21627297.call(path_21627298, nil, nil, nil, body_21627299)

var updateModel* = Call_UpdateModel_21627283(name: "updateModel",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}",
    validator: validate_UpdateModel_21627284, base: "/", makeUrl: url_UpdateModel_21627285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_21627268 = ref object of OpenApiRestCall_21625418
proc url_DeleteModel_21627270(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_21627269(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627271 = path.getOrDefault("model_name")
  valid_21627271 = validateParameter(valid_21627271, JString, required = true,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "model_name", valid_21627271
  var valid_21627272 = path.getOrDefault("restapi_id")
  valid_21627272 = validateParameter(valid_21627272, JString, required = true,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "restapi_id", valid_21627272
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627273 = header.getOrDefault("X-Amz-Date")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Date", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Security-Token", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Algorithm", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Signature")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Signature", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Credential")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Credential", valid_21627279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627280: Call_DeleteModel_21627268; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a model.
  ## 
  let valid = call_21627280.validator(path, query, header, formData, body, _)
  let scheme = call_21627280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627280.makeUrl(scheme.get, call_21627280.host, call_21627280.base,
                               call_21627280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627280, uri, valid, _)

proc call*(call_21627281: Call_DeleteModel_21627268; modelName: string;
          restapiId: string): Recallable =
  ## deleteModel
  ## Deletes a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627282 = newJObject()
  add(path_21627282, "model_name", newJString(modelName))
  add(path_21627282, "restapi_id", newJString(restapiId))
  result = call_21627281.call(path_21627282, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_21627268(name: "deleteModel",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}",
    validator: validate_DeleteModel_21627269, base: "/", makeUrl: url_DeleteModel_21627270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestValidator_21627300 = ref object of OpenApiRestCall_21625418
proc url_GetRequestValidator_21627302(protocol: Scheme; host: string; base: string;
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

proc validate_GetRequestValidator_21627301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627303 = path.getOrDefault("requestvalidator_id")
  valid_21627303 = validateParameter(valid_21627303, JString, required = true,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "requestvalidator_id", valid_21627303
  var valid_21627304 = path.getOrDefault("restapi_id")
  valid_21627304 = validateParameter(valid_21627304, JString, required = true,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "restapi_id", valid_21627304
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627305 = header.getOrDefault("X-Amz-Date")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Date", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Security-Token", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Algorithm", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Signature")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Signature", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-Credential")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-Credential", valid_21627311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627312: Call_GetRequestValidator_21627300; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_21627312.validator(path, query, header, formData, body, _)
  let scheme = call_21627312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627312.makeUrl(scheme.get, call_21627312.host, call_21627312.base,
                               call_21627312.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627312, uri, valid, _)

proc call*(call_21627313: Call_GetRequestValidator_21627300;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## getRequestValidator
  ## Gets a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be retrieved.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627314 = newJObject()
  add(path_21627314, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_21627314, "restapi_id", newJString(restapiId))
  result = call_21627313.call(path_21627314, nil, nil, nil, nil)

var getRequestValidator* = Call_GetRequestValidator_21627300(
    name: "getRequestValidator", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_GetRequestValidator_21627301, base: "/",
    makeUrl: url_GetRequestValidator_21627302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRequestValidator_21627330 = ref object of OpenApiRestCall_21625418
proc url_UpdateRequestValidator_21627332(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_UpdateRequestValidator_21627331(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627333 = path.getOrDefault("requestvalidator_id")
  valid_21627333 = validateParameter(valid_21627333, JString, required = true,
                                   default = nil)
  if valid_21627333 != nil:
    section.add "requestvalidator_id", valid_21627333
  var valid_21627334 = path.getOrDefault("restapi_id")
  valid_21627334 = validateParameter(valid_21627334, JString, required = true,
                                   default = nil)
  if valid_21627334 != nil:
    section.add "restapi_id", valid_21627334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627335 = header.getOrDefault("X-Amz-Date")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "X-Amz-Date", valid_21627335
  var valid_21627336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "X-Amz-Security-Token", valid_21627336
  var valid_21627337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627337 = validateParameter(valid_21627337, JString, required = false,
                                   default = nil)
  if valid_21627337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Algorithm", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-Signature")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-Signature", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-Credential")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-Credential", valid_21627341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627343: Call_UpdateRequestValidator_21627330;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_21627343.validator(path, query, header, formData, body, _)
  let scheme = call_21627343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627343.makeUrl(scheme.get, call_21627343.host, call_21627343.base,
                               call_21627343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627343, uri, valid, _)

proc call*(call_21627344: Call_UpdateRequestValidator_21627330;
          requestvalidatorId: string; body: JsonNode; restapiId: string): Recallable =
  ## updateRequestValidator
  ## Updates a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of <a>RequestValidator</a> to be updated.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627345 = newJObject()
  var body_21627346 = newJObject()
  add(path_21627345, "requestvalidator_id", newJString(requestvalidatorId))
  if body != nil:
    body_21627346 = body
  add(path_21627345, "restapi_id", newJString(restapiId))
  result = call_21627344.call(path_21627345, nil, nil, nil, body_21627346)

var updateRequestValidator* = Call_UpdateRequestValidator_21627330(
    name: "updateRequestValidator", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_UpdateRequestValidator_21627331, base: "/",
    makeUrl: url_UpdateRequestValidator_21627332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRequestValidator_21627315 = ref object of OpenApiRestCall_21625418
proc url_DeleteRequestValidator_21627317(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_DeleteRequestValidator_21627316(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627318 = path.getOrDefault("requestvalidator_id")
  valid_21627318 = validateParameter(valid_21627318, JString, required = true,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "requestvalidator_id", valid_21627318
  var valid_21627319 = path.getOrDefault("restapi_id")
  valid_21627319 = validateParameter(valid_21627319, JString, required = true,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "restapi_id", valid_21627319
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627320 = header.getOrDefault("X-Amz-Date")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Date", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Security-Token", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Algorithm", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Signature")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Signature", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-Credential")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-Credential", valid_21627326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627327: Call_DeleteRequestValidator_21627315;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ## 
  let valid = call_21627327.validator(path, query, header, formData, body, _)
  let scheme = call_21627327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627327.makeUrl(scheme.get, call_21627327.host, call_21627327.base,
                               call_21627327.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627327, uri, valid, _)

proc call*(call_21627328: Call_DeleteRequestValidator_21627315;
          requestvalidatorId: string; restapiId: string): Recallable =
  ## deleteRequestValidator
  ## Deletes a <a>RequestValidator</a> of a given <a>RestApi</a>.
  ##   requestvalidatorId: string (required)
  ##                     : [Required] The identifier of the <a>RequestValidator</a> to be deleted.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627329 = newJObject()
  add(path_21627329, "requestvalidator_id", newJString(requestvalidatorId))
  add(path_21627329, "restapi_id", newJString(restapiId))
  result = call_21627328.call(path_21627329, nil, nil, nil, nil)

var deleteRequestValidator* = Call_DeleteRequestValidator_21627315(
    name: "deleteRequestValidator", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/requestvalidators/{requestvalidator_id}",
    validator: validate_DeleteRequestValidator_21627316, base: "/",
    makeUrl: url_DeleteRequestValidator_21627317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResource_21627347 = ref object of OpenApiRestCall_21625418
proc url_GetResource_21627349(protocol: Scheme; host: string; base: string;
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

proc validate_GetResource_21627348(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627350 = path.getOrDefault("restapi_id")
  valid_21627350 = validateParameter(valid_21627350, JString, required = true,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "restapi_id", valid_21627350
  var valid_21627351 = path.getOrDefault("resource_id")
  valid_21627351 = validateParameter(valid_21627351, JString, required = true,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "resource_id", valid_21627351
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  section = newJObject()
  var valid_21627352 = query.getOrDefault("embed")
  valid_21627352 = validateParameter(valid_21627352, JArray, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "embed", valid_21627352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627353 = header.getOrDefault("X-Amz-Date")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Date", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Security-Token", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-Algorithm", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Signature")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Signature", valid_21627357
  var valid_21627358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-Credential")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-Credential", valid_21627359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627360: Call_GetResource_21627347; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about a resource.
  ## 
  let valid = call_21627360.validator(path, query, header, formData, body, _)
  let scheme = call_21627360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627360.makeUrl(scheme.get, call_21627360.host, call_21627360.base,
                               call_21627360.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627360, uri, valid, _)

proc call*(call_21627361: Call_GetResource_21627347; restapiId: string;
          resourceId: string; embed: JsonNode = nil): Recallable =
  ## getResource
  ## Lists information about a resource.
  ##   embed: JArray
  ##        : A query parameter to retrieve the specified resources embedded in the returned <a>Resource</a> representation in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources/{resource_id}?embed=methods</code>.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier for the <a>Resource</a> resource.
  var path_21627362 = newJObject()
  var query_21627363 = newJObject()
  if embed != nil:
    query_21627363.add "embed", embed
  add(path_21627362, "restapi_id", newJString(restapiId))
  add(path_21627362, "resource_id", newJString(resourceId))
  result = call_21627361.call(path_21627362, query_21627363, nil, nil, nil)

var getResource* = Call_GetResource_21627347(name: "getResource",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_GetResource_21627348, base: "/", makeUrl: url_GetResource_21627349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_21627379 = ref object of OpenApiRestCall_21625418
proc url_UpdateResource_21627381(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResource_21627380(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627382 = path.getOrDefault("restapi_id")
  valid_21627382 = validateParameter(valid_21627382, JString, required = true,
                                   default = nil)
  if valid_21627382 != nil:
    section.add "restapi_id", valid_21627382
  var valid_21627383 = path.getOrDefault("resource_id")
  valid_21627383 = validateParameter(valid_21627383, JString, required = true,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "resource_id", valid_21627383
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627384 = header.getOrDefault("X-Amz-Date")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "X-Amz-Date", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "X-Amz-Security-Token", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Algorithm", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-Signature")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Signature", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Credential")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Credential", valid_21627390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627392: Call_UpdateResource_21627379; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about a <a>Resource</a> resource.
  ## 
  let valid = call_21627392.validator(path, query, header, formData, body, _)
  let scheme = call_21627392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627392.makeUrl(scheme.get, call_21627392.host, call_21627392.base,
                               call_21627392.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627392, uri, valid, _)

proc call*(call_21627393: Call_UpdateResource_21627379; body: JsonNode;
          restapiId: string; resourceId: string): Recallable =
  ## updateResource
  ## Changes information about a <a>Resource</a> resource.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_21627394 = newJObject()
  var body_21627395 = newJObject()
  if body != nil:
    body_21627395 = body
  add(path_21627394, "restapi_id", newJString(restapiId))
  add(path_21627394, "resource_id", newJString(resourceId))
  result = call_21627393.call(path_21627394, nil, nil, nil, body_21627395)

var updateResource* = Call_UpdateResource_21627379(name: "updateResource",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_UpdateResource_21627380, base: "/",
    makeUrl: url_UpdateResource_21627381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_21627364 = ref object of OpenApiRestCall_21625418
proc url_DeleteResource_21627366(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResource_21627365(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627367 = path.getOrDefault("restapi_id")
  valid_21627367 = validateParameter(valid_21627367, JString, required = true,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "restapi_id", valid_21627367
  var valid_21627368 = path.getOrDefault("resource_id")
  valid_21627368 = validateParameter(valid_21627368, JString, required = true,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "resource_id", valid_21627368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627369 = header.getOrDefault("X-Amz-Date")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Date", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-Security-Token", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Algorithm", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-Signature")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-Signature", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Credential")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Credential", valid_21627375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627376: Call_DeleteResource_21627364; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>Resource</a> resource.
  ## 
  let valid = call_21627376.validator(path, query, header, formData, body, _)
  let scheme = call_21627376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627376.makeUrl(scheme.get, call_21627376.host, call_21627376.base,
                               call_21627376.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627376, uri, valid, _)

proc call*(call_21627377: Call_DeleteResource_21627364; restapiId: string;
          resourceId: string): Recallable =
  ## deleteResource
  ## Deletes a <a>Resource</a> resource.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  ##   resourceId: string (required)
  ##             : [Required] The identifier of the <a>Resource</a> resource.
  var path_21627378 = newJObject()
  add(path_21627378, "restapi_id", newJString(restapiId))
  add(path_21627378, "resource_id", newJString(resourceId))
  result = call_21627377.call(path_21627378, nil, nil, nil, nil)

var deleteResource* = Call_DeleteResource_21627364(name: "deleteResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources/{resource_id}",
    validator: validate_DeleteResource_21627365, base: "/",
    makeUrl: url_DeleteResource_21627366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRestApi_21627410 = ref object of OpenApiRestCall_21625418
proc url_PutRestApi_21627412(protocol: Scheme; host: string; base: string;
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

proc validate_PutRestApi_21627411(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627413 = path.getOrDefault("restapi_id")
  valid_21627413 = validateParameter(valid_21627413, JString, required = true,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "restapi_id", valid_21627413
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
  var valid_21627414 = query.getOrDefault("parameters.0.value")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "parameters.0.value", valid_21627414
  var valid_21627415 = query.getOrDefault("parameters.2.value")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "parameters.2.value", valid_21627415
  var valid_21627416 = query.getOrDefault("parameters.1.key")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "parameters.1.key", valid_21627416
  var valid_21627417 = query.getOrDefault("mode")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = newJString("merge"))
  if valid_21627417 != nil:
    section.add "mode", valid_21627417
  var valid_21627418 = query.getOrDefault("parameters.0.key")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "parameters.0.key", valid_21627418
  var valid_21627419 = query.getOrDefault("parameters.2.key")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "parameters.2.key", valid_21627419
  var valid_21627420 = query.getOrDefault("failonwarnings")
  valid_21627420 = validateParameter(valid_21627420, JBool, required = false,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "failonwarnings", valid_21627420
  var valid_21627421 = query.getOrDefault("parameters.1.value")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "parameters.1.value", valid_21627421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627422 = header.getOrDefault("X-Amz-Date")
  valid_21627422 = validateParameter(valid_21627422, JString, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "X-Amz-Date", valid_21627422
  var valid_21627423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627423 = validateParameter(valid_21627423, JString, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "X-Amz-Security-Token", valid_21627423
  var valid_21627424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627424 = validateParameter(valid_21627424, JString, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627424
  var valid_21627425 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Algorithm", valid_21627425
  var valid_21627426 = header.getOrDefault("X-Amz-Signature")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "X-Amz-Signature", valid_21627426
  var valid_21627427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Credential")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Credential", valid_21627428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627430: Call_PutRestApi_21627410; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A feature of the API Gateway control service for updating an existing API with an input of external API definitions. The update can take the form of merging the supplied definition into the existing API or overwriting the existing API.
  ## 
  let valid = call_21627430.validator(path, query, header, formData, body, _)
  let scheme = call_21627430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627430.makeUrl(scheme.get, call_21627430.host, call_21627430.base,
                               call_21627430.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627430, uri, valid, _)

proc call*(call_21627431: Call_PutRestApi_21627410; body: JsonNode;
          restapiId: string; parameters0Value: string = "";
          parameters2Value: string = ""; parameters1Key: string = "";
          mode: string = "merge"; parameters0Key: string = "";
          parameters2Key: string = ""; failonwarnings: bool = false;
          parameters1Value: string = ""): Recallable =
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
  var path_21627432 = newJObject()
  var query_21627433 = newJObject()
  var body_21627434 = newJObject()
  add(query_21627433, "parameters.0.value", newJString(parameters0Value))
  add(query_21627433, "parameters.2.value", newJString(parameters2Value))
  add(query_21627433, "parameters.1.key", newJString(parameters1Key))
  add(query_21627433, "mode", newJString(mode))
  add(query_21627433, "parameters.0.key", newJString(parameters0Key))
  add(query_21627433, "parameters.2.key", newJString(parameters2Key))
  add(query_21627433, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_21627434 = body
  add(query_21627433, "parameters.1.value", newJString(parameters1Value))
  add(path_21627432, "restapi_id", newJString(restapiId))
  result = call_21627431.call(path_21627432, query_21627433, nil, nil, body_21627434)

var putRestApi* = Call_PutRestApi_21627410(name: "putRestApi",
                                        meth: HttpMethod.HttpPut,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}",
                                        validator: validate_PutRestApi_21627411,
                                        base: "/", makeUrl: url_PutRestApi_21627412,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestApi_21627396 = ref object of OpenApiRestCall_21625418
proc url_GetRestApi_21627398(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestApi_21627397(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627399 = path.getOrDefault("restapi_id")
  valid_21627399 = validateParameter(valid_21627399, JString, required = true,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "restapi_id", valid_21627399
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627400 = header.getOrDefault("X-Amz-Date")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Date", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Security-Token", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Algorithm", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Signature")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Signature", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627405
  var valid_21627406 = header.getOrDefault("X-Amz-Credential")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-Credential", valid_21627406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627407: Call_GetRestApi_21627396; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the <a>RestApi</a> resource in the collection.
  ## 
  let valid = call_21627407.validator(path, query, header, formData, body, _)
  let scheme = call_21627407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627407.makeUrl(scheme.get, call_21627407.host, call_21627407.base,
                               call_21627407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627407, uri, valid, _)

proc call*(call_21627408: Call_GetRestApi_21627396; restapiId: string): Recallable =
  ## getRestApi
  ## Lists the <a>RestApi</a> resource in the collection.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627409 = newJObject()
  add(path_21627409, "restapi_id", newJString(restapiId))
  result = call_21627408.call(path_21627409, nil, nil, nil, nil)

var getRestApi* = Call_GetRestApi_21627396(name: "getRestApi",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/restapis/{restapi_id}",
                                        validator: validate_GetRestApi_21627397,
                                        base: "/", makeUrl: url_GetRestApi_21627398,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRestApi_21627449 = ref object of OpenApiRestCall_21625418
proc url_UpdateRestApi_21627451(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRestApi_21627450(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627452 = path.getOrDefault("restapi_id")
  valid_21627452 = validateParameter(valid_21627452, JString, required = true,
                                   default = nil)
  if valid_21627452 != nil:
    section.add "restapi_id", valid_21627452
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627453 = header.getOrDefault("X-Amz-Date")
  valid_21627453 = validateParameter(valid_21627453, JString, required = false,
                                   default = nil)
  if valid_21627453 != nil:
    section.add "X-Amz-Date", valid_21627453
  var valid_21627454 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627454 = validateParameter(valid_21627454, JString, required = false,
                                   default = nil)
  if valid_21627454 != nil:
    section.add "X-Amz-Security-Token", valid_21627454
  var valid_21627455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627455 = validateParameter(valid_21627455, JString, required = false,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627455
  var valid_21627456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627456 = validateParameter(valid_21627456, JString, required = false,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "X-Amz-Algorithm", valid_21627456
  var valid_21627457 = header.getOrDefault("X-Amz-Signature")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "X-Amz-Signature", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Credential")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Credential", valid_21627459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627461: Call_UpdateRestApi_21627449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about the specified API.
  ## 
  let valid = call_21627461.validator(path, query, header, formData, body, _)
  let scheme = call_21627461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627461.makeUrl(scheme.get, call_21627461.host, call_21627461.base,
                               call_21627461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627461, uri, valid, _)

proc call*(call_21627462: Call_UpdateRestApi_21627449; body: JsonNode;
          restapiId: string): Recallable =
  ## updateRestApi
  ## Changes information about the specified API.
  ##   body: JObject (required)
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627463 = newJObject()
  var body_21627464 = newJObject()
  if body != nil:
    body_21627464 = body
  add(path_21627463, "restapi_id", newJString(restapiId))
  result = call_21627462.call(path_21627463, nil, nil, nil, body_21627464)

var updateRestApi* = Call_UpdateRestApi_21627449(name: "updateRestApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_UpdateRestApi_21627450,
    base: "/", makeUrl: url_UpdateRestApi_21627451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRestApi_21627435 = ref object of OpenApiRestCall_21625418
proc url_DeleteRestApi_21627437(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRestApi_21627436(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627438 = path.getOrDefault("restapi_id")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true,
                                   default = nil)
  if valid_21627438 != nil:
    section.add "restapi_id", valid_21627438
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627439 = header.getOrDefault("X-Amz-Date")
  valid_21627439 = validateParameter(valid_21627439, JString, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "X-Amz-Date", valid_21627439
  var valid_21627440 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Security-Token", valid_21627440
  var valid_21627441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Algorithm", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Signature")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Signature", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Credential")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Credential", valid_21627445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627446: Call_DeleteRestApi_21627435; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified API.
  ## 
  let valid = call_21627446.validator(path, query, header, formData, body, _)
  let scheme = call_21627446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627446.makeUrl(scheme.get, call_21627446.host, call_21627446.base,
                               call_21627446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627446, uri, valid, _)

proc call*(call_21627447: Call_DeleteRestApi_21627435; restapiId: string): Recallable =
  ## deleteRestApi
  ## Deletes the specified API.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627448 = newJObject()
  add(path_21627448, "restapi_id", newJString(restapiId))
  result = call_21627447.call(path_21627448, nil, nil, nil, nil)

var deleteRestApi* = Call_DeleteRestApi_21627435(name: "deleteRestApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}", validator: validate_DeleteRestApi_21627436,
    base: "/", makeUrl: url_DeleteRestApi_21627437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_21627465 = ref object of OpenApiRestCall_21625418
proc url_GetStage_21627467(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_21627466(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627468 = path.getOrDefault("stage_name")
  valid_21627468 = validateParameter(valid_21627468, JString, required = true,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "stage_name", valid_21627468
  var valid_21627469 = path.getOrDefault("restapi_id")
  valid_21627469 = validateParameter(valid_21627469, JString, required = true,
                                   default = nil)
  if valid_21627469 != nil:
    section.add "restapi_id", valid_21627469
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627470 = header.getOrDefault("X-Amz-Date")
  valid_21627470 = validateParameter(valid_21627470, JString, required = false,
                                   default = nil)
  if valid_21627470 != nil:
    section.add "X-Amz-Date", valid_21627470
  var valid_21627471 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627471 = validateParameter(valid_21627471, JString, required = false,
                                   default = nil)
  if valid_21627471 != nil:
    section.add "X-Amz-Security-Token", valid_21627471
  var valid_21627472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627472
  var valid_21627473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-Algorithm", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Signature")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Signature", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Credential")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Credential", valid_21627476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627477: Call_GetStage_21627465; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a <a>Stage</a> resource.
  ## 
  let valid = call_21627477.validator(path, query, header, formData, body, _)
  let scheme = call_21627477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627477.makeUrl(scheme.get, call_21627477.host, call_21627477.base,
                               call_21627477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627477, uri, valid, _)

proc call*(call_21627478: Call_GetStage_21627465; stageName: string;
          restapiId: string): Recallable =
  ## getStage
  ## Gets information about a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to get information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627479 = newJObject()
  add(path_21627479, "stage_name", newJString(stageName))
  add(path_21627479, "restapi_id", newJString(restapiId))
  result = call_21627478.call(path_21627479, nil, nil, nil, nil)

var getStage* = Call_GetStage_21627465(name: "getStage", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}",
                                    validator: validate_GetStage_21627466,
                                    base: "/", makeUrl: url_GetStage_21627467,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_21627495 = ref object of OpenApiRestCall_21625418
proc url_UpdateStage_21627497(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_21627496(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627498 = path.getOrDefault("stage_name")
  valid_21627498 = validateParameter(valid_21627498, JString, required = true,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "stage_name", valid_21627498
  var valid_21627499 = path.getOrDefault("restapi_id")
  valid_21627499 = validateParameter(valid_21627499, JString, required = true,
                                   default = nil)
  if valid_21627499 != nil:
    section.add "restapi_id", valid_21627499
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627500 = header.getOrDefault("X-Amz-Date")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-Date", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Security-Token", valid_21627501
  var valid_21627502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627502 = validateParameter(valid_21627502, JString, required = false,
                                   default = nil)
  if valid_21627502 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627502
  var valid_21627503 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-Algorithm", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Signature")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Signature", valid_21627504
  var valid_21627505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627505 = validateParameter(valid_21627505, JString, required = false,
                                   default = nil)
  if valid_21627505 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Credential")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Credential", valid_21627506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627508: Call_UpdateStage_21627495; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about a <a>Stage</a> resource.
  ## 
  let valid = call_21627508.validator(path, query, header, formData, body, _)
  let scheme = call_21627508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627508.makeUrl(scheme.get, call_21627508.host, call_21627508.base,
                               call_21627508.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627508, uri, valid, _)

proc call*(call_21627509: Call_UpdateStage_21627495; body: JsonNode;
          stageName: string; restapiId: string): Recallable =
  ## updateStage
  ## Changes information about a <a>Stage</a> resource.
  ##   body: JObject (required)
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to change information about.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627510 = newJObject()
  var body_21627511 = newJObject()
  if body != nil:
    body_21627511 = body
  add(path_21627510, "stage_name", newJString(stageName))
  add(path_21627510, "restapi_id", newJString(restapiId))
  result = call_21627509.call(path_21627510, nil, nil, nil, body_21627511)

var updateStage* = Call_UpdateStage_21627495(name: "updateStage",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}",
    validator: validate_UpdateStage_21627496, base: "/", makeUrl: url_UpdateStage_21627497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_21627480 = ref object of OpenApiRestCall_21625418
proc url_DeleteStage_21627482(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_21627481(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627483 = path.getOrDefault("stage_name")
  valid_21627483 = validateParameter(valid_21627483, JString, required = true,
                                   default = nil)
  if valid_21627483 != nil:
    section.add "stage_name", valid_21627483
  var valid_21627484 = path.getOrDefault("restapi_id")
  valid_21627484 = validateParameter(valid_21627484, JString, required = true,
                                   default = nil)
  if valid_21627484 != nil:
    section.add "restapi_id", valid_21627484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627485 = header.getOrDefault("X-Amz-Date")
  valid_21627485 = validateParameter(valid_21627485, JString, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "X-Amz-Date", valid_21627485
  var valid_21627486 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627486 = validateParameter(valid_21627486, JString, required = false,
                                   default = nil)
  if valid_21627486 != nil:
    section.add "X-Amz-Security-Token", valid_21627486
  var valid_21627487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627487 = validateParameter(valid_21627487, JString, required = false,
                                   default = nil)
  if valid_21627487 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627487
  var valid_21627488 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-Algorithm", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Signature")
  valid_21627489 = validateParameter(valid_21627489, JString, required = false,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "X-Amz-Signature", valid_21627489
  var valid_21627490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627490 = validateParameter(valid_21627490, JString, required = false,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627490
  var valid_21627491 = header.getOrDefault("X-Amz-Credential")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Credential", valid_21627491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627492: Call_DeleteStage_21627480; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>Stage</a> resource.
  ## 
  let valid = call_21627492.validator(path, query, header, formData, body, _)
  let scheme = call_21627492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627492.makeUrl(scheme.get, call_21627492.host, call_21627492.base,
                               call_21627492.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627492, uri, valid, _)

proc call*(call_21627493: Call_DeleteStage_21627480; stageName: string;
          restapiId: string): Recallable =
  ## deleteStage
  ## Deletes a <a>Stage</a> resource.
  ##   stageName: string (required)
  ##            : [Required] The name of the <a>Stage</a> resource to delete.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627494 = newJObject()
  add(path_21627494, "stage_name", newJString(stageName))
  add(path_21627494, "restapi_id", newJString(restapiId))
  result = call_21627493.call(path_21627494, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_21627480(name: "deleteStage",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}",
    validator: validate_DeleteStage_21627481, base: "/", makeUrl: url_DeleteStage_21627482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlan_21627512 = ref object of OpenApiRestCall_21625418
proc url_GetUsagePlan_21627514(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlan_21627513(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627515 = path.getOrDefault("usageplanId")
  valid_21627515 = validateParameter(valid_21627515, JString, required = true,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "usageplanId", valid_21627515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627516 = header.getOrDefault("X-Amz-Date")
  valid_21627516 = validateParameter(valid_21627516, JString, required = false,
                                   default = nil)
  if valid_21627516 != nil:
    section.add "X-Amz-Date", valid_21627516
  var valid_21627517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627517 = validateParameter(valid_21627517, JString, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "X-Amz-Security-Token", valid_21627517
  var valid_21627518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627519 = validateParameter(valid_21627519, JString, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "X-Amz-Algorithm", valid_21627519
  var valid_21627520 = header.getOrDefault("X-Amz-Signature")
  valid_21627520 = validateParameter(valid_21627520, JString, required = false,
                                   default = nil)
  if valid_21627520 != nil:
    section.add "X-Amz-Signature", valid_21627520
  var valid_21627521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627521
  var valid_21627522 = header.getOrDefault("X-Amz-Credential")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "X-Amz-Credential", valid_21627522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627523: Call_GetUsagePlan_21627512; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a usage plan of a given plan identifier.
  ## 
  let valid = call_21627523.validator(path, query, header, formData, body, _)
  let scheme = call_21627523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627523.makeUrl(scheme.get, call_21627523.host, call_21627523.base,
                               call_21627523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627523, uri, valid, _)

proc call*(call_21627524: Call_GetUsagePlan_21627512; usageplanId: string): Recallable =
  ## getUsagePlan
  ## Gets a usage plan of a given plan identifier.
  ##   usageplanId: string (required)
  ##              : [Required] The identifier of the <a>UsagePlan</a> resource to be retrieved.
  var path_21627525 = newJObject()
  add(path_21627525, "usageplanId", newJString(usageplanId))
  result = call_21627524.call(path_21627525, nil, nil, nil, nil)

var getUsagePlan* = Call_GetUsagePlan_21627512(name: "getUsagePlan",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_GetUsagePlan_21627513,
    base: "/", makeUrl: url_GetUsagePlan_21627514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsagePlan_21627540 = ref object of OpenApiRestCall_21625418
proc url_UpdateUsagePlan_21627542(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsagePlan_21627541(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627543 = path.getOrDefault("usageplanId")
  valid_21627543 = validateParameter(valid_21627543, JString, required = true,
                                   default = nil)
  if valid_21627543 != nil:
    section.add "usageplanId", valid_21627543
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627544 = header.getOrDefault("X-Amz-Date")
  valid_21627544 = validateParameter(valid_21627544, JString, required = false,
                                   default = nil)
  if valid_21627544 != nil:
    section.add "X-Amz-Date", valid_21627544
  var valid_21627545 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Security-Token", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-Algorithm", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-Signature")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Signature", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627549 = validateParameter(valid_21627549, JString, required = false,
                                   default = nil)
  if valid_21627549 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627549
  var valid_21627550 = header.getOrDefault("X-Amz-Credential")
  valid_21627550 = validateParameter(valid_21627550, JString, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "X-Amz-Credential", valid_21627550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627552: Call_UpdateUsagePlan_21627540; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a usage plan of a given plan Id.
  ## 
  let valid = call_21627552.validator(path, query, header, formData, body, _)
  let scheme = call_21627552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627552.makeUrl(scheme.get, call_21627552.host, call_21627552.base,
                               call_21627552.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627552, uri, valid, _)

proc call*(call_21627553: Call_UpdateUsagePlan_21627540; usageplanId: string;
          body: JsonNode): Recallable =
  ## updateUsagePlan
  ## Updates a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-updated usage plan.
  ##   body: JObject (required)
  var path_21627554 = newJObject()
  var body_21627555 = newJObject()
  add(path_21627554, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_21627555 = body
  result = call_21627553.call(path_21627554, nil, nil, nil, body_21627555)

var updateUsagePlan* = Call_UpdateUsagePlan_21627540(name: "updateUsagePlan",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_UpdateUsagePlan_21627541,
    base: "/", makeUrl: url_UpdateUsagePlan_21627542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlan_21627526 = ref object of OpenApiRestCall_21625418
proc url_DeleteUsagePlan_21627528(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlan_21627527(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627529 = path.getOrDefault("usageplanId")
  valid_21627529 = validateParameter(valid_21627529, JString, required = true,
                                   default = nil)
  if valid_21627529 != nil:
    section.add "usageplanId", valid_21627529
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627530 = header.getOrDefault("X-Amz-Date")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "X-Amz-Date", valid_21627530
  var valid_21627531 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627531 = validateParameter(valid_21627531, JString, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "X-Amz-Security-Token", valid_21627531
  var valid_21627532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627532 = validateParameter(valid_21627532, JString, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627532
  var valid_21627533 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Algorithm", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Signature")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Signature", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Credential")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Credential", valid_21627536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627537: Call_DeleteUsagePlan_21627526; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a usage plan of a given plan Id.
  ## 
  let valid = call_21627537.validator(path, query, header, formData, body, _)
  let scheme = call_21627537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627537.makeUrl(scheme.get, call_21627537.host, call_21627537.base,
                               call_21627537.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627537, uri, valid, _)

proc call*(call_21627538: Call_DeleteUsagePlan_21627526; usageplanId: string): Recallable =
  ## deleteUsagePlan
  ## Deletes a usage plan of a given plan Id.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the to-be-deleted usage plan.
  var path_21627539 = newJObject()
  add(path_21627539, "usageplanId", newJString(usageplanId))
  result = call_21627538.call(path_21627539, nil, nil, nil, nil)

var deleteUsagePlan* = Call_DeleteUsagePlan_21627526(name: "deleteUsagePlan",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}", validator: validate_DeleteUsagePlan_21627527,
    base: "/", makeUrl: url_DeleteUsagePlan_21627528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsagePlanKey_21627556 = ref object of OpenApiRestCall_21625418
proc url_GetUsagePlanKey_21627558(protocol: Scheme; host: string; base: string;
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

proc validate_GetUsagePlanKey_21627557(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627559 = path.getOrDefault("keyId")
  valid_21627559 = validateParameter(valid_21627559, JString, required = true,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "keyId", valid_21627559
  var valid_21627560 = path.getOrDefault("usageplanId")
  valid_21627560 = validateParameter(valid_21627560, JString, required = true,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "usageplanId", valid_21627560
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627561 = header.getOrDefault("X-Amz-Date")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "X-Amz-Date", valid_21627561
  var valid_21627562 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627562 = validateParameter(valid_21627562, JString, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "X-Amz-Security-Token", valid_21627562
  var valid_21627563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627563
  var valid_21627564 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627564 = validateParameter(valid_21627564, JString, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "X-Amz-Algorithm", valid_21627564
  var valid_21627565 = header.getOrDefault("X-Amz-Signature")
  valid_21627565 = validateParameter(valid_21627565, JString, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "X-Amz-Signature", valid_21627565
  var valid_21627566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627566 = validateParameter(valid_21627566, JString, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627566
  var valid_21627567 = header.getOrDefault("X-Amz-Credential")
  valid_21627567 = validateParameter(valid_21627567, JString, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "X-Amz-Credential", valid_21627567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627568: Call_GetUsagePlanKey_21627556; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a usage plan key of a given key identifier.
  ## 
  let valid = call_21627568.validator(path, query, header, formData, body, _)
  let scheme = call_21627568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627568.makeUrl(scheme.get, call_21627568.host, call_21627568.base,
                               call_21627568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627568, uri, valid, _)

proc call*(call_21627569: Call_GetUsagePlanKey_21627556; keyId: string;
          usageplanId: string): Recallable =
  ## getUsagePlanKey
  ## Gets a usage plan key of a given key identifier.
  ##   keyId: string (required)
  ##        : [Required] The key Id of the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-retrieved <a>UsagePlanKey</a> resource representing a plan customer.
  var path_21627570 = newJObject()
  add(path_21627570, "keyId", newJString(keyId))
  add(path_21627570, "usageplanId", newJString(usageplanId))
  result = call_21627569.call(path_21627570, nil, nil, nil, nil)

var getUsagePlanKey* = Call_GetUsagePlanKey_21627556(name: "getUsagePlanKey",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_GetUsagePlanKey_21627557, base: "/",
    makeUrl: url_GetUsagePlanKey_21627558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUsagePlanKey_21627571 = ref object of OpenApiRestCall_21625418
proc url_DeleteUsagePlanKey_21627573(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUsagePlanKey_21627572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627574 = path.getOrDefault("keyId")
  valid_21627574 = validateParameter(valid_21627574, JString, required = true,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "keyId", valid_21627574
  var valid_21627575 = path.getOrDefault("usageplanId")
  valid_21627575 = validateParameter(valid_21627575, JString, required = true,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "usageplanId", valid_21627575
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627576 = header.getOrDefault("X-Amz-Date")
  valid_21627576 = validateParameter(valid_21627576, JString, required = false,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "X-Amz-Date", valid_21627576
  var valid_21627577 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627577 = validateParameter(valid_21627577, JString, required = false,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "X-Amz-Security-Token", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-Algorithm", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Signature")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Signature", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Credential")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Credential", valid_21627582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627583: Call_DeleteUsagePlanKey_21627571; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ## 
  let valid = call_21627583.validator(path, query, header, formData, body, _)
  let scheme = call_21627583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627583.makeUrl(scheme.get, call_21627583.host, call_21627583.base,
                               call_21627583.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627583, uri, valid, _)

proc call*(call_21627584: Call_DeleteUsagePlanKey_21627571; keyId: string;
          usageplanId: string): Recallable =
  ## deleteUsagePlanKey
  ## Deletes a usage plan key and remove the underlying API key from the associated usage plan.
  ##   keyId: string (required)
  ##        : [Required] The Id of the <a>UsagePlanKey</a> resource to be deleted.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the <a>UsagePlan</a> resource representing the usage plan containing the to-be-deleted <a>UsagePlanKey</a> resource representing a plan customer.
  var path_21627585 = newJObject()
  add(path_21627585, "keyId", newJString(keyId))
  add(path_21627585, "usageplanId", newJString(usageplanId))
  result = call_21627584.call(path_21627585, nil, nil, nil, nil)

var deleteUsagePlanKey* = Call_DeleteUsagePlanKey_21627571(
    name: "deleteUsagePlanKey", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}",
    validator: validate_DeleteUsagePlanKey_21627572, base: "/",
    makeUrl: url_DeleteUsagePlanKey_21627573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVpcLink_21627586 = ref object of OpenApiRestCall_21625418
proc url_GetVpcLink_21627588(protocol: Scheme; host: string; base: string;
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

proc validate_GetVpcLink_21627587(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627589 = path.getOrDefault("vpclink_id")
  valid_21627589 = validateParameter(valid_21627589, JString, required = true,
                                   default = nil)
  if valid_21627589 != nil:
    section.add "vpclink_id", valid_21627589
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627590 = header.getOrDefault("X-Amz-Date")
  valid_21627590 = validateParameter(valid_21627590, JString, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "X-Amz-Date", valid_21627590
  var valid_21627591 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "X-Amz-Security-Token", valid_21627591
  var valid_21627592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627592 = validateParameter(valid_21627592, JString, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Algorithm", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-Signature")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-Signature", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Credential")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Credential", valid_21627596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627597: Call_GetVpcLink_21627586; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a specified VPC link under the caller's account in a region.
  ## 
  let valid = call_21627597.validator(path, query, header, formData, body, _)
  let scheme = call_21627597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627597.makeUrl(scheme.get, call_21627597.host, call_21627597.base,
                               call_21627597.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627597, uri, valid, _)

proc call*(call_21627598: Call_GetVpcLink_21627586; vpclinkId: string): Recallable =
  ## getVpcLink
  ## Gets a specified VPC link under the caller's account in a region.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_21627599 = newJObject()
  add(path_21627599, "vpclink_id", newJString(vpclinkId))
  result = call_21627598.call(path_21627599, nil, nil, nil, nil)

var getVpcLink* = Call_GetVpcLink_21627586(name: "getVpcLink",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/vpclinks/{vpclink_id}",
                                        validator: validate_GetVpcLink_21627587,
                                        base: "/", makeUrl: url_GetVpcLink_21627588,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVpcLink_21627614 = ref object of OpenApiRestCall_21625418
proc url_UpdateVpcLink_21627616(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVpcLink_21627615(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627617 = path.getOrDefault("vpclink_id")
  valid_21627617 = validateParameter(valid_21627617, JString, required = true,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "vpclink_id", valid_21627617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627618 = header.getOrDefault("X-Amz-Date")
  valid_21627618 = validateParameter(valid_21627618, JString, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "X-Amz-Date", valid_21627618
  var valid_21627619 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627619 = validateParameter(valid_21627619, JString, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "X-Amz-Security-Token", valid_21627619
  var valid_21627620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627620
  var valid_21627621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627621 = validateParameter(valid_21627621, JString, required = false,
                                   default = nil)
  if valid_21627621 != nil:
    section.add "X-Amz-Algorithm", valid_21627621
  var valid_21627622 = header.getOrDefault("X-Amz-Signature")
  valid_21627622 = validateParameter(valid_21627622, JString, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "X-Amz-Signature", valid_21627622
  var valid_21627623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-Credential")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-Credential", valid_21627624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627626: Call_UpdateVpcLink_21627614; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_21627626.validator(path, query, header, formData, body, _)
  let scheme = call_21627626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627626.makeUrl(scheme.get, call_21627626.host, call_21627626.base,
                               call_21627626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627626, uri, valid, _)

proc call*(call_21627627: Call_UpdateVpcLink_21627614; body: JsonNode;
          vpclinkId: string): Recallable =
  ## updateVpcLink
  ## Updates an existing <a>VpcLink</a> of a specified identifier.
  ##   body: JObject (required)
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_21627628 = newJObject()
  var body_21627629 = newJObject()
  if body != nil:
    body_21627629 = body
  add(path_21627628, "vpclink_id", newJString(vpclinkId))
  result = call_21627627.call(path_21627628, nil, nil, nil, body_21627629)

var updateVpcLink* = Call_UpdateVpcLink_21627614(name: "updateVpcLink",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_UpdateVpcLink_21627615,
    base: "/", makeUrl: url_UpdateVpcLink_21627616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcLink_21627600 = ref object of OpenApiRestCall_21625418
proc url_DeleteVpcLink_21627602(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVpcLink_21627601(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627603 = path.getOrDefault("vpclink_id")
  valid_21627603 = validateParameter(valid_21627603, JString, required = true,
                                   default = nil)
  if valid_21627603 != nil:
    section.add "vpclink_id", valid_21627603
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627604 = header.getOrDefault("X-Amz-Date")
  valid_21627604 = validateParameter(valid_21627604, JString, required = false,
                                   default = nil)
  if valid_21627604 != nil:
    section.add "X-Amz-Date", valid_21627604
  var valid_21627605 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627605 = validateParameter(valid_21627605, JString, required = false,
                                   default = nil)
  if valid_21627605 != nil:
    section.add "X-Amz-Security-Token", valid_21627605
  var valid_21627606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627606 = validateParameter(valid_21627606, JString, required = false,
                                   default = nil)
  if valid_21627606 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627606
  var valid_21627607 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627607 = validateParameter(valid_21627607, JString, required = false,
                                   default = nil)
  if valid_21627607 != nil:
    section.add "X-Amz-Algorithm", valid_21627607
  var valid_21627608 = header.getOrDefault("X-Amz-Signature")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-Signature", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627609
  var valid_21627610 = header.getOrDefault("X-Amz-Credential")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "X-Amz-Credential", valid_21627610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627611: Call_DeleteVpcLink_21627600; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ## 
  let valid = call_21627611.validator(path, query, header, formData, body, _)
  let scheme = call_21627611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627611.makeUrl(scheme.get, call_21627611.host, call_21627611.base,
                               call_21627611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627611, uri, valid, _)

proc call*(call_21627612: Call_DeleteVpcLink_21627600; vpclinkId: string): Recallable =
  ## deleteVpcLink
  ## Deletes an existing <a>VpcLink</a> of a specified identifier.
  ##   vpclinkId: string (required)
  ##            : [Required] The identifier of the <a>VpcLink</a>. It is used in an <a>Integration</a> to reference this <a>VpcLink</a>.
  var path_21627613 = newJObject()
  add(path_21627613, "vpclink_id", newJString(vpclinkId))
  result = call_21627612.call(path_21627613, nil, nil, nil, nil)

var deleteVpcLink* = Call_DeleteVpcLink_21627600(name: "deleteVpcLink",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/vpclinks/{vpclink_id}", validator: validate_DeleteVpcLink_21627601,
    base: "/", makeUrl: url_DeleteVpcLink_21627602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageAuthorizersCache_21627630 = ref object of OpenApiRestCall_21625418
proc url_FlushStageAuthorizersCache_21627632(protocol: Scheme; host: string;
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

proc validate_FlushStageAuthorizersCache_21627631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627633 = path.getOrDefault("stage_name")
  valid_21627633 = validateParameter(valid_21627633, JString, required = true,
                                   default = nil)
  if valid_21627633 != nil:
    section.add "stage_name", valid_21627633
  var valid_21627634 = path.getOrDefault("restapi_id")
  valid_21627634 = validateParameter(valid_21627634, JString, required = true,
                                   default = nil)
  if valid_21627634 != nil:
    section.add "restapi_id", valid_21627634
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627635 = header.getOrDefault("X-Amz-Date")
  valid_21627635 = validateParameter(valid_21627635, JString, required = false,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "X-Amz-Date", valid_21627635
  var valid_21627636 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627636 = validateParameter(valid_21627636, JString, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "X-Amz-Security-Token", valid_21627636
  var valid_21627637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627637 = validateParameter(valid_21627637, JString, required = false,
                                   default = nil)
  if valid_21627637 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627637
  var valid_21627638 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Algorithm", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Signature")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Signature", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-Credential")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-Credential", valid_21627641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627642: Call_FlushStageAuthorizersCache_21627630;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Flushes all authorizer cache entries on a stage.
  ## 
  let valid = call_21627642.validator(path, query, header, formData, body, _)
  let scheme = call_21627642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627642.makeUrl(scheme.get, call_21627642.host, call_21627642.base,
                               call_21627642.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627642, uri, valid, _)

proc call*(call_21627643: Call_FlushStageAuthorizersCache_21627630;
          stageName: string; restapiId: string): Recallable =
  ## flushStageAuthorizersCache
  ## Flushes all authorizer cache entries on a stage.
  ##   stageName: string (required)
  ##            : The name of the stage to flush.
  ##   restapiId: string (required)
  ##            : The string identifier of the associated <a>RestApi</a>.
  var path_21627644 = newJObject()
  add(path_21627644, "stage_name", newJString(stageName))
  add(path_21627644, "restapi_id", newJString(restapiId))
  result = call_21627643.call(path_21627644, nil, nil, nil, nil)

var flushStageAuthorizersCache* = Call_FlushStageAuthorizersCache_21627630(
    name: "flushStageAuthorizersCache", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/authorizers",
    validator: validate_FlushStageAuthorizersCache_21627631, base: "/",
    makeUrl: url_FlushStageAuthorizersCache_21627632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushStageCache_21627645 = ref object of OpenApiRestCall_21625418
proc url_FlushStageCache_21627647(protocol: Scheme; host: string; base: string;
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

proc validate_FlushStageCache_21627646(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627648 = path.getOrDefault("stage_name")
  valid_21627648 = validateParameter(valid_21627648, JString, required = true,
                                   default = nil)
  if valid_21627648 != nil:
    section.add "stage_name", valid_21627648
  var valid_21627649 = path.getOrDefault("restapi_id")
  valid_21627649 = validateParameter(valid_21627649, JString, required = true,
                                   default = nil)
  if valid_21627649 != nil:
    section.add "restapi_id", valid_21627649
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627650 = header.getOrDefault("X-Amz-Date")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "X-Amz-Date", valid_21627650
  var valid_21627651 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627651 = validateParameter(valid_21627651, JString, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "X-Amz-Security-Token", valid_21627651
  var valid_21627652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627652 = validateParameter(valid_21627652, JString, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627652
  var valid_21627653 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Algorithm", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Signature")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Signature", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-Credential")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-Credential", valid_21627656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627657: Call_FlushStageCache_21627645; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Flushes a stage's cache.
  ## 
  let valid = call_21627657.validator(path, query, header, formData, body, _)
  let scheme = call_21627657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627657.makeUrl(scheme.get, call_21627657.host, call_21627657.base,
                               call_21627657.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627657, uri, valid, _)

proc call*(call_21627658: Call_FlushStageCache_21627645; stageName: string;
          restapiId: string): Recallable =
  ## flushStageCache
  ## Flushes a stage's cache.
  ##   stageName: string (required)
  ##            : [Required] The name of the stage to flush its cache.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627659 = newJObject()
  add(path_21627659, "stage_name", newJString(stageName))
  add(path_21627659, "restapi_id", newJString(restapiId))
  result = call_21627658.call(path_21627659, nil, nil, nil, nil)

var flushStageCache* = Call_FlushStageCache_21627645(name: "flushStageCache",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/stages/{stage_name}/cache/data",
    validator: validate_FlushStageCache_21627646, base: "/",
    makeUrl: url_FlushStageCache_21627647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateClientCertificate_21627675 = ref object of OpenApiRestCall_21625418
proc url_GenerateClientCertificate_21627677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateClientCertificate_21627676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627678 = header.getOrDefault("X-Amz-Date")
  valid_21627678 = validateParameter(valid_21627678, JString, required = false,
                                   default = nil)
  if valid_21627678 != nil:
    section.add "X-Amz-Date", valid_21627678
  var valid_21627679 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627679 = validateParameter(valid_21627679, JString, required = false,
                                   default = nil)
  if valid_21627679 != nil:
    section.add "X-Amz-Security-Token", valid_21627679
  var valid_21627680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627680 = validateParameter(valid_21627680, JString, required = false,
                                   default = nil)
  if valid_21627680 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627680
  var valid_21627681 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627681 = validateParameter(valid_21627681, JString, required = false,
                                   default = nil)
  if valid_21627681 != nil:
    section.add "X-Amz-Algorithm", valid_21627681
  var valid_21627682 = header.getOrDefault("X-Amz-Signature")
  valid_21627682 = validateParameter(valid_21627682, JString, required = false,
                                   default = nil)
  if valid_21627682 != nil:
    section.add "X-Amz-Signature", valid_21627682
  var valid_21627683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Credential")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Credential", valid_21627684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627686: Call_GenerateClientCertificate_21627675;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates a <a>ClientCertificate</a> resource.
  ## 
  let valid = call_21627686.validator(path, query, header, formData, body, _)
  let scheme = call_21627686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627686.makeUrl(scheme.get, call_21627686.host, call_21627686.base,
                               call_21627686.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627686, uri, valid, _)

proc call*(call_21627687: Call_GenerateClientCertificate_21627675; body: JsonNode): Recallable =
  ## generateClientCertificate
  ## Generates a <a>ClientCertificate</a> resource.
  ##   body: JObject (required)
  var body_21627688 = newJObject()
  if body != nil:
    body_21627688 = body
  result = call_21627687.call(nil, nil, nil, nil, body_21627688)

var generateClientCertificate* = Call_GenerateClientCertificate_21627675(
    name: "generateClientCertificate", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GenerateClientCertificate_21627676, base: "/",
    makeUrl: url_GenerateClientCertificate_21627677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClientCertificates_21627660 = ref object of OpenApiRestCall_21625418
proc url_GetClientCertificates_21627662(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetClientCertificates_21627661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627663 = query.getOrDefault("position")
  valid_21627663 = validateParameter(valid_21627663, JString, required = false,
                                   default = nil)
  if valid_21627663 != nil:
    section.add "position", valid_21627663
  var valid_21627664 = query.getOrDefault("limit")
  valid_21627664 = validateParameter(valid_21627664, JInt, required = false,
                                   default = nil)
  if valid_21627664 != nil:
    section.add "limit", valid_21627664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627665 = header.getOrDefault("X-Amz-Date")
  valid_21627665 = validateParameter(valid_21627665, JString, required = false,
                                   default = nil)
  if valid_21627665 != nil:
    section.add "X-Amz-Date", valid_21627665
  var valid_21627666 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627666 = validateParameter(valid_21627666, JString, required = false,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "X-Amz-Security-Token", valid_21627666
  var valid_21627667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627667 = validateParameter(valid_21627667, JString, required = false,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627667
  var valid_21627668 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Algorithm", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Signature")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Signature", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Credential")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Credential", valid_21627671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627672: Call_GetClientCertificates_21627660;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ## 
  let valid = call_21627672.validator(path, query, header, formData, body, _)
  let scheme = call_21627672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627672.makeUrl(scheme.get, call_21627672.host, call_21627672.base,
                               call_21627672.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627672, uri, valid, _)

proc call*(call_21627673: Call_GetClientCertificates_21627660;
          position: string = ""; limit: int = 0): Recallable =
  ## getClientCertificates
  ## Gets a collection of <a>ClientCertificate</a> resources.
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21627674 = newJObject()
  add(query_21627674, "position", newJString(position))
  add(query_21627674, "limit", newJInt(limit))
  result = call_21627673.call(nil, query_21627674, nil, nil, nil)

var getClientCertificates* = Call_GetClientCertificates_21627660(
    name: "getClientCertificates", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/clientcertificates",
    validator: validate_GetClientCertificates_21627661, base: "/",
    makeUrl: url_GetClientCertificates_21627662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_21627689 = ref object of OpenApiRestCall_21625418
proc url_GetAccount_21627691(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_21627690(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627692 = header.getOrDefault("X-Amz-Date")
  valid_21627692 = validateParameter(valid_21627692, JString, required = false,
                                   default = nil)
  if valid_21627692 != nil:
    section.add "X-Amz-Date", valid_21627692
  var valid_21627693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627693 = validateParameter(valid_21627693, JString, required = false,
                                   default = nil)
  if valid_21627693 != nil:
    section.add "X-Amz-Security-Token", valid_21627693
  var valid_21627694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627694 = validateParameter(valid_21627694, JString, required = false,
                                   default = nil)
  if valid_21627694 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627694
  var valid_21627695 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627695 = validateParameter(valid_21627695, JString, required = false,
                                   default = nil)
  if valid_21627695 != nil:
    section.add "X-Amz-Algorithm", valid_21627695
  var valid_21627696 = header.getOrDefault("X-Amz-Signature")
  valid_21627696 = validateParameter(valid_21627696, JString, required = false,
                                   default = nil)
  if valid_21627696 != nil:
    section.add "X-Amz-Signature", valid_21627696
  var valid_21627697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627697 = validateParameter(valid_21627697, JString, required = false,
                                   default = nil)
  if valid_21627697 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627697
  var valid_21627698 = header.getOrDefault("X-Amz-Credential")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "X-Amz-Credential", valid_21627698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627699: Call_GetAccount_21627689; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the current <a>Account</a> resource.
  ## 
  let valid = call_21627699.validator(path, query, header, formData, body, _)
  let scheme = call_21627699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627699.makeUrl(scheme.get, call_21627699.host, call_21627699.base,
                               call_21627699.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627699, uri, valid, _)

proc call*(call_21627700: Call_GetAccount_21627689): Recallable =
  ## getAccount
  ## Gets information about the current <a>Account</a> resource.
  result = call_21627700.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_21627689(name: "getAccount",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/account",
                                        validator: validate_GetAccount_21627690,
                                        base: "/", makeUrl: url_GetAccount_21627691,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_21627701 = ref object of OpenApiRestCall_21625418
proc url_UpdateAccount_21627703(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAccount_21627702(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627704 = header.getOrDefault("X-Amz-Date")
  valid_21627704 = validateParameter(valid_21627704, JString, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "X-Amz-Date", valid_21627704
  var valid_21627705 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627705 = validateParameter(valid_21627705, JString, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "X-Amz-Security-Token", valid_21627705
  var valid_21627706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627706 = validateParameter(valid_21627706, JString, required = false,
                                   default = nil)
  if valid_21627706 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627706
  var valid_21627707 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627707 = validateParameter(valid_21627707, JString, required = false,
                                   default = nil)
  if valid_21627707 != nil:
    section.add "X-Amz-Algorithm", valid_21627707
  var valid_21627708 = header.getOrDefault("X-Amz-Signature")
  valid_21627708 = validateParameter(valid_21627708, JString, required = false,
                                   default = nil)
  if valid_21627708 != nil:
    section.add "X-Amz-Signature", valid_21627708
  var valid_21627709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627709 = validateParameter(valid_21627709, JString, required = false,
                                   default = nil)
  if valid_21627709 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627709
  var valid_21627710 = header.getOrDefault("X-Amz-Credential")
  valid_21627710 = validateParameter(valid_21627710, JString, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "X-Amz-Credential", valid_21627710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627712: Call_UpdateAccount_21627701; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes information about the current <a>Account</a> resource.
  ## 
  let valid = call_21627712.validator(path, query, header, formData, body, _)
  let scheme = call_21627712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627712.makeUrl(scheme.get, call_21627712.host, call_21627712.base,
                               call_21627712.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627712, uri, valid, _)

proc call*(call_21627713: Call_UpdateAccount_21627701; body: JsonNode): Recallable =
  ## updateAccount
  ## Changes information about the current <a>Account</a> resource.
  ##   body: JObject (required)
  var body_21627714 = newJObject()
  if body != nil:
    body_21627714 = body
  result = call_21627713.call(nil, nil, nil, nil, body_21627714)

var updateAccount* = Call_UpdateAccount_21627701(name: "updateAccount",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com", route: "/account",
    validator: validate_UpdateAccount_21627702, base: "/",
    makeUrl: url_UpdateAccount_21627703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_21627715 = ref object of OpenApiRestCall_21625418
proc url_GetExport_21627717(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetExport_21627716(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627718 = path.getOrDefault("export_type")
  valid_21627718 = validateParameter(valid_21627718, JString, required = true,
                                   default = nil)
  if valid_21627718 != nil:
    section.add "export_type", valid_21627718
  var valid_21627719 = path.getOrDefault("stage_name")
  valid_21627719 = validateParameter(valid_21627719, JString, required = true,
                                   default = nil)
  if valid_21627719 != nil:
    section.add "stage_name", valid_21627719
  var valid_21627720 = path.getOrDefault("restapi_id")
  valid_21627720 = validateParameter(valid_21627720, JString, required = true,
                                   default = nil)
  if valid_21627720 != nil:
    section.add "restapi_id", valid_21627720
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_21627721 = query.getOrDefault("parameters.0.value")
  valid_21627721 = validateParameter(valid_21627721, JString, required = false,
                                   default = nil)
  if valid_21627721 != nil:
    section.add "parameters.0.value", valid_21627721
  var valid_21627722 = query.getOrDefault("parameters.2.value")
  valid_21627722 = validateParameter(valid_21627722, JString, required = false,
                                   default = nil)
  if valid_21627722 != nil:
    section.add "parameters.2.value", valid_21627722
  var valid_21627723 = query.getOrDefault("parameters.1.key")
  valid_21627723 = validateParameter(valid_21627723, JString, required = false,
                                   default = nil)
  if valid_21627723 != nil:
    section.add "parameters.1.key", valid_21627723
  var valid_21627724 = query.getOrDefault("parameters.0.key")
  valid_21627724 = validateParameter(valid_21627724, JString, required = false,
                                   default = nil)
  if valid_21627724 != nil:
    section.add "parameters.0.key", valid_21627724
  var valid_21627725 = query.getOrDefault("parameters.2.key")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "parameters.2.key", valid_21627725
  var valid_21627726 = query.getOrDefault("parameters.1.value")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "parameters.1.value", valid_21627726
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
  var valid_21627727 = header.getOrDefault("X-Amz-Date")
  valid_21627727 = validateParameter(valid_21627727, JString, required = false,
                                   default = nil)
  if valid_21627727 != nil:
    section.add "X-Amz-Date", valid_21627727
  var valid_21627728 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627728 = validateParameter(valid_21627728, JString, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "X-Amz-Security-Token", valid_21627728
  var valid_21627729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627729 = validateParameter(valid_21627729, JString, required = false,
                                   default = nil)
  if valid_21627729 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627729
  var valid_21627730 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627730 = validateParameter(valid_21627730, JString, required = false,
                                   default = nil)
  if valid_21627730 != nil:
    section.add "X-Amz-Algorithm", valid_21627730
  var valid_21627731 = header.getOrDefault("X-Amz-Signature")
  valid_21627731 = validateParameter(valid_21627731, JString, required = false,
                                   default = nil)
  if valid_21627731 != nil:
    section.add "X-Amz-Signature", valid_21627731
  var valid_21627732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627732 = validateParameter(valid_21627732, JString, required = false,
                                   default = nil)
  if valid_21627732 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627732
  var valid_21627733 = header.getOrDefault("Accept")
  valid_21627733 = validateParameter(valid_21627733, JString, required = false,
                                   default = nil)
  if valid_21627733 != nil:
    section.add "Accept", valid_21627733
  var valid_21627734 = header.getOrDefault("X-Amz-Credential")
  valid_21627734 = validateParameter(valid_21627734, JString, required = false,
                                   default = nil)
  if valid_21627734 != nil:
    section.add "X-Amz-Credential", valid_21627734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627735: Call_GetExport_21627715; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Exports a deployed version of a <a>RestApi</a> in a specified format.
  ## 
  let valid = call_21627735.validator(path, query, header, formData, body, _)
  let scheme = call_21627735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627735.makeUrl(scheme.get, call_21627735.host, call_21627735.base,
                               call_21627735.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627735, uri, valid, _)

proc call*(call_21627736: Call_GetExport_21627715; exportType: string;
          stageName: string; restapiId: string; parameters0Value: string = "";
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
  var path_21627737 = newJObject()
  var query_21627738 = newJObject()
  add(query_21627738, "parameters.0.value", newJString(parameters0Value))
  add(query_21627738, "parameters.2.value", newJString(parameters2Value))
  add(query_21627738, "parameters.1.key", newJString(parameters1Key))
  add(query_21627738, "parameters.0.key", newJString(parameters0Key))
  add(path_21627737, "export_type", newJString(exportType))
  add(query_21627738, "parameters.2.key", newJString(parameters2Key))
  add(path_21627737, "stage_name", newJString(stageName))
  add(query_21627738, "parameters.1.value", newJString(parameters1Value))
  add(path_21627737, "restapi_id", newJString(restapiId))
  result = call_21627736.call(path_21627737, query_21627738, nil, nil, nil)

var getExport* = Call_GetExport_21627715(name: "getExport", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/exports/{export_type}",
                                      validator: validate_GetExport_21627716,
                                      base: "/", makeUrl: url_GetExport_21627717,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayResponses_21627739 = ref object of OpenApiRestCall_21625418
proc url_GetGatewayResponses_21627741(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayResponses_21627740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627742 = path.getOrDefault("restapi_id")
  valid_21627742 = validateParameter(valid_21627742, JString, required = true,
                                   default = nil)
  if valid_21627742 != nil:
    section.add "restapi_id", valid_21627742
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  section = newJObject()
  var valid_21627743 = query.getOrDefault("position")
  valid_21627743 = validateParameter(valid_21627743, JString, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "position", valid_21627743
  var valid_21627744 = query.getOrDefault("limit")
  valid_21627744 = validateParameter(valid_21627744, JInt, required = false,
                                   default = nil)
  if valid_21627744 != nil:
    section.add "limit", valid_21627744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627745 = header.getOrDefault("X-Amz-Date")
  valid_21627745 = validateParameter(valid_21627745, JString, required = false,
                                   default = nil)
  if valid_21627745 != nil:
    section.add "X-Amz-Date", valid_21627745
  var valid_21627746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627746 = validateParameter(valid_21627746, JString, required = false,
                                   default = nil)
  if valid_21627746 != nil:
    section.add "X-Amz-Security-Token", valid_21627746
  var valid_21627747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627747 = validateParameter(valid_21627747, JString, required = false,
                                   default = nil)
  if valid_21627747 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627747
  var valid_21627748 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627748 = validateParameter(valid_21627748, JString, required = false,
                                   default = nil)
  if valid_21627748 != nil:
    section.add "X-Amz-Algorithm", valid_21627748
  var valid_21627749 = header.getOrDefault("X-Amz-Signature")
  valid_21627749 = validateParameter(valid_21627749, JString, required = false,
                                   default = nil)
  if valid_21627749 != nil:
    section.add "X-Amz-Signature", valid_21627749
  var valid_21627750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627750 = validateParameter(valid_21627750, JString, required = false,
                                   default = nil)
  if valid_21627750 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627750
  var valid_21627751 = header.getOrDefault("X-Amz-Credential")
  valid_21627751 = validateParameter(valid_21627751, JString, required = false,
                                   default = nil)
  if valid_21627751 != nil:
    section.add "X-Amz-Credential", valid_21627751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627752: Call_GetGatewayResponses_21627739; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ## 
  let valid = call_21627752.validator(path, query, header, formData, body, _)
  let scheme = call_21627752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627752.makeUrl(scheme.get, call_21627752.host, call_21627752.base,
                               call_21627752.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627752, uri, valid, _)

proc call*(call_21627753: Call_GetGatewayResponses_21627739; restapiId: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getGatewayResponses
  ## Gets the <a>GatewayResponses</a> collection on the given <a>RestApi</a>. If an API developer has not added any definitions for gateway responses, the result will be the API Gateway-generated default <a>GatewayResponses</a> collection for the supported response types.
  ##   position: string
  ##           : The current pagination position in the paged result set. The <a>GatewayResponse</a> collection does not support pagination and the position does not apply here.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500. The <a>GatewayResponses</a> collection does not support pagination and the limit does not apply here.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627754 = newJObject()
  var query_21627755 = newJObject()
  add(query_21627755, "position", newJString(position))
  add(query_21627755, "limit", newJInt(limit))
  add(path_21627754, "restapi_id", newJString(restapiId))
  result = call_21627753.call(path_21627754, query_21627755, nil, nil, nil)

var getGatewayResponses* = Call_GetGatewayResponses_21627739(
    name: "getGatewayResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/gatewayresponses",
    validator: validate_GetGatewayResponses_21627740, base: "/",
    makeUrl: url_GetGatewayResponses_21627741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_21627756 = ref object of OpenApiRestCall_21625418
proc url_GetModelTemplate_21627758(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_21627757(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627759 = path.getOrDefault("model_name")
  valid_21627759 = validateParameter(valid_21627759, JString, required = true,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "model_name", valid_21627759
  var valid_21627760 = path.getOrDefault("restapi_id")
  valid_21627760 = validateParameter(valid_21627760, JString, required = true,
                                   default = nil)
  if valid_21627760 != nil:
    section.add "restapi_id", valid_21627760
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627761 = header.getOrDefault("X-Amz-Date")
  valid_21627761 = validateParameter(valid_21627761, JString, required = false,
                                   default = nil)
  if valid_21627761 != nil:
    section.add "X-Amz-Date", valid_21627761
  var valid_21627762 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627762 = validateParameter(valid_21627762, JString, required = false,
                                   default = nil)
  if valid_21627762 != nil:
    section.add "X-Amz-Security-Token", valid_21627762
  var valid_21627763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627763 = validateParameter(valid_21627763, JString, required = false,
                                   default = nil)
  if valid_21627763 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627763
  var valid_21627764 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627764 = validateParameter(valid_21627764, JString, required = false,
                                   default = nil)
  if valid_21627764 != nil:
    section.add "X-Amz-Algorithm", valid_21627764
  var valid_21627765 = header.getOrDefault("X-Amz-Signature")
  valid_21627765 = validateParameter(valid_21627765, JString, required = false,
                                   default = nil)
  if valid_21627765 != nil:
    section.add "X-Amz-Signature", valid_21627765
  var valid_21627766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627766 = validateParameter(valid_21627766, JString, required = false,
                                   default = nil)
  if valid_21627766 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627766
  var valid_21627767 = header.getOrDefault("X-Amz-Credential")
  valid_21627767 = validateParameter(valid_21627767, JString, required = false,
                                   default = nil)
  if valid_21627767 != nil:
    section.add "X-Amz-Credential", valid_21627767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627768: Call_GetModelTemplate_21627756; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ## 
  let valid = call_21627768.validator(path, query, header, formData, body, _)
  let scheme = call_21627768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627768.makeUrl(scheme.get, call_21627768.host, call_21627768.base,
                               call_21627768.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627768, uri, valid, _)

proc call*(call_21627769: Call_GetModelTemplate_21627756; modelName: string;
          restapiId: string): Recallable =
  ## getModelTemplate
  ## Generates a sample mapping template that can be used to transform a payload into the structure of a model.
  ##   modelName: string (required)
  ##            : [Required] The name of the model for which to generate a template.
  ##   restapiId: string (required)
  ##            : [Required] The string identifier of the associated <a>RestApi</a>.
  var path_21627770 = newJObject()
  add(path_21627770, "model_name", newJString(modelName))
  add(path_21627770, "restapi_id", newJString(restapiId))
  result = call_21627769.call(path_21627770, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_21627756(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/models/{model_name}/default_template",
    validator: validate_GetModelTemplate_21627757, base: "/",
    makeUrl: url_GetModelTemplate_21627758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_21627771 = ref object of OpenApiRestCall_21625418
proc url_GetResources_21627773(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_21627772(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627774 = path.getOrDefault("restapi_id")
  valid_21627774 = validateParameter(valid_21627774, JString, required = true,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "restapi_id", valid_21627774
  result.add "path", section
  ## parameters in `query` object:
  ##   embed: JArray
  ##        : A query parameter used to retrieve the specified resources embedded in the returned <a>Resources</a> resource in the response. This <code>embed</code> parameter value is a list of comma-separated strings. Currently, the request supports only retrieval of the embedded <a>Method</a> resources this way. The query parameter value must be a single-valued list and contain the <code>"methods"</code> string. For example, <code>GET /restapis/{restapi_id}/resources?embed=methods</code>.
  ##   position: JString
  ##           : The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21627775 = query.getOrDefault("embed")
  valid_21627775 = validateParameter(valid_21627775, JArray, required = false,
                                   default = nil)
  if valid_21627775 != nil:
    section.add "embed", valid_21627775
  var valid_21627776 = query.getOrDefault("position")
  valid_21627776 = validateParameter(valid_21627776, JString, required = false,
                                   default = nil)
  if valid_21627776 != nil:
    section.add "position", valid_21627776
  var valid_21627777 = query.getOrDefault("limit")
  valid_21627777 = validateParameter(valid_21627777, JInt, required = false,
                                   default = nil)
  if valid_21627777 != nil:
    section.add "limit", valid_21627777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627778 = header.getOrDefault("X-Amz-Date")
  valid_21627778 = validateParameter(valid_21627778, JString, required = false,
                                   default = nil)
  if valid_21627778 != nil:
    section.add "X-Amz-Date", valid_21627778
  var valid_21627779 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627779 = validateParameter(valid_21627779, JString, required = false,
                                   default = nil)
  if valid_21627779 != nil:
    section.add "X-Amz-Security-Token", valid_21627779
  var valid_21627780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627780 = validateParameter(valid_21627780, JString, required = false,
                                   default = nil)
  if valid_21627780 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627780
  var valid_21627781 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627781 = validateParameter(valid_21627781, JString, required = false,
                                   default = nil)
  if valid_21627781 != nil:
    section.add "X-Amz-Algorithm", valid_21627781
  var valid_21627782 = header.getOrDefault("X-Amz-Signature")
  valid_21627782 = validateParameter(valid_21627782, JString, required = false,
                                   default = nil)
  if valid_21627782 != nil:
    section.add "X-Amz-Signature", valid_21627782
  var valid_21627783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627783 = validateParameter(valid_21627783, JString, required = false,
                                   default = nil)
  if valid_21627783 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627783
  var valid_21627784 = header.getOrDefault("X-Amz-Credential")
  valid_21627784 = validateParameter(valid_21627784, JString, required = false,
                                   default = nil)
  if valid_21627784 != nil:
    section.add "X-Amz-Credential", valid_21627784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627785: Call_GetResources_21627771; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists information about a collection of <a>Resource</a> resources.
  ## 
  let valid = call_21627785.validator(path, query, header, formData, body, _)
  let scheme = call_21627785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627785.makeUrl(scheme.get, call_21627785.host, call_21627785.base,
                               call_21627785.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627785, uri, valid, _)

proc call*(call_21627786: Call_GetResources_21627771; restapiId: string;
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
  var path_21627787 = newJObject()
  var query_21627788 = newJObject()
  if embed != nil:
    query_21627788.add "embed", embed
  add(query_21627788, "position", newJString(position))
  add(query_21627788, "limit", newJInt(limit))
  add(path_21627787, "restapi_id", newJString(restapiId))
  result = call_21627786.call(path_21627787, query_21627788, nil, nil, nil)

var getResources* = Call_GetResources_21627771(name: "getResources",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/restapis/{restapi_id}/resources", validator: validate_GetResources_21627772,
    base: "/", makeUrl: url_GetResources_21627773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdk_21627789 = ref object of OpenApiRestCall_21625418
proc url_GetSdk_21627791(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSdk_21627790(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627792 = path.getOrDefault("sdk_type")
  valid_21627792 = validateParameter(valid_21627792, JString, required = true,
                                   default = nil)
  if valid_21627792 != nil:
    section.add "sdk_type", valid_21627792
  var valid_21627793 = path.getOrDefault("stage_name")
  valid_21627793 = validateParameter(valid_21627793, JString, required = true,
                                   default = nil)
  if valid_21627793 != nil:
    section.add "stage_name", valid_21627793
  var valid_21627794 = path.getOrDefault("restapi_id")
  valid_21627794 = validateParameter(valid_21627794, JString, required = true,
                                   default = nil)
  if valid_21627794 != nil:
    section.add "restapi_id", valid_21627794
  result.add "path", section
  ## parameters in `query` object:
  ##   parameters.0.value: JString
  ##   parameters.2.value: JString
  ##   parameters.1.key: JString
  ##   parameters.0.key: JString
  ##   parameters.2.key: JString
  ##   parameters.1.value: JString
  section = newJObject()
  var valid_21627795 = query.getOrDefault("parameters.0.value")
  valid_21627795 = validateParameter(valid_21627795, JString, required = false,
                                   default = nil)
  if valid_21627795 != nil:
    section.add "parameters.0.value", valid_21627795
  var valid_21627796 = query.getOrDefault("parameters.2.value")
  valid_21627796 = validateParameter(valid_21627796, JString, required = false,
                                   default = nil)
  if valid_21627796 != nil:
    section.add "parameters.2.value", valid_21627796
  var valid_21627797 = query.getOrDefault("parameters.1.key")
  valid_21627797 = validateParameter(valid_21627797, JString, required = false,
                                   default = nil)
  if valid_21627797 != nil:
    section.add "parameters.1.key", valid_21627797
  var valid_21627798 = query.getOrDefault("parameters.0.key")
  valid_21627798 = validateParameter(valid_21627798, JString, required = false,
                                   default = nil)
  if valid_21627798 != nil:
    section.add "parameters.0.key", valid_21627798
  var valid_21627799 = query.getOrDefault("parameters.2.key")
  valid_21627799 = validateParameter(valid_21627799, JString, required = false,
                                   default = nil)
  if valid_21627799 != nil:
    section.add "parameters.2.key", valid_21627799
  var valid_21627800 = query.getOrDefault("parameters.1.value")
  valid_21627800 = validateParameter(valid_21627800, JString, required = false,
                                   default = nil)
  if valid_21627800 != nil:
    section.add "parameters.1.value", valid_21627800
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627801 = header.getOrDefault("X-Amz-Date")
  valid_21627801 = validateParameter(valid_21627801, JString, required = false,
                                   default = nil)
  if valid_21627801 != nil:
    section.add "X-Amz-Date", valid_21627801
  var valid_21627802 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627802 = validateParameter(valid_21627802, JString, required = false,
                                   default = nil)
  if valid_21627802 != nil:
    section.add "X-Amz-Security-Token", valid_21627802
  var valid_21627803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Algorithm", valid_21627804
  var valid_21627805 = header.getOrDefault("X-Amz-Signature")
  valid_21627805 = validateParameter(valid_21627805, JString, required = false,
                                   default = nil)
  if valid_21627805 != nil:
    section.add "X-Amz-Signature", valid_21627805
  var valid_21627806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627806 = validateParameter(valid_21627806, JString, required = false,
                                   default = nil)
  if valid_21627806 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627806
  var valid_21627807 = header.getOrDefault("X-Amz-Credential")
  valid_21627807 = validateParameter(valid_21627807, JString, required = false,
                                   default = nil)
  if valid_21627807 != nil:
    section.add "X-Amz-Credential", valid_21627807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627808: Call_GetSdk_21627789; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates a client SDK for a <a>RestApi</a> and <a>Stage</a>.
  ## 
  let valid = call_21627808.validator(path, query, header, formData, body, _)
  let scheme = call_21627808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627808.makeUrl(scheme.get, call_21627808.host, call_21627808.base,
                               call_21627808.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627808, uri, valid, _)

proc call*(call_21627809: Call_GetSdk_21627789; sdkType: string; stageName: string;
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
  var path_21627810 = newJObject()
  var query_21627811 = newJObject()
  add(path_21627810, "sdk_type", newJString(sdkType))
  add(query_21627811, "parameters.0.value", newJString(parameters0Value))
  add(query_21627811, "parameters.2.value", newJString(parameters2Value))
  add(query_21627811, "parameters.1.key", newJString(parameters1Key))
  add(query_21627811, "parameters.0.key", newJString(parameters0Key))
  add(query_21627811, "parameters.2.key", newJString(parameters2Key))
  add(path_21627810, "stage_name", newJString(stageName))
  add(query_21627811, "parameters.1.value", newJString(parameters1Value))
  add(path_21627810, "restapi_id", newJString(restapiId))
  result = call_21627809.call(path_21627810, query_21627811, nil, nil, nil)

var getSdk* = Call_GetSdk_21627789(name: "getSdk", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com", route: "/restapis/{restapi_id}/stages/{stage_name}/sdks/{sdk_type}",
                                validator: validate_GetSdk_21627790, base: "/",
                                makeUrl: url_GetSdk_21627791,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkType_21627812 = ref object of OpenApiRestCall_21625418
proc url_GetSdkType_21627814(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSdkType_21627813(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   sdktype_id: JString (required)
  ##             : [Required] The identifier of the queried <a>SdkType</a> instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `sdktype_id` field"
  var valid_21627815 = path.getOrDefault("sdktype_id")
  valid_21627815 = validateParameter(valid_21627815, JString, required = true,
                                   default = nil)
  if valid_21627815 != nil:
    section.add "sdktype_id", valid_21627815
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627816 = header.getOrDefault("X-Amz-Date")
  valid_21627816 = validateParameter(valid_21627816, JString, required = false,
                                   default = nil)
  if valid_21627816 != nil:
    section.add "X-Amz-Date", valid_21627816
  var valid_21627817 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627817 = validateParameter(valid_21627817, JString, required = false,
                                   default = nil)
  if valid_21627817 != nil:
    section.add "X-Amz-Security-Token", valid_21627817
  var valid_21627818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627818 = validateParameter(valid_21627818, JString, required = false,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627818
  var valid_21627819 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627819 = validateParameter(valid_21627819, JString, required = false,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "X-Amz-Algorithm", valid_21627819
  var valid_21627820 = header.getOrDefault("X-Amz-Signature")
  valid_21627820 = validateParameter(valid_21627820, JString, required = false,
                                   default = nil)
  if valid_21627820 != nil:
    section.add "X-Amz-Signature", valid_21627820
  var valid_21627821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627821 = validateParameter(valid_21627821, JString, required = false,
                                   default = nil)
  if valid_21627821 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627821
  var valid_21627822 = header.getOrDefault("X-Amz-Credential")
  valid_21627822 = validateParameter(valid_21627822, JString, required = false,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "X-Amz-Credential", valid_21627822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627823: Call_GetSdkType_21627812; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627823.validator(path, query, header, formData, body, _)
  let scheme = call_21627823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627823.makeUrl(scheme.get, call_21627823.host, call_21627823.base,
                               call_21627823.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627823, uri, valid, _)

proc call*(call_21627824: Call_GetSdkType_21627812; sdktypeId: string): Recallable =
  ## getSdkType
  ##   sdktypeId: string (required)
  ##            : [Required] The identifier of the queried <a>SdkType</a> instance.
  var path_21627825 = newJObject()
  add(path_21627825, "sdktype_id", newJString(sdktypeId))
  result = call_21627824.call(path_21627825, nil, nil, nil, nil)

var getSdkType* = Call_GetSdkType_21627812(name: "getSdkType",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com",
                                        route: "/sdktypes/{sdktype_id}",
                                        validator: validate_GetSdkType_21627813,
                                        base: "/", makeUrl: url_GetSdkType_21627814,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSdkTypes_21627826 = ref object of OpenApiRestCall_21625418
proc url_GetSdkTypes_21627828(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSdkTypes_21627827(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627829 = query.getOrDefault("position")
  valid_21627829 = validateParameter(valid_21627829, JString, required = false,
                                   default = nil)
  if valid_21627829 != nil:
    section.add "position", valid_21627829
  var valid_21627830 = query.getOrDefault("limit")
  valid_21627830 = validateParameter(valid_21627830, JInt, required = false,
                                   default = nil)
  if valid_21627830 != nil:
    section.add "limit", valid_21627830
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627831 = header.getOrDefault("X-Amz-Date")
  valid_21627831 = validateParameter(valid_21627831, JString, required = false,
                                   default = nil)
  if valid_21627831 != nil:
    section.add "X-Amz-Date", valid_21627831
  var valid_21627832 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627832 = validateParameter(valid_21627832, JString, required = false,
                                   default = nil)
  if valid_21627832 != nil:
    section.add "X-Amz-Security-Token", valid_21627832
  var valid_21627833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627833 = validateParameter(valid_21627833, JString, required = false,
                                   default = nil)
  if valid_21627833 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627833
  var valid_21627834 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627834 = validateParameter(valid_21627834, JString, required = false,
                                   default = nil)
  if valid_21627834 != nil:
    section.add "X-Amz-Algorithm", valid_21627834
  var valid_21627835 = header.getOrDefault("X-Amz-Signature")
  valid_21627835 = validateParameter(valid_21627835, JString, required = false,
                                   default = nil)
  if valid_21627835 != nil:
    section.add "X-Amz-Signature", valid_21627835
  var valid_21627836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627836 = validateParameter(valid_21627836, JString, required = false,
                                   default = nil)
  if valid_21627836 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627836
  var valid_21627837 = header.getOrDefault("X-Amz-Credential")
  valid_21627837 = validateParameter(valid_21627837, JString, required = false,
                                   default = nil)
  if valid_21627837 != nil:
    section.add "X-Amz-Credential", valid_21627837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627838: Call_GetSdkTypes_21627826; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627838.validator(path, query, header, formData, body, _)
  let scheme = call_21627838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627838.makeUrl(scheme.get, call_21627838.host, call_21627838.base,
                               call_21627838.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627838, uri, valid, _)

proc call*(call_21627839: Call_GetSdkTypes_21627826; position: string = "";
          limit: int = 0): Recallable =
  ## getSdkTypes
  ##   position: string
  ##           : The current pagination position in the paged result set.
  ##   limit: int
  ##        : The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var query_21627840 = newJObject()
  add(query_21627840, "position", newJString(position))
  add(query_21627840, "limit", newJInt(limit))
  result = call_21627839.call(nil, query_21627840, nil, nil, nil)

var getSdkTypes* = Call_GetSdkTypes_21627826(name: "getSdkTypes",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/sdktypes",
    validator: validate_GetSdkTypes_21627827, base: "/", makeUrl: url_GetSdkTypes_21627828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627858 = ref object of OpenApiRestCall_21625418
proc url_TagResource_21627860(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21627859(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627861 = path.getOrDefault("resource_arn")
  valid_21627861 = validateParameter(valid_21627861, JString, required = true,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "resource_arn", valid_21627861
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627862 = header.getOrDefault("X-Amz-Date")
  valid_21627862 = validateParameter(valid_21627862, JString, required = false,
                                   default = nil)
  if valid_21627862 != nil:
    section.add "X-Amz-Date", valid_21627862
  var valid_21627863 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "X-Amz-Security-Token", valid_21627863
  var valid_21627864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627864 = validateParameter(valid_21627864, JString, required = false,
                                   default = nil)
  if valid_21627864 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627864
  var valid_21627865 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627865 = validateParameter(valid_21627865, JString, required = false,
                                   default = nil)
  if valid_21627865 != nil:
    section.add "X-Amz-Algorithm", valid_21627865
  var valid_21627866 = header.getOrDefault("X-Amz-Signature")
  valid_21627866 = validateParameter(valid_21627866, JString, required = false,
                                   default = nil)
  if valid_21627866 != nil:
    section.add "X-Amz-Signature", valid_21627866
  var valid_21627867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627867 = validateParameter(valid_21627867, JString, required = false,
                                   default = nil)
  if valid_21627867 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627867
  var valid_21627868 = header.getOrDefault("X-Amz-Credential")
  valid_21627868 = validateParameter(valid_21627868, JString, required = false,
                                   default = nil)
  if valid_21627868 != nil:
    section.add "X-Amz-Credential", valid_21627868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627870: Call_TagResource_21627858; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates a tag on a given resource.
  ## 
  let valid = call_21627870.validator(path, query, header, formData, body, _)
  let scheme = call_21627870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627870.makeUrl(scheme.get, call_21627870.host, call_21627870.base,
                               call_21627870.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627870, uri, valid, _)

proc call*(call_21627871: Call_TagResource_21627858; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates a tag on a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   body: JObject (required)
  var path_21627872 = newJObject()
  var body_21627873 = newJObject()
  add(path_21627872, "resource_arn", newJString(resourceArn))
  if body != nil:
    body_21627873 = body
  result = call_21627871.call(path_21627872, nil, nil, nil, body_21627873)

var tagResource* = Call_TagResource_21627858(name: "tagResource",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}", validator: validate_TagResource_21627859,
    base: "/", makeUrl: url_TagResource_21627860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_21627841 = ref object of OpenApiRestCall_21625418
proc url_GetTags_21627843(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_21627842(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627844 = path.getOrDefault("resource_arn")
  valid_21627844 = validateParameter(valid_21627844, JString, required = true,
                                   default = nil)
  if valid_21627844 != nil:
    section.add "resource_arn", valid_21627844
  result.add "path", section
  ## parameters in `query` object:
  ##   position: JString
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: JInt
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  section = newJObject()
  var valid_21627845 = query.getOrDefault("position")
  valid_21627845 = validateParameter(valid_21627845, JString, required = false,
                                   default = nil)
  if valid_21627845 != nil:
    section.add "position", valid_21627845
  var valid_21627846 = query.getOrDefault("limit")
  valid_21627846 = validateParameter(valid_21627846, JInt, required = false,
                                   default = nil)
  if valid_21627846 != nil:
    section.add "limit", valid_21627846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627847 = header.getOrDefault("X-Amz-Date")
  valid_21627847 = validateParameter(valid_21627847, JString, required = false,
                                   default = nil)
  if valid_21627847 != nil:
    section.add "X-Amz-Date", valid_21627847
  var valid_21627848 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627848 = validateParameter(valid_21627848, JString, required = false,
                                   default = nil)
  if valid_21627848 != nil:
    section.add "X-Amz-Security-Token", valid_21627848
  var valid_21627849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627849 = validateParameter(valid_21627849, JString, required = false,
                                   default = nil)
  if valid_21627849 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627849
  var valid_21627850 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627850 = validateParameter(valid_21627850, JString, required = false,
                                   default = nil)
  if valid_21627850 != nil:
    section.add "X-Amz-Algorithm", valid_21627850
  var valid_21627851 = header.getOrDefault("X-Amz-Signature")
  valid_21627851 = validateParameter(valid_21627851, JString, required = false,
                                   default = nil)
  if valid_21627851 != nil:
    section.add "X-Amz-Signature", valid_21627851
  var valid_21627852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627852 = validateParameter(valid_21627852, JString, required = false,
                                   default = nil)
  if valid_21627852 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627852
  var valid_21627853 = header.getOrDefault("X-Amz-Credential")
  valid_21627853 = validateParameter(valid_21627853, JString, required = false,
                                   default = nil)
  if valid_21627853 != nil:
    section.add "X-Amz-Credential", valid_21627853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627854: Call_GetTags_21627841; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the <a>Tags</a> collection for a given resource.
  ## 
  let valid = call_21627854.validator(path, query, header, formData, body, _)
  let scheme = call_21627854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627854.makeUrl(scheme.get, call_21627854.host, call_21627854.base,
                               call_21627854.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627854, uri, valid, _)

proc call*(call_21627855: Call_GetTags_21627841; resourceArn: string;
          position: string = ""; limit: int = 0): Recallable =
  ## getTags
  ## Gets the <a>Tags</a> collection for a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   position: string
  ##           : (Not currently supported) The current pagination position in the paged result set.
  ##   limit: int
  ##        : (Not currently supported) The maximum number of returned results per page. The default value is 25 and the maximum value is 500.
  var path_21627856 = newJObject()
  var query_21627857 = newJObject()
  add(path_21627856, "resource_arn", newJString(resourceArn))
  add(query_21627857, "position", newJString(position))
  add(query_21627857, "limit", newJInt(limit))
  result = call_21627855.call(path_21627856, query_21627857, nil, nil, nil)

var getTags* = Call_GetTags_21627841(name: "getTags", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/tags/{resource_arn}",
                                  validator: validate_GetTags_21627842, base: "/",
                                  makeUrl: url_GetTags_21627843,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUsage_21627874 = ref object of OpenApiRestCall_21625418
proc url_GetUsage_21627876(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUsage_21627875(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627877 = path.getOrDefault("usageplanId")
  valid_21627877 = validateParameter(valid_21627877, JString, required = true,
                                   default = nil)
  if valid_21627877 != nil:
    section.add "usageplanId", valid_21627877
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
  var valid_21627878 = query.getOrDefault("endDate")
  valid_21627878 = validateParameter(valid_21627878, JString, required = true,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "endDate", valid_21627878
  var valid_21627879 = query.getOrDefault("startDate")
  valid_21627879 = validateParameter(valid_21627879, JString, required = true,
                                   default = nil)
  if valid_21627879 != nil:
    section.add "startDate", valid_21627879
  var valid_21627880 = query.getOrDefault("keyId")
  valid_21627880 = validateParameter(valid_21627880, JString, required = false,
                                   default = nil)
  if valid_21627880 != nil:
    section.add "keyId", valid_21627880
  var valid_21627881 = query.getOrDefault("position")
  valid_21627881 = validateParameter(valid_21627881, JString, required = false,
                                   default = nil)
  if valid_21627881 != nil:
    section.add "position", valid_21627881
  var valid_21627882 = query.getOrDefault("limit")
  valid_21627882 = validateParameter(valid_21627882, JInt, required = false,
                                   default = nil)
  if valid_21627882 != nil:
    section.add "limit", valid_21627882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627883 = header.getOrDefault("X-Amz-Date")
  valid_21627883 = validateParameter(valid_21627883, JString, required = false,
                                   default = nil)
  if valid_21627883 != nil:
    section.add "X-Amz-Date", valid_21627883
  var valid_21627884 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627884 = validateParameter(valid_21627884, JString, required = false,
                                   default = nil)
  if valid_21627884 != nil:
    section.add "X-Amz-Security-Token", valid_21627884
  var valid_21627885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627885 = validateParameter(valid_21627885, JString, required = false,
                                   default = nil)
  if valid_21627885 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627885
  var valid_21627886 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627886 = validateParameter(valid_21627886, JString, required = false,
                                   default = nil)
  if valid_21627886 != nil:
    section.add "X-Amz-Algorithm", valid_21627886
  var valid_21627887 = header.getOrDefault("X-Amz-Signature")
  valid_21627887 = validateParameter(valid_21627887, JString, required = false,
                                   default = nil)
  if valid_21627887 != nil:
    section.add "X-Amz-Signature", valid_21627887
  var valid_21627888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627888 = validateParameter(valid_21627888, JString, required = false,
                                   default = nil)
  if valid_21627888 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627888
  var valid_21627889 = header.getOrDefault("X-Amz-Credential")
  valid_21627889 = validateParameter(valid_21627889, JString, required = false,
                                   default = nil)
  if valid_21627889 != nil:
    section.add "X-Amz-Credential", valid_21627889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627890: Call_GetUsage_21627874; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the usage data of a usage plan in a specified time interval.
  ## 
  let valid = call_21627890.validator(path, query, header, formData, body, _)
  let scheme = call_21627890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627890.makeUrl(scheme.get, call_21627890.host, call_21627890.base,
                               call_21627890.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627890, uri, valid, _)

proc call*(call_21627891: Call_GetUsage_21627874; endDate: string; startDate: string;
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
  var path_21627892 = newJObject()
  var query_21627893 = newJObject()
  add(query_21627893, "endDate", newJString(endDate))
  add(query_21627893, "startDate", newJString(startDate))
  add(path_21627892, "usageplanId", newJString(usageplanId))
  add(query_21627893, "keyId", newJString(keyId))
  add(query_21627893, "position", newJString(position))
  add(query_21627893, "limit", newJInt(limit))
  result = call_21627891.call(path_21627892, query_21627893, nil, nil, nil)

var getUsage* = Call_GetUsage_21627874(name: "getUsage", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/usageplans/{usageplanId}/usage#startDate&endDate",
                                    validator: validate_GetUsage_21627875,
                                    base: "/", makeUrl: url_GetUsage_21627876,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportApiKeys_21627894 = ref object of OpenApiRestCall_21625418
proc url_ImportApiKeys_21627896(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApiKeys_21627895(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627897 = query.getOrDefault("mode")
  valid_21627897 = validateParameter(valid_21627897, JString, required = true,
                                   default = newJString("import"))
  if valid_21627897 != nil:
    section.add "mode", valid_21627897
  var valid_21627898 = query.getOrDefault("failonwarnings")
  valid_21627898 = validateParameter(valid_21627898, JBool, required = false,
                                   default = nil)
  if valid_21627898 != nil:
    section.add "failonwarnings", valid_21627898
  var valid_21627899 = query.getOrDefault("format")
  valid_21627899 = validateParameter(valid_21627899, JString, required = true,
                                   default = newJString("csv"))
  if valid_21627899 != nil:
    section.add "format", valid_21627899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627900 = header.getOrDefault("X-Amz-Date")
  valid_21627900 = validateParameter(valid_21627900, JString, required = false,
                                   default = nil)
  if valid_21627900 != nil:
    section.add "X-Amz-Date", valid_21627900
  var valid_21627901 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627901 = validateParameter(valid_21627901, JString, required = false,
                                   default = nil)
  if valid_21627901 != nil:
    section.add "X-Amz-Security-Token", valid_21627901
  var valid_21627902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627902 = validateParameter(valid_21627902, JString, required = false,
                                   default = nil)
  if valid_21627902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627902
  var valid_21627903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627903 = validateParameter(valid_21627903, JString, required = false,
                                   default = nil)
  if valid_21627903 != nil:
    section.add "X-Amz-Algorithm", valid_21627903
  var valid_21627904 = header.getOrDefault("X-Amz-Signature")
  valid_21627904 = validateParameter(valid_21627904, JString, required = false,
                                   default = nil)
  if valid_21627904 != nil:
    section.add "X-Amz-Signature", valid_21627904
  var valid_21627905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627905 = validateParameter(valid_21627905, JString, required = false,
                                   default = nil)
  if valid_21627905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627905
  var valid_21627906 = header.getOrDefault("X-Amz-Credential")
  valid_21627906 = validateParameter(valid_21627906, JString, required = false,
                                   default = nil)
  if valid_21627906 != nil:
    section.add "X-Amz-Credential", valid_21627906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627908: Call_ImportApiKeys_21627894; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Import API keys from an external source, such as a CSV-formatted file.
  ## 
  let valid = call_21627908.validator(path, query, header, formData, body, _)
  let scheme = call_21627908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627908.makeUrl(scheme.get, call_21627908.host, call_21627908.base,
                               call_21627908.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627908, uri, valid, _)

proc call*(call_21627909: Call_ImportApiKeys_21627894; body: JsonNode;
          mode: string = "import"; failonwarnings: bool = false; format: string = "csv"): Recallable =
  ## importApiKeys
  ## Import API keys from an external source, such as a CSV-formatted file.
  ##   mode: string (required)
  ##   failonwarnings: bool
  ##                 : A query parameter to indicate whether to rollback <a>ApiKey</a> importation (<code>true</code>) or not (<code>false</code>) when error is encountered.
  ##   body: JObject (required)
  ##   format: string (required)
  ##         : A query parameter to specify the input format to imported API keys. Currently, only the <code>csv</code> format is supported.
  var query_21627910 = newJObject()
  var body_21627911 = newJObject()
  add(query_21627910, "mode", newJString(mode))
  add(query_21627910, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_21627911 = body
  add(query_21627910, "format", newJString(format))
  result = call_21627909.call(nil, query_21627910, nil, nil, body_21627911)

var importApiKeys* = Call_ImportApiKeys_21627894(name: "importApiKeys",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/apikeys#mode=import&format", validator: validate_ImportApiKeys_21627895,
    base: "/", makeUrl: url_ImportApiKeys_21627896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportRestApi_21627912 = ref object of OpenApiRestCall_21625418
proc url_ImportRestApi_21627914(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportRestApi_21627913(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627915 = query.getOrDefault("parameters.0.value")
  valid_21627915 = validateParameter(valid_21627915, JString, required = false,
                                   default = nil)
  if valid_21627915 != nil:
    section.add "parameters.0.value", valid_21627915
  var valid_21627916 = query.getOrDefault("parameters.2.value")
  valid_21627916 = validateParameter(valid_21627916, JString, required = false,
                                   default = nil)
  if valid_21627916 != nil:
    section.add "parameters.2.value", valid_21627916
  var valid_21627917 = query.getOrDefault("parameters.1.key")
  valid_21627917 = validateParameter(valid_21627917, JString, required = false,
                                   default = nil)
  if valid_21627917 != nil:
    section.add "parameters.1.key", valid_21627917
  var valid_21627918 = query.getOrDefault("parameters.0.key")
  valid_21627918 = validateParameter(valid_21627918, JString, required = false,
                                   default = nil)
  if valid_21627918 != nil:
    section.add "parameters.0.key", valid_21627918
  var valid_21627919 = query.getOrDefault("mode")
  valid_21627919 = validateParameter(valid_21627919, JString, required = true,
                                   default = newJString("import"))
  if valid_21627919 != nil:
    section.add "mode", valid_21627919
  var valid_21627920 = query.getOrDefault("parameters.2.key")
  valid_21627920 = validateParameter(valid_21627920, JString, required = false,
                                   default = nil)
  if valid_21627920 != nil:
    section.add "parameters.2.key", valid_21627920
  var valid_21627921 = query.getOrDefault("failonwarnings")
  valid_21627921 = validateParameter(valid_21627921, JBool, required = false,
                                   default = nil)
  if valid_21627921 != nil:
    section.add "failonwarnings", valid_21627921
  var valid_21627922 = query.getOrDefault("parameters.1.value")
  valid_21627922 = validateParameter(valid_21627922, JString, required = false,
                                   default = nil)
  if valid_21627922 != nil:
    section.add "parameters.1.value", valid_21627922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627923 = header.getOrDefault("X-Amz-Date")
  valid_21627923 = validateParameter(valid_21627923, JString, required = false,
                                   default = nil)
  if valid_21627923 != nil:
    section.add "X-Amz-Date", valid_21627923
  var valid_21627924 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627924 = validateParameter(valid_21627924, JString, required = false,
                                   default = nil)
  if valid_21627924 != nil:
    section.add "X-Amz-Security-Token", valid_21627924
  var valid_21627925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627925 = validateParameter(valid_21627925, JString, required = false,
                                   default = nil)
  if valid_21627925 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627925
  var valid_21627926 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627926 = validateParameter(valid_21627926, JString, required = false,
                                   default = nil)
  if valid_21627926 != nil:
    section.add "X-Amz-Algorithm", valid_21627926
  var valid_21627927 = header.getOrDefault("X-Amz-Signature")
  valid_21627927 = validateParameter(valid_21627927, JString, required = false,
                                   default = nil)
  if valid_21627927 != nil:
    section.add "X-Amz-Signature", valid_21627927
  var valid_21627928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627928 = validateParameter(valid_21627928, JString, required = false,
                                   default = nil)
  if valid_21627928 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627928
  var valid_21627929 = header.getOrDefault("X-Amz-Credential")
  valid_21627929 = validateParameter(valid_21627929, JString, required = false,
                                   default = nil)
  if valid_21627929 != nil:
    section.add "X-Amz-Credential", valid_21627929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627931: Call_ImportRestApi_21627912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A feature of the API Gateway control service for creating a new API from an external API definition file.
  ## 
  let valid = call_21627931.validator(path, query, header, formData, body, _)
  let scheme = call_21627931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627931.makeUrl(scheme.get, call_21627931.host, call_21627931.base,
                               call_21627931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627931, uri, valid, _)

proc call*(call_21627932: Call_ImportRestApi_21627912; body: JsonNode;
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
  var query_21627933 = newJObject()
  var body_21627934 = newJObject()
  add(query_21627933, "parameters.0.value", newJString(parameters0Value))
  add(query_21627933, "parameters.2.value", newJString(parameters2Value))
  add(query_21627933, "parameters.1.key", newJString(parameters1Key))
  add(query_21627933, "parameters.0.key", newJString(parameters0Key))
  add(query_21627933, "mode", newJString(mode))
  add(query_21627933, "parameters.2.key", newJString(parameters2Key))
  add(query_21627933, "failonwarnings", newJBool(failonwarnings))
  if body != nil:
    body_21627934 = body
  add(query_21627933, "parameters.1.value", newJString(parameters1Value))
  result = call_21627932.call(nil, query_21627933, nil, nil, body_21627934)

var importRestApi* = Call_ImportRestApi_21627912(name: "importRestApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/restapis#mode=import", validator: validate_ImportRestApi_21627913,
    base: "/", makeUrl: url_ImportRestApi_21627914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627935 = ref object of OpenApiRestCall_21625418
proc url_UntagResource_21627937(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21627936(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627938 = path.getOrDefault("resource_arn")
  valid_21627938 = validateParameter(valid_21627938, JString, required = true,
                                   default = nil)
  if valid_21627938 != nil:
    section.add "resource_arn", valid_21627938
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21627939 = query.getOrDefault("tagKeys")
  valid_21627939 = validateParameter(valid_21627939, JArray, required = true,
                                   default = nil)
  if valid_21627939 != nil:
    section.add "tagKeys", valid_21627939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627940 = header.getOrDefault("X-Amz-Date")
  valid_21627940 = validateParameter(valid_21627940, JString, required = false,
                                   default = nil)
  if valid_21627940 != nil:
    section.add "X-Amz-Date", valid_21627940
  var valid_21627941 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627941 = validateParameter(valid_21627941, JString, required = false,
                                   default = nil)
  if valid_21627941 != nil:
    section.add "X-Amz-Security-Token", valid_21627941
  var valid_21627942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627942 = validateParameter(valid_21627942, JString, required = false,
                                   default = nil)
  if valid_21627942 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627942
  var valid_21627943 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627943 = validateParameter(valid_21627943, JString, required = false,
                                   default = nil)
  if valid_21627943 != nil:
    section.add "X-Amz-Algorithm", valid_21627943
  var valid_21627944 = header.getOrDefault("X-Amz-Signature")
  valid_21627944 = validateParameter(valid_21627944, JString, required = false,
                                   default = nil)
  if valid_21627944 != nil:
    section.add "X-Amz-Signature", valid_21627944
  var valid_21627945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627945 = validateParameter(valid_21627945, JString, required = false,
                                   default = nil)
  if valid_21627945 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627945
  var valid_21627946 = header.getOrDefault("X-Amz-Credential")
  valid_21627946 = validateParameter(valid_21627946, JString, required = false,
                                   default = nil)
  if valid_21627946 != nil:
    section.add "X-Amz-Credential", valid_21627946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627947: Call_UntagResource_21627935; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from a given resource.
  ## 
  let valid = call_21627947.validator(path, query, header, formData, body, _)
  let scheme = call_21627947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627947.makeUrl(scheme.get, call_21627947.host, call_21627947.base,
                               call_21627947.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627947, uri, valid, _)

proc call*(call_21627948: Call_UntagResource_21627935; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a given resource.
  ##   resourceArn: string (required)
  ##              : [Required] The ARN of a resource that can be tagged. The resource ARN must be URL-encoded.
  ##   tagKeys: JArray (required)
  ##          : [Required] The Tag keys to delete.
  var path_21627949 = newJObject()
  var query_21627950 = newJObject()
  add(path_21627949, "resource_arn", newJString(resourceArn))
  if tagKeys != nil:
    query_21627950.add "tagKeys", tagKeys
  result = call_21627948.call(path_21627949, query_21627950, nil, nil, nil)

var untagResource* = Call_UntagResource_21627935(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/tags/{resource_arn}#tagKeys", validator: validate_UntagResource_21627936,
    base: "/", makeUrl: url_UntagResource_21627937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUsage_21627951 = ref object of OpenApiRestCall_21625418
proc url_UpdateUsage_21627953(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUsage_21627952(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627954 = path.getOrDefault("keyId")
  valid_21627954 = validateParameter(valid_21627954, JString, required = true,
                                   default = nil)
  if valid_21627954 != nil:
    section.add "keyId", valid_21627954
  var valid_21627955 = path.getOrDefault("usageplanId")
  valid_21627955 = validateParameter(valid_21627955, JString, required = true,
                                   default = nil)
  if valid_21627955 != nil:
    section.add "usageplanId", valid_21627955
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627956 = header.getOrDefault("X-Amz-Date")
  valid_21627956 = validateParameter(valid_21627956, JString, required = false,
                                   default = nil)
  if valid_21627956 != nil:
    section.add "X-Amz-Date", valid_21627956
  var valid_21627957 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627957 = validateParameter(valid_21627957, JString, required = false,
                                   default = nil)
  if valid_21627957 != nil:
    section.add "X-Amz-Security-Token", valid_21627957
  var valid_21627958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627958 = validateParameter(valid_21627958, JString, required = false,
                                   default = nil)
  if valid_21627958 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627958
  var valid_21627959 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627959 = validateParameter(valid_21627959, JString, required = false,
                                   default = nil)
  if valid_21627959 != nil:
    section.add "X-Amz-Algorithm", valid_21627959
  var valid_21627960 = header.getOrDefault("X-Amz-Signature")
  valid_21627960 = validateParameter(valid_21627960, JString, required = false,
                                   default = nil)
  if valid_21627960 != nil:
    section.add "X-Amz-Signature", valid_21627960
  var valid_21627961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627961 = validateParameter(valid_21627961, JString, required = false,
                                   default = nil)
  if valid_21627961 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627961
  var valid_21627962 = header.getOrDefault("X-Amz-Credential")
  valid_21627962 = validateParameter(valid_21627962, JString, required = false,
                                   default = nil)
  if valid_21627962 != nil:
    section.add "X-Amz-Credential", valid_21627962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627964: Call_UpdateUsage_21627951; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ## 
  let valid = call_21627964.validator(path, query, header, formData, body, _)
  let scheme = call_21627964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627964.makeUrl(scheme.get, call_21627964.host, call_21627964.base,
                               call_21627964.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627964, uri, valid, _)

proc call*(call_21627965: Call_UpdateUsage_21627951; keyId: string;
          usageplanId: string; body: JsonNode): Recallable =
  ## updateUsage
  ## Grants a temporary extension to the remaining quota of a usage plan associated with a specified API key.
  ##   keyId: string (required)
  ##        : [Required] The identifier of the API key associated with the usage plan in which a temporary extension is granted to the remaining quota.
  ##   usageplanId: string (required)
  ##              : [Required] The Id of the usage plan associated with the usage data.
  ##   body: JObject (required)
  var path_21627966 = newJObject()
  var body_21627967 = newJObject()
  add(path_21627966, "keyId", newJString(keyId))
  add(path_21627966, "usageplanId", newJString(usageplanId))
  if body != nil:
    body_21627967 = body
  result = call_21627965.call(path_21627966, nil, nil, nil, body_21627967)

var updateUsage* = Call_UpdateUsage_21627951(name: "updateUsage",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/usageplans/{usageplanId}/keys/{keyId}/usage",
    validator: validate_UpdateUsage_21627952, base: "/", makeUrl: url_UpdateUsage_21627953,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}