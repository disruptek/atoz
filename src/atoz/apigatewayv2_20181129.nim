
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonApiGatewayV2
## version: 2018-11-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon API Gateway V2
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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServiceName = "apigatewayv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_ImportApi_21626019 = ref object of OpenApiRestCall_21625435
proc url_ImportApi_21626021(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApi_21626020(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Imports an API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  section = newJObject()
  var valid_21626022 = query.getOrDefault("basepath")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "basepath", valid_21626022
  var valid_21626023 = query.getOrDefault("failOnWarnings")
  valid_21626023 = validateParameter(valid_21626023, JBool, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "failOnWarnings", valid_21626023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626024 = header.getOrDefault("X-Amz-Date")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Date", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Security-Token", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_ImportApi_21626019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports an API.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_ImportApi_21626019; body: JsonNode;
          basepath: string = ""; failOnWarnings: bool = false): Recallable =
  ## importApi
  ## Imports an API.
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   body: JObject (required)
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  var query_21626034 = newJObject()
  var body_21626035 = newJObject()
  add(query_21626034, "basepath", newJString(basepath))
  if body != nil:
    body_21626035 = body
  add(query_21626034, "failOnWarnings", newJBool(failOnWarnings))
  result = call_21626033.call(nil, query_21626034, nil, nil, body_21626035)

var importApi* = Call_ImportApi_21626019(name: "importApi", meth: HttpMethod.HttpPut,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis",
                                      validator: validate_ImportApi_21626020,
                                      base: "/", makeUrl: url_ImportApi_21626021,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_21626036 = ref object of OpenApiRestCall_21625435
proc url_CreateApi_21626038(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApi_21626037(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Api resource.
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
  var valid_21626039 = header.getOrDefault("X-Amz-Date")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Date", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Security-Token", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
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

proc call*(call_21626047: Call_CreateApi_21626036; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_CreateApi_21626036; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_21626049 = newJObject()
  if body != nil:
    body_21626049 = body
  result = call_21626048.call(nil, nil, nil, nil, body_21626049)

var createApi* = Call_CreateApi_21626036(name: "createApi",
                                      meth: HttpMethod.HttpPost,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis",
                                      validator: validate_CreateApi_21626037,
                                      base: "/", makeUrl: url_CreateApi_21626038,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetApis_21625781(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApis_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a collection of Api resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21625882 = query.getOrDefault("maxResults")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "maxResults", valid_21625882
  var valid_21625883 = query.getOrDefault("nextToken")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "nextToken", valid_21625883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_GetApis_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_GetApis_21625779; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var query_21625980 = newJObject()
  add(query_21625980, "maxResults", newJString(maxResults))
  add(query_21625980, "nextToken", newJString(nextToken))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var getApis* = Call_GetApis_21625779(name: "getApis", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis", validator: validate_GetApis_21625780,
                                  base: "/", makeUrl: url_GetApis_21625781,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_21626080 = ref object of OpenApiRestCall_21625435
proc url_CreateApiMapping_21626082(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiMapping_21626081(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626083 = path.getOrDefault("domainName")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "domainName", valid_21626083
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626084 = header.getOrDefault("X-Amz-Date")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Date", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Security-Token", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
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

proc call*(call_21626092: Call_CreateApiMapping_21626080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_CreateApiMapping_21626080; domainName: string;
          body: JsonNode): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_21626094 = newJObject()
  var body_21626095 = newJObject()
  add(path_21626094, "domainName", newJString(domainName))
  if body != nil:
    body_21626095 = body
  result = call_21626093.call(path_21626094, nil, nil, nil, body_21626095)

var createApiMapping* = Call_CreateApiMapping_21626080(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_21626081, base: "/",
    makeUrl: url_CreateApiMapping_21626082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_21626050 = ref object of OpenApiRestCall_21625435
proc url_GetApiMappings_21626052(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMappings_21626051(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets API mappings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626066 = path.getOrDefault("domainName")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "domainName", valid_21626066
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626067 = query.getOrDefault("maxResults")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "maxResults", valid_21626067
  var valid_21626068 = query.getOrDefault("nextToken")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "nextToken", valid_21626068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626069 = header.getOrDefault("X-Amz-Date")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Date", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Security-Token", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626076: Call_GetApiMappings_21626050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets API mappings.
  ## 
  let valid = call_21626076.validator(path, query, header, formData, body, _)
  let scheme = call_21626076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626076.makeUrl(scheme.get, call_21626076.host, call_21626076.base,
                               call_21626076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626076, uri, valid, _)

proc call*(call_21626077: Call_GetApiMappings_21626050; domainName: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_21626078 = newJObject()
  var query_21626079 = newJObject()
  add(query_21626079, "maxResults", newJString(maxResults))
  add(query_21626079, "nextToken", newJString(nextToken))
  add(path_21626078, "domainName", newJString(domainName))
  result = call_21626077.call(path_21626078, query_21626079, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_21626050(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_21626051, base: "/",
    makeUrl: url_GetApiMappings_21626052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_21626113 = ref object of OpenApiRestCall_21625435
proc url_CreateAuthorizer_21626115(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAuthorizer_21626114(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Authorizer for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626116 = path.getOrDefault("apiId")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "apiId", valid_21626116
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626117 = header.getOrDefault("X-Amz-Date")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Date", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Security-Token", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Algorithm", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Signature")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Signature", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Credential")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Credential", valid_21626123
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

proc call*(call_21626125: Call_CreateAuthorizer_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_CreateAuthorizer_21626113; apiId: string;
          body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626127 = newJObject()
  var body_21626128 = newJObject()
  add(path_21626127, "apiId", newJString(apiId))
  if body != nil:
    body_21626128 = body
  result = call_21626126.call(path_21626127, nil, nil, nil, body_21626128)

var createAuthorizer* = Call_CreateAuthorizer_21626113(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_21626114,
    base: "/", makeUrl: url_CreateAuthorizer_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_21626096 = ref object of OpenApiRestCall_21625435
proc url_GetAuthorizers_21626098(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizers_21626097(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Authorizers for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626099 = path.getOrDefault("apiId")
  valid_21626099 = validateParameter(valid_21626099, JString, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "apiId", valid_21626099
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626100 = query.getOrDefault("maxResults")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "maxResults", valid_21626100
  var valid_21626101 = query.getOrDefault("nextToken")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "nextToken", valid_21626101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626102 = header.getOrDefault("X-Amz-Date")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Date", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Security-Token", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626109: Call_GetAuthorizers_21626096; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_21626109.validator(path, query, header, formData, body, _)
  let scheme = call_21626109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626109.makeUrl(scheme.get, call_21626109.host, call_21626109.base,
                               call_21626109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626109, uri, valid, _)

proc call*(call_21626110: Call_GetAuthorizers_21626096; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626111 = newJObject()
  var query_21626112 = newJObject()
  add(path_21626111, "apiId", newJString(apiId))
  add(query_21626112, "maxResults", newJString(maxResults))
  add(query_21626112, "nextToken", newJString(nextToken))
  result = call_21626110.call(path_21626111, query_21626112, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_21626096(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_21626097,
    base: "/", makeUrl: url_GetAuthorizers_21626098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_21626146 = ref object of OpenApiRestCall_21625435
proc url_CreateDeployment_21626148(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_21626147(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Deployment for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626149 = path.getOrDefault("apiId")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "apiId", valid_21626149
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626150 = header.getOrDefault("X-Amz-Date")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Date", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Security-Token", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Algorithm", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Signature")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Signature", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Credential")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Credential", valid_21626156
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

proc call*(call_21626158: Call_CreateDeployment_21626146; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_CreateDeployment_21626146; apiId: string;
          body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626160 = newJObject()
  var body_21626161 = newJObject()
  add(path_21626160, "apiId", newJString(apiId))
  if body != nil:
    body_21626161 = body
  result = call_21626159.call(path_21626160, nil, nil, nil, body_21626161)

var createDeployment* = Call_CreateDeployment_21626146(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_21626147,
    base: "/", makeUrl: url_CreateDeployment_21626148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_21626129 = ref object of OpenApiRestCall_21625435
proc url_GetDeployments_21626131(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployments_21626130(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Deployments for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626132 = path.getOrDefault("apiId")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "apiId", valid_21626132
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626133 = query.getOrDefault("maxResults")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "maxResults", valid_21626133
  var valid_21626134 = query.getOrDefault("nextToken")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "nextToken", valid_21626134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_GetDeployments_21626129; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_GetDeployments_21626129; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626144 = newJObject()
  var query_21626145 = newJObject()
  add(path_21626144, "apiId", newJString(apiId))
  add(query_21626145, "maxResults", newJString(maxResults))
  add(query_21626145, "nextToken", newJString(nextToken))
  result = call_21626143.call(path_21626144, query_21626145, nil, nil, nil)

var getDeployments* = Call_GetDeployments_21626129(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_21626130,
    base: "/", makeUrl: url_GetDeployments_21626131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_21626177 = ref object of OpenApiRestCall_21625435
proc url_CreateDomainName_21626179(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_21626178(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a domain name.
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
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
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

proc call*(call_21626188: Call_CreateDomainName_21626177; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_CreateDomainName_21626177; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_21626190 = newJObject()
  if body != nil:
    body_21626190 = body
  result = call_21626189.call(nil, nil, nil, nil, body_21626190)

var createDomainName* = Call_CreateDomainName_21626177(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_21626178,
    base: "/", makeUrl: url_CreateDomainName_21626179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_21626162 = ref object of OpenApiRestCall_21625435
proc url_GetDomainNames_21626164(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_21626163(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the domain names for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626165 = query.getOrDefault("maxResults")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "maxResults", valid_21626165
  var valid_21626166 = query.getOrDefault("nextToken")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "nextToken", valid_21626166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Algorithm", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Signature")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Signature", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Credential")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Credential", valid_21626173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626174: Call_GetDomainNames_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_GetDomainNames_21626162; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var query_21626176 = newJObject()
  add(query_21626176, "maxResults", newJString(maxResults))
  add(query_21626176, "nextToken", newJString(nextToken))
  result = call_21626175.call(nil, query_21626176, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_21626162(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_21626163,
    base: "/", makeUrl: url_GetDomainNames_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_21626208 = ref object of OpenApiRestCall_21625435
proc url_CreateIntegration_21626210(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegration_21626209(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626211 = path.getOrDefault("apiId")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "apiId", valid_21626211
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
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

proc call*(call_21626220: Call_CreateIntegration_21626208; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_CreateIntegration_21626208; apiId: string;
          body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626222 = newJObject()
  var body_21626223 = newJObject()
  add(path_21626222, "apiId", newJString(apiId))
  if body != nil:
    body_21626223 = body
  result = call_21626221.call(path_21626222, nil, nil, nil, body_21626223)

var createIntegration* = Call_CreateIntegration_21626208(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_21626209,
    base: "/", makeUrl: url_CreateIntegration_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_21626191 = ref object of OpenApiRestCall_21625435
proc url_GetIntegrations_21626193(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrations_21626192(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Integrations for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626194 = path.getOrDefault("apiId")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "apiId", valid_21626194
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626195 = query.getOrDefault("maxResults")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "maxResults", valid_21626195
  var valid_21626196 = query.getOrDefault("nextToken")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "nextToken", valid_21626196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Signature")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Signature", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Credential")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Credential", valid_21626203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626204: Call_GetIntegrations_21626191; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_21626204.validator(path, query, header, formData, body, _)
  let scheme = call_21626204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626204.makeUrl(scheme.get, call_21626204.host, call_21626204.base,
                               call_21626204.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626204, uri, valid, _)

proc call*(call_21626205: Call_GetIntegrations_21626191; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626206 = newJObject()
  var query_21626207 = newJObject()
  add(path_21626206, "apiId", newJString(apiId))
  add(query_21626207, "maxResults", newJString(maxResults))
  add(query_21626207, "nextToken", newJString(nextToken))
  result = call_21626205.call(path_21626206, query_21626207, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_21626191(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_21626192,
    base: "/", makeUrl: url_GetIntegrations_21626193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_21626242 = ref object of OpenApiRestCall_21625435
proc url_CreateIntegrationResponse_21626244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntegrationResponse_21626243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626245 = path.getOrDefault("apiId")
  valid_21626245 = validateParameter(valid_21626245, JString, required = true,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "apiId", valid_21626245
  var valid_21626246 = path.getOrDefault("integrationId")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "integrationId", valid_21626246
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626247 = header.getOrDefault("X-Amz-Date")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Date", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Security-Token", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Algorithm", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Signature")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Signature", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Credential")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Credential", valid_21626253
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

proc call*(call_21626255: Call_CreateIntegrationResponse_21626242;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_21626255.validator(path, query, header, formData, body, _)
  let scheme = call_21626255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626255.makeUrl(scheme.get, call_21626255.host, call_21626255.base,
                               call_21626255.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626255, uri, valid, _)

proc call*(call_21626256: Call_CreateIntegrationResponse_21626242; apiId: string;
          body: JsonNode; integrationId: string): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626257 = newJObject()
  var body_21626258 = newJObject()
  add(path_21626257, "apiId", newJString(apiId))
  if body != nil:
    body_21626258 = body
  add(path_21626257, "integrationId", newJString(integrationId))
  result = call_21626256.call(path_21626257, nil, nil, nil, body_21626258)

var createIntegrationResponse* = Call_CreateIntegrationResponse_21626242(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_21626243, base: "/",
    makeUrl: url_CreateIntegrationResponse_21626244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_21626224 = ref object of OpenApiRestCall_21625435
proc url_GetIntegrationResponses_21626226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponses_21626225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626227 = path.getOrDefault("apiId")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "apiId", valid_21626227
  var valid_21626228 = path.getOrDefault("integrationId")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "integrationId", valid_21626228
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626229 = query.getOrDefault("maxResults")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "maxResults", valid_21626229
  var valid_21626230 = query.getOrDefault("nextToken")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "nextToken", valid_21626230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626231 = header.getOrDefault("X-Amz-Date")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Date", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Security-Token", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Algorithm", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Signature")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Signature", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Credential")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Credential", valid_21626237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626238: Call_GetIntegrationResponses_21626224;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_21626238.validator(path, query, header, formData, body, _)
  let scheme = call_21626238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626238.makeUrl(scheme.get, call_21626238.host, call_21626238.base,
                               call_21626238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626238, uri, valid, _)

proc call*(call_21626239: Call_GetIntegrationResponses_21626224; apiId: string;
          integrationId: string; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626240 = newJObject()
  var query_21626241 = newJObject()
  add(path_21626240, "apiId", newJString(apiId))
  add(query_21626241, "maxResults", newJString(maxResults))
  add(query_21626241, "nextToken", newJString(nextToken))
  add(path_21626240, "integrationId", newJString(integrationId))
  result = call_21626239.call(path_21626240, query_21626241, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_21626224(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_21626225, base: "/",
    makeUrl: url_GetIntegrationResponses_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_21626276 = ref object of OpenApiRestCall_21625435
proc url_CreateModel_21626278(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateModel_21626277(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Model for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626279 = path.getOrDefault("apiId")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "apiId", valid_21626279
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626280 = header.getOrDefault("X-Amz-Date")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Date", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Security-Token", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Algorithm", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Signature")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Signature", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Credential")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Credential", valid_21626286
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

proc call*(call_21626288: Call_CreateModel_21626276; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_21626288.validator(path, query, header, formData, body, _)
  let scheme = call_21626288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626288.makeUrl(scheme.get, call_21626288.host, call_21626288.base,
                               call_21626288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626288, uri, valid, _)

proc call*(call_21626289: Call_CreateModel_21626276; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626290 = newJObject()
  var body_21626291 = newJObject()
  add(path_21626290, "apiId", newJString(apiId))
  if body != nil:
    body_21626291 = body
  result = call_21626289.call(path_21626290, nil, nil, nil, body_21626291)

var createModel* = Call_CreateModel_21626276(name: "createModel",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models", validator: validate_CreateModel_21626277,
    base: "/", makeUrl: url_CreateModel_21626278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_21626259 = ref object of OpenApiRestCall_21625435
proc url_GetModels_21626261(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModels_21626260(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Models for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626262 = path.getOrDefault("apiId")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "apiId", valid_21626262
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626263 = query.getOrDefault("maxResults")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "maxResults", valid_21626263
  var valid_21626264 = query.getOrDefault("nextToken")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "nextToken", valid_21626264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626265 = header.getOrDefault("X-Amz-Date")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Date", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Security-Token", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Algorithm", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Signature")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Signature", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Credential")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Credential", valid_21626271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626272: Call_GetModels_21626259; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_21626272.validator(path, query, header, formData, body, _)
  let scheme = call_21626272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626272.makeUrl(scheme.get, call_21626272.host, call_21626272.base,
                               call_21626272.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626272, uri, valid, _)

proc call*(call_21626273: Call_GetModels_21626259; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626274 = newJObject()
  var query_21626275 = newJObject()
  add(path_21626274, "apiId", newJString(apiId))
  add(query_21626275, "maxResults", newJString(maxResults))
  add(query_21626275, "nextToken", newJString(nextToken))
  result = call_21626273.call(path_21626274, query_21626275, nil, nil, nil)

var getModels* = Call_GetModels_21626259(name: "getModels", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis/{apiId}/models",
                                      validator: validate_GetModels_21626260,
                                      base: "/", makeUrl: url_GetModels_21626261,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_21626309 = ref object of OpenApiRestCall_21625435
proc url_CreateRoute_21626311(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_21626310(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Route for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626312 = path.getOrDefault("apiId")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "apiId", valid_21626312
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
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

proc call*(call_21626321: Call_CreateRoute_21626309; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_21626321.validator(path, query, header, formData, body, _)
  let scheme = call_21626321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626321.makeUrl(scheme.get, call_21626321.host, call_21626321.base,
                               call_21626321.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626321, uri, valid, _)

proc call*(call_21626322: Call_CreateRoute_21626309; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626323 = newJObject()
  var body_21626324 = newJObject()
  add(path_21626323, "apiId", newJString(apiId))
  if body != nil:
    body_21626324 = body
  result = call_21626322.call(path_21626323, nil, nil, nil, body_21626324)

var createRoute* = Call_CreateRoute_21626309(name: "createRoute",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes", validator: validate_CreateRoute_21626310,
    base: "/", makeUrl: url_CreateRoute_21626311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_21626292 = ref object of OpenApiRestCall_21625435
proc url_GetRoutes_21626294(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoutes_21626293(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Routes for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626295 = path.getOrDefault("apiId")
  valid_21626295 = validateParameter(valid_21626295, JString, required = true,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "apiId", valid_21626295
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626296 = query.getOrDefault("maxResults")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "maxResults", valid_21626296
  var valid_21626297 = query.getOrDefault("nextToken")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "nextToken", valid_21626297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626305: Call_GetRoutes_21626292; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_21626305.validator(path, query, header, formData, body, _)
  let scheme = call_21626305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626305.makeUrl(scheme.get, call_21626305.host, call_21626305.base,
                               call_21626305.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626305, uri, valid, _)

proc call*(call_21626306: Call_GetRoutes_21626292; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626307 = newJObject()
  var query_21626308 = newJObject()
  add(path_21626307, "apiId", newJString(apiId))
  add(query_21626308, "maxResults", newJString(maxResults))
  add(query_21626308, "nextToken", newJString(nextToken))
  result = call_21626306.call(path_21626307, query_21626308, nil, nil, nil)

var getRoutes* = Call_GetRoutes_21626292(name: "getRoutes", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis/{apiId}/routes",
                                      validator: validate_GetRoutes_21626293,
                                      base: "/", makeUrl: url_GetRoutes_21626294,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_21626343 = ref object of OpenApiRestCall_21625435
proc url_CreateRouteResponse_21626345(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRouteResponse_21626344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a RouteResponse for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626346 = path.getOrDefault("apiId")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "apiId", valid_21626346
  var valid_21626347 = path.getOrDefault("routeId")
  valid_21626347 = validateParameter(valid_21626347, JString, required = true,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "routeId", valid_21626347
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626348 = header.getOrDefault("X-Amz-Date")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Date", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Security-Token", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_CreateRouteResponse_21626343; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_CreateRouteResponse_21626343; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626358 = newJObject()
  var body_21626359 = newJObject()
  add(path_21626358, "apiId", newJString(apiId))
  if body != nil:
    body_21626359 = body
  add(path_21626358, "routeId", newJString(routeId))
  result = call_21626357.call(path_21626358, nil, nil, nil, body_21626359)

var createRouteResponse* = Call_CreateRouteResponse_21626343(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_21626344, base: "/",
    makeUrl: url_CreateRouteResponse_21626345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_21626325 = ref object of OpenApiRestCall_21625435
proc url_GetRouteResponses_21626327(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponses_21626326(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the RouteResponses for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626328 = path.getOrDefault("apiId")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "apiId", valid_21626328
  var valid_21626329 = path.getOrDefault("routeId")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "routeId", valid_21626329
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626330 = query.getOrDefault("maxResults")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "maxResults", valid_21626330
  var valid_21626331 = query.getOrDefault("nextToken")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "nextToken", valid_21626331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Algorithm", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Signature")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Signature", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Credential")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Credential", valid_21626338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_GetRouteResponses_21626325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_GetRouteResponses_21626325; apiId: string;
          routeId: string; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626341 = newJObject()
  var query_21626342 = newJObject()
  add(path_21626341, "apiId", newJString(apiId))
  add(query_21626342, "maxResults", newJString(maxResults))
  add(query_21626342, "nextToken", newJString(nextToken))
  add(path_21626341, "routeId", newJString(routeId))
  result = call_21626340.call(path_21626341, query_21626342, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_21626325(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_21626326, base: "/",
    makeUrl: url_GetRouteResponses_21626327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_21626377 = ref object of OpenApiRestCall_21625435
proc url_CreateStage_21626379(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateStage_21626378(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Stage for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626380 = path.getOrDefault("apiId")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "apiId", valid_21626380
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626389: Call_CreateStage_21626377; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_21626389.validator(path, query, header, formData, body, _)
  let scheme = call_21626389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626389.makeUrl(scheme.get, call_21626389.host, call_21626389.base,
                               call_21626389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626389, uri, valid, _)

proc call*(call_21626390: Call_CreateStage_21626377; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626391 = newJObject()
  var body_21626392 = newJObject()
  add(path_21626391, "apiId", newJString(apiId))
  if body != nil:
    body_21626392 = body
  result = call_21626390.call(path_21626391, nil, nil, nil, body_21626392)

var createStage* = Call_CreateStage_21626377(name: "createStage",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages", validator: validate_CreateStage_21626378,
    base: "/", makeUrl: url_CreateStage_21626379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_21626360 = ref object of OpenApiRestCall_21625435
proc url_GetStages_21626362(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStages_21626361(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Stages for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626363 = path.getOrDefault("apiId")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "apiId", valid_21626363
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  section = newJObject()
  var valid_21626364 = query.getOrDefault("maxResults")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "maxResults", valid_21626364
  var valid_21626365 = query.getOrDefault("nextToken")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "nextToken", valid_21626365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626366 = header.getOrDefault("X-Amz-Date")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Date", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Security-Token", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Algorithm", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Signature")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Signature", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Credential")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Credential", valid_21626372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626373: Call_GetStages_21626360; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_GetStages_21626360; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of the collection.
  var path_21626375 = newJObject()
  var query_21626376 = newJObject()
  add(path_21626375, "apiId", newJString(apiId))
  add(query_21626376, "maxResults", newJString(maxResults))
  add(query_21626376, "nextToken", newJString(nextToken))
  result = call_21626374.call(path_21626375, query_21626376, nil, nil, nil)

var getStages* = Call_GetStages_21626360(name: "getStages", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis/{apiId}/stages",
                                      validator: validate_GetStages_21626361,
                                      base: "/", makeUrl: url_GetStages_21626362,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_21626407 = ref object of OpenApiRestCall_21625435
proc url_ReimportApi_21626409(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ReimportApi_21626408(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Puts an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626410 = path.getOrDefault("apiId")
  valid_21626410 = validateParameter(valid_21626410, JString, required = true,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "apiId", valid_21626410
  result.add "path", section
  ## parameters in `query` object:
  ##   basepath: JString
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   failOnWarnings: JBool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  section = newJObject()
  var valid_21626411 = query.getOrDefault("basepath")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "basepath", valid_21626411
  var valid_21626412 = query.getOrDefault("failOnWarnings")
  valid_21626412 = validateParameter(valid_21626412, JBool, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "failOnWarnings", valid_21626412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626413 = header.getOrDefault("X-Amz-Date")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Date", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Security-Token", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Algorithm", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Signature")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Signature", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Credential")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Credential", valid_21626419
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

proc call*(call_21626421: Call_ReimportApi_21626407; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Puts an Api resource.
  ## 
  let valid = call_21626421.validator(path, query, header, formData, body, _)
  let scheme = call_21626421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626421.makeUrl(scheme.get, call_21626421.host, call_21626421.base,
                               call_21626421.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626421, uri, valid, _)

proc call*(call_21626422: Call_ReimportApi_21626407; apiId: string; body: JsonNode;
          basepath: string = ""; failOnWarnings: bool = false): Recallable =
  ## reimportApi
  ## Puts an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   basepath: string
  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   body: JObject (required)
  ##   failOnWarnings: bool
  ##                 : Specifies whether to rollback the API creation (true) or not (false) when a warning is encountered. The default value is false.
  var path_21626423 = newJObject()
  var query_21626424 = newJObject()
  var body_21626425 = newJObject()
  add(path_21626423, "apiId", newJString(apiId))
  add(query_21626424, "basepath", newJString(basepath))
  if body != nil:
    body_21626425 = body
  add(query_21626424, "failOnWarnings", newJBool(failOnWarnings))
  result = call_21626422.call(path_21626423, query_21626424, nil, nil, body_21626425)

var reimportApi* = Call_ReimportApi_21626407(name: "reimportApi",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}", validator: validate_ReimportApi_21626408, base: "/",
    makeUrl: url_ReimportApi_21626409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_21626393 = ref object of OpenApiRestCall_21625435
proc url_GetApi_21626395(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApi_21626394(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626396 = path.getOrDefault("apiId")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "apiId", valid_21626396
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626397 = header.getOrDefault("X-Amz-Date")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Date", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Security-Token", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Algorithm", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Signature")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Signature", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Credential")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Credential", valid_21626403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626404: Call_GetApi_21626393; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_21626404.validator(path, query, header, formData, body, _)
  let scheme = call_21626404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626404.makeUrl(scheme.get, call_21626404.host, call_21626404.base,
                               call_21626404.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626404, uri, valid, _)

proc call*(call_21626405: Call_GetApi_21626393; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_21626406 = newJObject()
  add(path_21626406, "apiId", newJString(apiId))
  result = call_21626405.call(path_21626406, nil, nil, nil, nil)

var getApi* = Call_GetApi_21626393(name: "getApi", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis/{apiId}",
                                validator: validate_GetApi_21626394, base: "/",
                                makeUrl: url_GetApi_21626395,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_21626440 = ref object of OpenApiRestCall_21625435
proc url_UpdateApi_21626442(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApi_21626441(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626443 = path.getOrDefault("apiId")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "apiId", valid_21626443
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626444 = header.getOrDefault("X-Amz-Date")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Date", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Security-Token", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Algorithm", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Signature")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Signature", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Credential")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Credential", valid_21626450
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

proc call*(call_21626452: Call_UpdateApi_21626440; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_21626452.validator(path, query, header, formData, body, _)
  let scheme = call_21626452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626452.makeUrl(scheme.get, call_21626452.host, call_21626452.base,
                               call_21626452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626452, uri, valid, _)

proc call*(call_21626453: Call_UpdateApi_21626440; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626454 = newJObject()
  var body_21626455 = newJObject()
  add(path_21626454, "apiId", newJString(apiId))
  if body != nil:
    body_21626455 = body
  result = call_21626453.call(path_21626454, nil, nil, nil, body_21626455)

var updateApi* = Call_UpdateApi_21626440(name: "updateApi",
                                      meth: HttpMethod.HttpPatch,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis/{apiId}",
                                      validator: validate_UpdateApi_21626441,
                                      base: "/", makeUrl: url_UpdateApi_21626442,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_21626426 = ref object of OpenApiRestCall_21625435
proc url_DeleteApi_21626428(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApi_21626427(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626429 = path.getOrDefault("apiId")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "apiId", valid_21626429
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626430 = header.getOrDefault("X-Amz-Date")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Date", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Security-Token", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Algorithm", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Signature")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Signature", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Credential")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Credential", valid_21626436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626437: Call_DeleteApi_21626426; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_21626437.validator(path, query, header, formData, body, _)
  let scheme = call_21626437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626437.makeUrl(scheme.get, call_21626437.host, call_21626437.base,
                               call_21626437.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626437, uri, valid, _)

proc call*(call_21626438: Call_DeleteApi_21626426; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_21626439 = newJObject()
  add(path_21626439, "apiId", newJString(apiId))
  result = call_21626438.call(path_21626439, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_21626426(name: "deleteApi",
                                      meth: HttpMethod.HttpDelete,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis/{apiId}",
                                      validator: validate_DeleteApi_21626427,
                                      base: "/", makeUrl: url_DeleteApi_21626428,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_21626456 = ref object of OpenApiRestCall_21625435
proc url_GetApiMapping_21626458(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiMapping_21626457(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626459 = path.getOrDefault("domainName")
  valid_21626459 = validateParameter(valid_21626459, JString, required = true,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "domainName", valid_21626459
  var valid_21626460 = path.getOrDefault("apiMappingId")
  valid_21626460 = validateParameter(valid_21626460, JString, required = true,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "apiMappingId", valid_21626460
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626461 = header.getOrDefault("X-Amz-Date")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Date", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Security-Token", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Algorithm", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Signature")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Signature", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Credential")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Credential", valid_21626467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626468: Call_GetApiMapping_21626456; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an API mapping.
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_GetApiMapping_21626456; domainName: string;
          apiMappingId: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_21626470 = newJObject()
  add(path_21626470, "domainName", newJString(domainName))
  add(path_21626470, "apiMappingId", newJString(apiMappingId))
  result = call_21626469.call(path_21626470, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_21626456(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_21626457, base: "/",
    makeUrl: url_GetApiMapping_21626458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_21626486 = ref object of OpenApiRestCall_21625435
proc url_UpdateApiMapping_21626488(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiMapping_21626487(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626489 = path.getOrDefault("domainName")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "domainName", valid_21626489
  var valid_21626490 = path.getOrDefault("apiMappingId")
  valid_21626490 = validateParameter(valid_21626490, JString, required = true,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "apiMappingId", valid_21626490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626491 = header.getOrDefault("X-Amz-Date")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Date", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Security-Token", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Algorithm", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Signature")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Signature", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Credential")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Credential", valid_21626497
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

proc call*(call_21626499: Call_UpdateApiMapping_21626486; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## The API mapping.
  ## 
  let valid = call_21626499.validator(path, query, header, formData, body, _)
  let scheme = call_21626499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626499.makeUrl(scheme.get, call_21626499.host, call_21626499.base,
                               call_21626499.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626499, uri, valid, _)

proc call*(call_21626500: Call_UpdateApiMapping_21626486; domainName: string;
          apiMappingId: string; body: JsonNode): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  var path_21626501 = newJObject()
  var body_21626502 = newJObject()
  add(path_21626501, "domainName", newJString(domainName))
  add(path_21626501, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_21626502 = body
  result = call_21626500.call(path_21626501, nil, nil, nil, body_21626502)

var updateApiMapping* = Call_UpdateApiMapping_21626486(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_21626487, base: "/",
    makeUrl: url_UpdateApiMapping_21626488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_21626471 = ref object of OpenApiRestCall_21625435
proc url_DeleteApiMapping_21626473(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiMapping_21626472(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626474 = path.getOrDefault("domainName")
  valid_21626474 = validateParameter(valid_21626474, JString, required = true,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "domainName", valid_21626474
  var valid_21626475 = path.getOrDefault("apiMappingId")
  valid_21626475 = validateParameter(valid_21626475, JString, required = true,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "apiMappingId", valid_21626475
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626476 = header.getOrDefault("X-Amz-Date")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Date", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Security-Token", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Algorithm", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Signature")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Signature", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Credential")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Credential", valid_21626482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626483: Call_DeleteApiMapping_21626471; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_21626483.validator(path, query, header, formData, body, _)
  let scheme = call_21626483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626483.makeUrl(scheme.get, call_21626483.host, call_21626483.base,
                               call_21626483.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626483, uri, valid, _)

proc call*(call_21626484: Call_DeleteApiMapping_21626471; domainName: string;
          apiMappingId: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_21626485 = newJObject()
  add(path_21626485, "domainName", newJString(domainName))
  add(path_21626485, "apiMappingId", newJString(apiMappingId))
  result = call_21626484.call(path_21626485, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_21626471(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_21626472, base: "/",
    makeUrl: url_DeleteApiMapping_21626473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_21626503 = ref object of OpenApiRestCall_21625435
proc url_GetAuthorizer_21626505(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAuthorizer_21626504(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626506 = path.getOrDefault("apiId")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "apiId", valid_21626506
  var valid_21626507 = path.getOrDefault("authorizerId")
  valid_21626507 = validateParameter(valid_21626507, JString, required = true,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "authorizerId", valid_21626507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626508 = header.getOrDefault("X-Amz-Date")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Date", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Security-Token", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Algorithm", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Signature")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Signature", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Credential")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Credential", valid_21626514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626515: Call_GetAuthorizer_21626503; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_21626515.validator(path, query, header, formData, body, _)
  let scheme = call_21626515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626515.makeUrl(scheme.get, call_21626515.host, call_21626515.base,
                               call_21626515.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626515, uri, valid, _)

proc call*(call_21626516: Call_GetAuthorizer_21626503; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_21626517 = newJObject()
  add(path_21626517, "apiId", newJString(apiId))
  add(path_21626517, "authorizerId", newJString(authorizerId))
  result = call_21626516.call(path_21626517, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_21626503(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_21626504, base: "/",
    makeUrl: url_GetAuthorizer_21626505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_21626533 = ref object of OpenApiRestCall_21625435
proc url_UpdateAuthorizer_21626535(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAuthorizer_21626534(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626536 = path.getOrDefault("apiId")
  valid_21626536 = validateParameter(valid_21626536, JString, required = true,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "apiId", valid_21626536
  var valid_21626537 = path.getOrDefault("authorizerId")
  valid_21626537 = validateParameter(valid_21626537, JString, required = true,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "authorizerId", valid_21626537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626538 = header.getOrDefault("X-Amz-Date")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Date", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Security-Token", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Algorithm", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Signature")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Signature", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Credential")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Credential", valid_21626544
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

proc call*(call_21626546: Call_UpdateAuthorizer_21626533; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_21626546.validator(path, query, header, formData, body, _)
  let scheme = call_21626546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626546.makeUrl(scheme.get, call_21626546.host, call_21626546.base,
                               call_21626546.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626546, uri, valid, _)

proc call*(call_21626547: Call_UpdateAuthorizer_21626533; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_21626548 = newJObject()
  var body_21626549 = newJObject()
  add(path_21626548, "apiId", newJString(apiId))
  add(path_21626548, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_21626549 = body
  result = call_21626547.call(path_21626548, nil, nil, nil, body_21626549)

var updateAuthorizer* = Call_UpdateAuthorizer_21626533(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_21626534, base: "/",
    makeUrl: url_UpdateAuthorizer_21626535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_21626518 = ref object of OpenApiRestCall_21625435
proc url_DeleteAuthorizer_21626520(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAuthorizer_21626519(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626521 = path.getOrDefault("apiId")
  valid_21626521 = validateParameter(valid_21626521, JString, required = true,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "apiId", valid_21626521
  var valid_21626522 = path.getOrDefault("authorizerId")
  valid_21626522 = validateParameter(valid_21626522, JString, required = true,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "authorizerId", valid_21626522
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626523 = header.getOrDefault("X-Amz-Date")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Date", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Security-Token", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Algorithm", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Signature")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Signature", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Credential")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Credential", valid_21626529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626530: Call_DeleteAuthorizer_21626518; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_21626530.validator(path, query, header, formData, body, _)
  let scheme = call_21626530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626530.makeUrl(scheme.get, call_21626530.host, call_21626530.base,
                               call_21626530.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626530, uri, valid, _)

proc call*(call_21626531: Call_DeleteAuthorizer_21626518; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_21626532 = newJObject()
  add(path_21626532, "apiId", newJString(apiId))
  add(path_21626532, "authorizerId", newJString(authorizerId))
  result = call_21626531.call(path_21626532, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_21626518(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_21626519, base: "/",
    makeUrl: url_DeleteAuthorizer_21626520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_21626550 = ref object of OpenApiRestCall_21625435
proc url_DeleteCorsConfiguration_21626552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCorsConfiguration_21626551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a CORS configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626553 = path.getOrDefault("apiId")
  valid_21626553 = validateParameter(valid_21626553, JString, required = true,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "apiId", valid_21626553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626554 = header.getOrDefault("X-Amz-Date")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Date", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Security-Token", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Algorithm", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Signature")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Signature", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Credential")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Credential", valid_21626560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626561: Call_DeleteCorsConfiguration_21626550;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a CORS configuration.
  ## 
  let valid = call_21626561.validator(path, query, header, formData, body, _)
  let scheme = call_21626561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626561.makeUrl(scheme.get, call_21626561.host, call_21626561.base,
                               call_21626561.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626561, uri, valid, _)

proc call*(call_21626562: Call_DeleteCorsConfiguration_21626550; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_21626563 = newJObject()
  add(path_21626563, "apiId", newJString(apiId))
  result = call_21626562.call(path_21626563, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_21626550(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_21626551, base: "/",
    makeUrl: url_DeleteCorsConfiguration_21626552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_21626564 = ref object of OpenApiRestCall_21625435
proc url_GetDeployment_21626566(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_21626565(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626567 = path.getOrDefault("apiId")
  valid_21626567 = validateParameter(valid_21626567, JString, required = true,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "apiId", valid_21626567
  var valid_21626568 = path.getOrDefault("deploymentId")
  valid_21626568 = validateParameter(valid_21626568, JString, required = true,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "deploymentId", valid_21626568
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626569 = header.getOrDefault("X-Amz-Date")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Date", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Security-Token", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Algorithm", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Signature")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Signature", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Credential")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Credential", valid_21626575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626576: Call_GetDeployment_21626564; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_21626576.validator(path, query, header, formData, body, _)
  let scheme = call_21626576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626576.makeUrl(scheme.get, call_21626576.host, call_21626576.base,
                               call_21626576.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626576, uri, valid, _)

proc call*(call_21626577: Call_GetDeployment_21626564; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_21626578 = newJObject()
  add(path_21626578, "apiId", newJString(apiId))
  add(path_21626578, "deploymentId", newJString(deploymentId))
  result = call_21626577.call(path_21626578, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_21626564(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_21626565, base: "/",
    makeUrl: url_GetDeployment_21626566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_21626594 = ref object of OpenApiRestCall_21625435
proc url_UpdateDeployment_21626596(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeployment_21626595(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626597 = path.getOrDefault("apiId")
  valid_21626597 = validateParameter(valid_21626597, JString, required = true,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "apiId", valid_21626597
  var valid_21626598 = path.getOrDefault("deploymentId")
  valid_21626598 = validateParameter(valid_21626598, JString, required = true,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "deploymentId", valid_21626598
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_21626607: Call_UpdateDeployment_21626594; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_21626607.validator(path, query, header, formData, body, _)
  let scheme = call_21626607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626607.makeUrl(scheme.get, call_21626607.host, call_21626607.base,
                               call_21626607.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626607, uri, valid, _)

proc call*(call_21626608: Call_UpdateDeployment_21626594; apiId: string;
          deploymentId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  ##   body: JObject (required)
  var path_21626609 = newJObject()
  var body_21626610 = newJObject()
  add(path_21626609, "apiId", newJString(apiId))
  add(path_21626609, "deploymentId", newJString(deploymentId))
  if body != nil:
    body_21626610 = body
  result = call_21626608.call(path_21626609, nil, nil, nil, body_21626610)

var updateDeployment* = Call_UpdateDeployment_21626594(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_21626595, base: "/",
    makeUrl: url_UpdateDeployment_21626596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_21626579 = ref object of OpenApiRestCall_21625435
proc url_DeleteDeployment_21626581(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeployment_21626580(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626582 = path.getOrDefault("apiId")
  valid_21626582 = validateParameter(valid_21626582, JString, required = true,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "apiId", valid_21626582
  var valid_21626583 = path.getOrDefault("deploymentId")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "deploymentId", valid_21626583
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_21626591: Call_DeleteDeployment_21626579; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_DeleteDeployment_21626579; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_21626593 = newJObject()
  add(path_21626593, "apiId", newJString(apiId))
  add(path_21626593, "deploymentId", newJString(deploymentId))
  result = call_21626592.call(path_21626593, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_21626579(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_21626580, base: "/",
    makeUrl: url_DeleteDeployment_21626581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_21626611 = ref object of OpenApiRestCall_21625435
proc url_GetDomainName_21626613(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainName_21626612(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626614 = path.getOrDefault("domainName")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "domainName", valid_21626614
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626615 = header.getOrDefault("X-Amz-Date")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Date", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Security-Token", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Algorithm", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Signature")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Signature", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Credential")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Credential", valid_21626621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626622: Call_GetDomainName_21626611; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_21626622.validator(path, query, header, formData, body, _)
  let scheme = call_21626622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626622.makeUrl(scheme.get, call_21626622.host, call_21626622.base,
                               call_21626622.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626622, uri, valid, _)

proc call*(call_21626623: Call_GetDomainName_21626611; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_21626624 = newJObject()
  add(path_21626624, "domainName", newJString(domainName))
  result = call_21626623.call(path_21626624, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_21626611(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_21626612,
    base: "/", makeUrl: url_GetDomainName_21626613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_21626639 = ref object of OpenApiRestCall_21625435
proc url_UpdateDomainName_21626641(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainName_21626640(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626642 = path.getOrDefault("domainName")
  valid_21626642 = validateParameter(valid_21626642, JString, required = true,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "domainName", valid_21626642
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626643 = header.getOrDefault("X-Amz-Date")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Date", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Security-Token", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
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

proc call*(call_21626651: Call_UpdateDomainName_21626639; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_UpdateDomainName_21626639; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_21626653 = newJObject()
  var body_21626654 = newJObject()
  add(path_21626653, "domainName", newJString(domainName))
  if body != nil:
    body_21626654 = body
  result = call_21626652.call(path_21626653, nil, nil, nil, body_21626654)

var updateDomainName* = Call_UpdateDomainName_21626639(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_21626640,
    base: "/", makeUrl: url_UpdateDomainName_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_21626625 = ref object of OpenApiRestCall_21625435
proc url_DeleteDomainName_21626627(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainName_21626626(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_21626628 = path.getOrDefault("domainName")
  valid_21626628 = validateParameter(valid_21626628, JString, required = true,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "domainName", valid_21626628
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626629 = header.getOrDefault("X-Amz-Date")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Date", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Security-Token", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Algorithm", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Signature")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Signature", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Credential")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Credential", valid_21626635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626636: Call_DeleteDomainName_21626625; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_21626636.validator(path, query, header, formData, body, _)
  let scheme = call_21626636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626636.makeUrl(scheme.get, call_21626636.host, call_21626636.base,
                               call_21626636.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626636, uri, valid, _)

proc call*(call_21626637: Call_DeleteDomainName_21626625; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_21626638 = newJObject()
  add(path_21626638, "domainName", newJString(domainName))
  result = call_21626637.call(path_21626638, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_21626625(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_21626626,
    base: "/", makeUrl: url_DeleteDomainName_21626627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_21626655 = ref object of OpenApiRestCall_21625435
proc url_GetIntegration_21626657(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegration_21626656(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626658 = path.getOrDefault("apiId")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "apiId", valid_21626658
  var valid_21626659 = path.getOrDefault("integrationId")
  valid_21626659 = validateParameter(valid_21626659, JString, required = true,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "integrationId", valid_21626659
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626660 = header.getOrDefault("X-Amz-Date")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Date", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Security-Token", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Algorithm", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Signature")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Signature", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Credential")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Credential", valid_21626666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626667: Call_GetIntegration_21626655; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_21626667.validator(path, query, header, formData, body, _)
  let scheme = call_21626667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626667.makeUrl(scheme.get, call_21626667.host, call_21626667.base,
                               call_21626667.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626667, uri, valid, _)

proc call*(call_21626668: Call_GetIntegration_21626655; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626669 = newJObject()
  add(path_21626669, "apiId", newJString(apiId))
  add(path_21626669, "integrationId", newJString(integrationId))
  result = call_21626668.call(path_21626669, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_21626655(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_21626656, base: "/",
    makeUrl: url_GetIntegration_21626657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_21626685 = ref object of OpenApiRestCall_21625435
proc url_UpdateIntegration_21626687(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegration_21626686(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626688 = path.getOrDefault("apiId")
  valid_21626688 = validateParameter(valid_21626688, JString, required = true,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "apiId", valid_21626688
  var valid_21626689 = path.getOrDefault("integrationId")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "integrationId", valid_21626689
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_21626698: Call_UpdateIntegration_21626685; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_21626698.validator(path, query, header, formData, body, _)
  let scheme = call_21626698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626698.makeUrl(scheme.get, call_21626698.host, call_21626698.base,
                               call_21626698.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626698, uri, valid, _)

proc call*(call_21626699: Call_UpdateIntegration_21626685; apiId: string;
          body: JsonNode; integrationId: string): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626700 = newJObject()
  var body_21626701 = newJObject()
  add(path_21626700, "apiId", newJString(apiId))
  if body != nil:
    body_21626701 = body
  add(path_21626700, "integrationId", newJString(integrationId))
  result = call_21626699.call(path_21626700, nil, nil, nil, body_21626701)

var updateIntegration* = Call_UpdateIntegration_21626685(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_21626686, base: "/",
    makeUrl: url_UpdateIntegration_21626687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_21626670 = ref object of OpenApiRestCall_21625435
proc url_DeleteIntegration_21626672(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegration_21626671(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626673 = path.getOrDefault("apiId")
  valid_21626673 = validateParameter(valid_21626673, JString, required = true,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "apiId", valid_21626673
  var valid_21626674 = path.getOrDefault("integrationId")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "integrationId", valid_21626674
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626675 = header.getOrDefault("X-Amz-Date")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Date", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Security-Token", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Algorithm", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Signature")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Signature", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Credential")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Credential", valid_21626681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626682: Call_DeleteIntegration_21626670; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_21626682.validator(path, query, header, formData, body, _)
  let scheme = call_21626682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626682.makeUrl(scheme.get, call_21626682.host, call_21626682.base,
                               call_21626682.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626682, uri, valid, _)

proc call*(call_21626683: Call_DeleteIntegration_21626670; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626684 = newJObject()
  add(path_21626684, "apiId", newJString(apiId))
  add(path_21626684, "integrationId", newJString(integrationId))
  result = call_21626683.call(path_21626684, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_21626670(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_21626671, base: "/",
    makeUrl: url_DeleteIntegration_21626672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_21626702 = ref object of OpenApiRestCall_21625435
proc url_GetIntegrationResponse_21626704(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntegrationResponse_21626703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_21626705 = path.getOrDefault("integrationResponseId")
  valid_21626705 = validateParameter(valid_21626705, JString, required = true,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "integrationResponseId", valid_21626705
  var valid_21626706 = path.getOrDefault("apiId")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "apiId", valid_21626706
  var valid_21626707 = path.getOrDefault("integrationId")
  valid_21626707 = validateParameter(valid_21626707, JString, required = true,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "integrationId", valid_21626707
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_21626715: Call_GetIntegrationResponse_21626702;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_21626715.validator(path, query, header, formData, body, _)
  let scheme = call_21626715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626715.makeUrl(scheme.get, call_21626715.host, call_21626715.base,
                               call_21626715.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626715, uri, valid, _)

proc call*(call_21626716: Call_GetIntegrationResponse_21626702;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626717 = newJObject()
  add(path_21626717, "integrationResponseId", newJString(integrationResponseId))
  add(path_21626717, "apiId", newJString(apiId))
  add(path_21626717, "integrationId", newJString(integrationId))
  result = call_21626716.call(path_21626717, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_21626702(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_21626703, base: "/",
    makeUrl: url_GetIntegrationResponse_21626704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_21626734 = ref object of OpenApiRestCall_21625435
proc url_UpdateIntegrationResponse_21626736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_21626735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_21626737 = path.getOrDefault("integrationResponseId")
  valid_21626737 = validateParameter(valid_21626737, JString, required = true,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "integrationResponseId", valid_21626737
  var valid_21626738 = path.getOrDefault("apiId")
  valid_21626738 = validateParameter(valid_21626738, JString, required = true,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "apiId", valid_21626738
  var valid_21626739 = path.getOrDefault("integrationId")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "integrationId", valid_21626739
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626740 = header.getOrDefault("X-Amz-Date")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Date", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Security-Token", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Algorithm", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Signature")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Signature", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Credential")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Credential", valid_21626746
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

proc call*(call_21626748: Call_UpdateIntegrationResponse_21626734;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_21626748.validator(path, query, header, formData, body, _)
  let scheme = call_21626748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626748.makeUrl(scheme.get, call_21626748.host, call_21626748.base,
                               call_21626748.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626748, uri, valid, _)

proc call*(call_21626749: Call_UpdateIntegrationResponse_21626734;
          integrationResponseId: string; apiId: string; body: JsonNode;
          integrationId: string): Recallable =
  ## updateIntegrationResponse
  ## Updates an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626750 = newJObject()
  var body_21626751 = newJObject()
  add(path_21626750, "integrationResponseId", newJString(integrationResponseId))
  add(path_21626750, "apiId", newJString(apiId))
  if body != nil:
    body_21626751 = body
  add(path_21626750, "integrationId", newJString(integrationId))
  result = call_21626749.call(path_21626750, nil, nil, nil, body_21626751)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_21626734(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_21626735, base: "/",
    makeUrl: url_UpdateIntegrationResponse_21626736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_21626718 = ref object of OpenApiRestCall_21625435
proc url_DeleteIntegrationResponse_21626720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_21626719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_21626721 = path.getOrDefault("integrationResponseId")
  valid_21626721 = validateParameter(valid_21626721, JString, required = true,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "integrationResponseId", valid_21626721
  var valid_21626722 = path.getOrDefault("apiId")
  valid_21626722 = validateParameter(valid_21626722, JString, required = true,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "apiId", valid_21626722
  var valid_21626723 = path.getOrDefault("integrationId")
  valid_21626723 = validateParameter(valid_21626723, JString, required = true,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "integrationId", valid_21626723
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_21626731: Call_DeleteIntegrationResponse_21626718;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_DeleteIntegrationResponse_21626718;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_21626733 = newJObject()
  add(path_21626733, "integrationResponseId", newJString(integrationResponseId))
  add(path_21626733, "apiId", newJString(apiId))
  add(path_21626733, "integrationId", newJString(integrationId))
  result = call_21626732.call(path_21626733, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_21626718(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_21626719, base: "/",
    makeUrl: url_DeleteIntegrationResponse_21626720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_21626752 = ref object of OpenApiRestCall_21625435
proc url_GetModel_21626754(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModel_21626753(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626755 = path.getOrDefault("apiId")
  valid_21626755 = validateParameter(valid_21626755, JString, required = true,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "apiId", valid_21626755
  var valid_21626756 = path.getOrDefault("modelId")
  valid_21626756 = validateParameter(valid_21626756, JString, required = true,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "modelId", valid_21626756
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626757 = header.getOrDefault("X-Amz-Date")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Date", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Security-Token", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Algorithm", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Signature")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Signature", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Credential")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Credential", valid_21626763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626764: Call_GetModel_21626752; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_21626764.validator(path, query, header, formData, body, _)
  let scheme = call_21626764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626764.makeUrl(scheme.get, call_21626764.host, call_21626764.base,
                               call_21626764.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626764, uri, valid, _)

proc call*(call_21626765: Call_GetModel_21626752; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_21626766 = newJObject()
  add(path_21626766, "apiId", newJString(apiId))
  add(path_21626766, "modelId", newJString(modelId))
  result = call_21626765.call(path_21626766, nil, nil, nil, nil)

var getModel* = Call_GetModel_21626752(name: "getModel", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models/{modelId}",
                                    validator: validate_GetModel_21626753,
                                    base: "/", makeUrl: url_GetModel_21626754,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_21626782 = ref object of OpenApiRestCall_21625435
proc url_UpdateModel_21626784(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateModel_21626783(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626785 = path.getOrDefault("apiId")
  valid_21626785 = validateParameter(valid_21626785, JString, required = true,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "apiId", valid_21626785
  var valid_21626786 = path.getOrDefault("modelId")
  valid_21626786 = validateParameter(valid_21626786, JString, required = true,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "modelId", valid_21626786
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626787 = header.getOrDefault("X-Amz-Date")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Date", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Security-Token", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Algorithm", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Signature")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Signature", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Credential")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Credential", valid_21626793
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

proc call*(call_21626795: Call_UpdateModel_21626782; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_21626795.validator(path, query, header, formData, body, _)
  let scheme = call_21626795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626795.makeUrl(scheme.get, call_21626795.host, call_21626795.base,
                               call_21626795.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626795, uri, valid, _)

proc call*(call_21626796: Call_UpdateModel_21626782; apiId: string; modelId: string;
          body: JsonNode): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  ##   body: JObject (required)
  var path_21626797 = newJObject()
  var body_21626798 = newJObject()
  add(path_21626797, "apiId", newJString(apiId))
  add(path_21626797, "modelId", newJString(modelId))
  if body != nil:
    body_21626798 = body
  result = call_21626796.call(path_21626797, nil, nil, nil, body_21626798)

var updateModel* = Call_UpdateModel_21626782(name: "updateModel",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}", validator: validate_UpdateModel_21626783,
    base: "/", makeUrl: url_UpdateModel_21626784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_21626767 = ref object of OpenApiRestCall_21625435
proc url_DeleteModel_21626769(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteModel_21626768(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626770 = path.getOrDefault("apiId")
  valid_21626770 = validateParameter(valid_21626770, JString, required = true,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "apiId", valid_21626770
  var valid_21626771 = path.getOrDefault("modelId")
  valid_21626771 = validateParameter(valid_21626771, JString, required = true,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "modelId", valid_21626771
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626772 = header.getOrDefault("X-Amz-Date")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Date", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Security-Token", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Algorithm", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Signature")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Signature", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Credential")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Credential", valid_21626778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626779: Call_DeleteModel_21626767; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_21626779.validator(path, query, header, formData, body, _)
  let scheme = call_21626779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626779.makeUrl(scheme.get, call_21626779.host, call_21626779.base,
                               call_21626779.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626779, uri, valid, _)

proc call*(call_21626780: Call_DeleteModel_21626767; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_21626781 = newJObject()
  add(path_21626781, "apiId", newJString(apiId))
  add(path_21626781, "modelId", newJString(modelId))
  result = call_21626780.call(path_21626781, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_21626767(name: "deleteModel",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}", validator: validate_DeleteModel_21626768,
    base: "/", makeUrl: url_DeleteModel_21626769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_21626799 = ref object of OpenApiRestCall_21625435
proc url_GetRoute_21626801(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoute_21626800(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626802 = path.getOrDefault("apiId")
  valid_21626802 = validateParameter(valid_21626802, JString, required = true,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "apiId", valid_21626802
  var valid_21626803 = path.getOrDefault("routeId")
  valid_21626803 = validateParameter(valid_21626803, JString, required = true,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "routeId", valid_21626803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626804 = header.getOrDefault("X-Amz-Date")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Date", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Security-Token", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Algorithm", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Signature")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Signature", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Credential")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Credential", valid_21626810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626811: Call_GetRoute_21626799; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_21626811.validator(path, query, header, formData, body, _)
  let scheme = call_21626811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626811.makeUrl(scheme.get, call_21626811.host, call_21626811.base,
                               call_21626811.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626811, uri, valid, _)

proc call*(call_21626812: Call_GetRoute_21626799; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626813 = newJObject()
  add(path_21626813, "apiId", newJString(apiId))
  add(path_21626813, "routeId", newJString(routeId))
  result = call_21626812.call(path_21626813, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_21626799(name: "getRoute", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes/{routeId}",
                                    validator: validate_GetRoute_21626800,
                                    base: "/", makeUrl: url_GetRoute_21626801,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_21626829 = ref object of OpenApiRestCall_21625435
proc url_UpdateRoute_21626831(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_21626830(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626832 = path.getOrDefault("apiId")
  valid_21626832 = validateParameter(valid_21626832, JString, required = true,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "apiId", valid_21626832
  var valid_21626833 = path.getOrDefault("routeId")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "routeId", valid_21626833
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626834 = header.getOrDefault("X-Amz-Date")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Date", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Security-Token", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Algorithm", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Signature")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Signature", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Credential")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Credential", valid_21626840
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

proc call*(call_21626842: Call_UpdateRoute_21626829; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_21626842.validator(path, query, header, formData, body, _)
  let scheme = call_21626842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626842.makeUrl(scheme.get, call_21626842.host, call_21626842.base,
                               call_21626842.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626842, uri, valid, _)

proc call*(call_21626843: Call_UpdateRoute_21626829; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626844 = newJObject()
  var body_21626845 = newJObject()
  add(path_21626844, "apiId", newJString(apiId))
  if body != nil:
    body_21626845 = body
  add(path_21626844, "routeId", newJString(routeId))
  result = call_21626843.call(path_21626844, nil, nil, nil, body_21626845)

var updateRoute* = Call_UpdateRoute_21626829(name: "updateRoute",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}", validator: validate_UpdateRoute_21626830,
    base: "/", makeUrl: url_UpdateRoute_21626831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_21626814 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoute_21626816(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_21626815(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626817 = path.getOrDefault("apiId")
  valid_21626817 = validateParameter(valid_21626817, JString, required = true,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "apiId", valid_21626817
  var valid_21626818 = path.getOrDefault("routeId")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "routeId", valid_21626818
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626819 = header.getOrDefault("X-Amz-Date")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Date", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Security-Token", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Algorithm", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Signature")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Signature", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Credential")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Credential", valid_21626825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626826: Call_DeleteRoute_21626814; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_21626826.validator(path, query, header, formData, body, _)
  let scheme = call_21626826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626826.makeUrl(scheme.get, call_21626826.host, call_21626826.base,
                               call_21626826.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626826, uri, valid, _)

proc call*(call_21626827: Call_DeleteRoute_21626814; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626828 = newJObject()
  add(path_21626828, "apiId", newJString(apiId))
  add(path_21626828, "routeId", newJString(routeId))
  result = call_21626827.call(path_21626828, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_21626814(name: "deleteRoute",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}", validator: validate_DeleteRoute_21626815,
    base: "/", makeUrl: url_DeleteRoute_21626816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_21626846 = ref object of OpenApiRestCall_21625435
proc url_GetRouteResponse_21626848(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponse_21626847(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626849 = path.getOrDefault("apiId")
  valid_21626849 = validateParameter(valid_21626849, JString, required = true,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "apiId", valid_21626849
  var valid_21626850 = path.getOrDefault("routeResponseId")
  valid_21626850 = validateParameter(valid_21626850, JString, required = true,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "routeResponseId", valid_21626850
  var valid_21626851 = path.getOrDefault("routeId")
  valid_21626851 = validateParameter(valid_21626851, JString, required = true,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "routeId", valid_21626851
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626852 = header.getOrDefault("X-Amz-Date")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Date", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Security-Token", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Algorithm", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Signature")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Signature", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Credential")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Credential", valid_21626858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626859: Call_GetRouteResponse_21626846; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_21626859.validator(path, query, header, formData, body, _)
  let scheme = call_21626859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626859.makeUrl(scheme.get, call_21626859.host, call_21626859.base,
                               call_21626859.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626859, uri, valid, _)

proc call*(call_21626860: Call_GetRouteResponse_21626846; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626861 = newJObject()
  add(path_21626861, "apiId", newJString(apiId))
  add(path_21626861, "routeResponseId", newJString(routeResponseId))
  add(path_21626861, "routeId", newJString(routeId))
  result = call_21626860.call(path_21626861, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_21626846(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_21626847, base: "/",
    makeUrl: url_GetRouteResponse_21626848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_21626878 = ref object of OpenApiRestCall_21625435
proc url_UpdateRouteResponse_21626880(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRouteResponse_21626879(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626881 = path.getOrDefault("apiId")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "apiId", valid_21626881
  var valid_21626882 = path.getOrDefault("routeResponseId")
  valid_21626882 = validateParameter(valid_21626882, JString, required = true,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "routeResponseId", valid_21626882
  var valid_21626883 = path.getOrDefault("routeId")
  valid_21626883 = validateParameter(valid_21626883, JString, required = true,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "routeId", valid_21626883
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626884 = header.getOrDefault("X-Amz-Date")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Date", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Security-Token", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Algorithm", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Signature")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Signature", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Credential")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Credential", valid_21626890
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

proc call*(call_21626892: Call_UpdateRouteResponse_21626878; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_21626892.validator(path, query, header, formData, body, _)
  let scheme = call_21626892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626892.makeUrl(scheme.get, call_21626892.host, call_21626892.base,
                               call_21626892.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626892, uri, valid, _)

proc call*(call_21626893: Call_UpdateRouteResponse_21626878; apiId: string;
          routeResponseId: string; body: JsonNode; routeId: string): Recallable =
  ## updateRouteResponse
  ## Updates a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626894 = newJObject()
  var body_21626895 = newJObject()
  add(path_21626894, "apiId", newJString(apiId))
  add(path_21626894, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_21626895 = body
  add(path_21626894, "routeId", newJString(routeId))
  result = call_21626893.call(path_21626894, nil, nil, nil, body_21626895)

var updateRouteResponse* = Call_UpdateRouteResponse_21626878(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_21626879, base: "/",
    makeUrl: url_UpdateRouteResponse_21626880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_21626862 = ref object of OpenApiRestCall_21625435
proc url_DeleteRouteResponse_21626864(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteResponse_21626863(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626865 = path.getOrDefault("apiId")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "apiId", valid_21626865
  var valid_21626866 = path.getOrDefault("routeResponseId")
  valid_21626866 = validateParameter(valid_21626866, JString, required = true,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "routeResponseId", valid_21626866
  var valid_21626867 = path.getOrDefault("routeId")
  valid_21626867 = validateParameter(valid_21626867, JString, required = true,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "routeId", valid_21626867
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626868 = header.getOrDefault("X-Amz-Date")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Date", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Security-Token", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Algorithm", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Signature")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Signature", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Credential")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Credential", valid_21626874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626875: Call_DeleteRouteResponse_21626862; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_21626875.validator(path, query, header, formData, body, _)
  let scheme = call_21626875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626875.makeUrl(scheme.get, call_21626875.host, call_21626875.base,
                               call_21626875.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626875, uri, valid, _)

proc call*(call_21626876: Call_DeleteRouteResponse_21626862; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_21626877 = newJObject()
  add(path_21626877, "apiId", newJString(apiId))
  add(path_21626877, "routeResponseId", newJString(routeResponseId))
  add(path_21626877, "routeId", newJString(routeId))
  result = call_21626876.call(path_21626877, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_21626862(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_21626863, base: "/",
    makeUrl: url_DeleteRouteResponse_21626864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_21626896 = ref object of OpenApiRestCall_21625435
proc url_DeleteRouteSettings_21626898(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  assert "routeKey" in path, "`routeKey` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName"),
               (kind: ConstantSegment, value: "/routesettings/"),
               (kind: VariableSegment, value: "routeKey")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRouteSettings_21626897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the RouteSettings for a stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeKey: JString (required)
  ##           : The route key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_21626899 = path.getOrDefault("stageName")
  valid_21626899 = validateParameter(valid_21626899, JString, required = true,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "stageName", valid_21626899
  var valid_21626900 = path.getOrDefault("apiId")
  valid_21626900 = validateParameter(valid_21626900, JString, required = true,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "apiId", valid_21626900
  var valid_21626901 = path.getOrDefault("routeKey")
  valid_21626901 = validateParameter(valid_21626901, JString, required = true,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "routeKey", valid_21626901
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626902 = header.getOrDefault("X-Amz-Date")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Date", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Security-Token", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Algorithm", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Signature")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Signature", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-Credential")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Credential", valid_21626908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626909: Call_DeleteRouteSettings_21626896; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the RouteSettings for a stage.
  ## 
  let valid = call_21626909.validator(path, query, header, formData, body, _)
  let scheme = call_21626909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626909.makeUrl(scheme.get, call_21626909.host, call_21626909.base,
                               call_21626909.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626909, uri, valid, _)

proc call*(call_21626910: Call_DeleteRouteSettings_21626896; stageName: string;
          apiId: string; routeKey: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeKey: string (required)
  ##           : The route key.
  var path_21626911 = newJObject()
  add(path_21626911, "stageName", newJString(stageName))
  add(path_21626911, "apiId", newJString(apiId))
  add(path_21626911, "routeKey", newJString(routeKey))
  result = call_21626910.call(path_21626911, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_21626896(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_21626897, base: "/",
    makeUrl: url_DeleteRouteSettings_21626898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_21626912 = ref object of OpenApiRestCall_21625435
proc url_GetStage_21626914(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStage_21626913(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_21626915 = path.getOrDefault("stageName")
  valid_21626915 = validateParameter(valid_21626915, JString, required = true,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "stageName", valid_21626915
  var valid_21626916 = path.getOrDefault("apiId")
  valid_21626916 = validateParameter(valid_21626916, JString, required = true,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "apiId", valid_21626916
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Algorithm", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Signature")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Signature", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-Credential")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-Credential", valid_21626923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626924: Call_GetStage_21626912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_21626924.validator(path, query, header, formData, body, _)
  let scheme = call_21626924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626924.makeUrl(scheme.get, call_21626924.host, call_21626924.base,
                               call_21626924.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626924, uri, valid, _)

proc call*(call_21626925: Call_GetStage_21626912; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_21626926 = newJObject()
  add(path_21626926, "stageName", newJString(stageName))
  add(path_21626926, "apiId", newJString(apiId))
  result = call_21626925.call(path_21626926, nil, nil, nil, nil)

var getStage* = Call_GetStage_21626912(name: "getStage", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                    validator: validate_GetStage_21626913,
                                    base: "/", makeUrl: url_GetStage_21626914,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_21626942 = ref object of OpenApiRestCall_21625435
proc url_UpdateStage_21626944(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStage_21626943(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_21626945 = path.getOrDefault("stageName")
  valid_21626945 = validateParameter(valid_21626945, JString, required = true,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "stageName", valid_21626945
  var valid_21626946 = path.getOrDefault("apiId")
  valid_21626946 = validateParameter(valid_21626946, JString, required = true,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "apiId", valid_21626946
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626947 = header.getOrDefault("X-Amz-Date")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Date", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Security-Token", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Algorithm", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Signature")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Signature", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Credential")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Credential", valid_21626953
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

proc call*(call_21626955: Call_UpdateStage_21626942; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_21626955.validator(path, query, header, formData, body, _)
  let scheme = call_21626955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626955.makeUrl(scheme.get, call_21626955.host, call_21626955.base,
                               call_21626955.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626955, uri, valid, _)

proc call*(call_21626956: Call_UpdateStage_21626942; stageName: string;
          apiId: string; body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_21626957 = newJObject()
  var body_21626958 = newJObject()
  add(path_21626957, "stageName", newJString(stageName))
  add(path_21626957, "apiId", newJString(apiId))
  if body != nil:
    body_21626958 = body
  result = call_21626956.call(path_21626957, nil, nil, nil, body_21626958)

var updateStage* = Call_UpdateStage_21626942(name: "updateStage",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}", validator: validate_UpdateStage_21626943,
    base: "/", makeUrl: url_UpdateStage_21626944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_21626927 = ref object of OpenApiRestCall_21625435
proc url_DeleteStage_21626929(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStage_21626928(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_21626930 = path.getOrDefault("stageName")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "stageName", valid_21626930
  var valid_21626931 = path.getOrDefault("apiId")
  valid_21626931 = validateParameter(valid_21626931, JString, required = true,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "apiId", valid_21626931
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626932 = header.getOrDefault("X-Amz-Date")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Date", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Security-Token", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Algorithm", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Signature")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Signature", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Credential")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Credential", valid_21626938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626939: Call_DeleteStage_21626927; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_21626939.validator(path, query, header, formData, body, _)
  let scheme = call_21626939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626939.makeUrl(scheme.get, call_21626939.host, call_21626939.base,
                               call_21626939.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626939, uri, valid, _)

proc call*(call_21626940: Call_DeleteStage_21626927; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_21626941 = newJObject()
  add(path_21626941, "stageName", newJString(stageName))
  add(path_21626941, "apiId", newJString(apiId))
  result = call_21626940.call(path_21626941, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_21626927(name: "deleteStage",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}", validator: validate_DeleteStage_21626928,
    base: "/", makeUrl: url_DeleteStage_21626929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_21626959 = ref object of OpenApiRestCall_21625435
proc url_GetModelTemplate_21626961(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId"),
               (kind: ConstantSegment, value: "/template")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetModelTemplate_21626960(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a model template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626962 = path.getOrDefault("apiId")
  valid_21626962 = validateParameter(valid_21626962, JString, required = true,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "apiId", valid_21626962
  var valid_21626963 = path.getOrDefault("modelId")
  valid_21626963 = validateParameter(valid_21626963, JString, required = true,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "modelId", valid_21626963
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626964 = header.getOrDefault("X-Amz-Date")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Date", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Security-Token", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Algorithm", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Signature")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Signature", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Credential")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Credential", valid_21626970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626971: Call_GetModelTemplate_21626959; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_21626971.validator(path, query, header, formData, body, _)
  let scheme = call_21626971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626971.makeUrl(scheme.get, call_21626971.host, call_21626971.base,
                               call_21626971.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626971, uri, valid, _)

proc call*(call_21626972: Call_GetModelTemplate_21626959; apiId: string;
          modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_21626973 = newJObject()
  add(path_21626973, "apiId", newJString(apiId))
  add(path_21626973, "modelId", newJString(modelId))
  result = call_21626972.call(path_21626973, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_21626959(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_21626960, base: "/",
    makeUrl: url_GetModelTemplate_21626961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626988 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626990(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626989(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new Tag resource to represent a tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626991 = path.getOrDefault("resource-arn")
  valid_21626991 = validateParameter(valid_21626991, JString, required = true,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "resource-arn", valid_21626991
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626992 = header.getOrDefault("X-Amz-Date")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Date", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Security-Token", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Algorithm", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Signature")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Signature", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Credential")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Credential", valid_21626998
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

proc call*(call_21627000: Call_TagResource_21626988; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Tag resource to represent a tag.
  ## 
  let valid = call_21627000.validator(path, query, header, formData, body, _)
  let scheme = call_21627000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627000.makeUrl(scheme.get, call_21627000.host, call_21627000.base,
                               call_21627000.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627000, uri, valid, _)

proc call*(call_21627001: Call_TagResource_21626988; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  ##   body: JObject (required)
  var path_21627002 = newJObject()
  var body_21627003 = newJObject()
  add(path_21627002, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21627003 = body
  result = call_21627001.call(path_21627002, nil, nil, nil, body_21627003)

var tagResource* = Call_TagResource_21626988(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}", validator: validate_TagResource_21626989,
    base: "/", makeUrl: url_TagResource_21626990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_21626974 = ref object of OpenApiRestCall_21625435
proc url_GetTags_21626976(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTags_21626975(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a collection of Tag resources.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626977 = path.getOrDefault("resource-arn")
  valid_21626977 = validateParameter(valid_21626977, JString, required = true,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "resource-arn", valid_21626977
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626978 = header.getOrDefault("X-Amz-Date")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Date", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Security-Token", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Algorithm", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Signature")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Signature", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Credential")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Credential", valid_21626984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626985: Call_GetTags_21626974; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a collection of Tag resources.
  ## 
  let valid = call_21626985.validator(path, query, header, formData, body, _)
  let scheme = call_21626985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626985.makeUrl(scheme.get, call_21626985.host, call_21626985.base,
                               call_21626985.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626985, uri, valid, _)

proc call*(call_21626986: Call_GetTags_21626974; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_21626987 = newJObject()
  add(path_21626987, "resource-arn", newJString(resourceArn))
  result = call_21626986.call(path_21626987, nil, nil, nil, nil)

var getTags* = Call_GetTags_21626974(name: "getTags", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/tags/{resource-arn}",
                                  validator: validate_GetTags_21626975, base: "/",
                                  makeUrl: url_GetTags_21626976,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627004 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627006(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21627005(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a Tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The resource ARN for the tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21627007 = path.getOrDefault("resource-arn")
  valid_21627007 = validateParameter(valid_21627007, JString, required = true,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "resource-arn", valid_21627007
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21627008 = query.getOrDefault("tagKeys")
  valid_21627008 = validateParameter(valid_21627008, JArray, required = true,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "tagKeys", valid_21627008
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_21627016: Call_UntagResource_21627004; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Tag.
  ## 
  let valid = call_21627016.validator(path, query, header, formData, body, _)
  let scheme = call_21627016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627016.makeUrl(scheme.get, call_21627016.host, call_21627016.base,
                               call_21627016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627016, uri, valid, _)

proc call*(call_21627017: Call_UntagResource_21627004; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>The Tag keys to delete.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : The resource ARN for the tag.
  var path_21627018 = newJObject()
  var query_21627019 = newJObject()
  if tagKeys != nil:
    query_21627019.add "tagKeys", tagKeys
  add(path_21627018, "resource-arn", newJString(resourceArn))
  result = call_21627017.call(path_21627018, query_21627019, nil, nil, nil)

var untagResource* = Call_UntagResource_21627004(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21627005,
    base: "/", makeUrl: url_UntagResource_21627006,
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