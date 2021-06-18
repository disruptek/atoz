
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "apigateway.ap-northeast-1.amazonaws.com", "ap-southeast-1": "apigateway.ap-southeast-1.amazonaws.com", "us-west-2": "apigateway.us-west-2.amazonaws.com", "eu-west-2": "apigateway.eu-west-2.amazonaws.com", "ap-northeast-3": "apigateway.ap-northeast-3.amazonaws.com", "eu-central-1": "apigateway.eu-central-1.amazonaws.com", "us-east-2": "apigateway.us-east-2.amazonaws.com", "us-east-1": "apigateway.us-east-1.amazonaws.com", "cn-northwest-1": "apigateway.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "apigateway.ap-south-1.amazonaws.com", "eu-north-1": "apigateway.eu-north-1.amazonaws.com", "ap-northeast-2": "apigateway.ap-northeast-2.amazonaws.com", "us-west-1": "apigateway.us-west-1.amazonaws.com", "us-gov-east-1": "apigateway.us-gov-east-1.amazonaws.com", "eu-west-3": "apigateway.eu-west-3.amazonaws.com", "cn-north-1": "apigateway.cn-north-1.amazonaws.com.cn", "sa-east-1": "apigateway.sa-east-1.amazonaws.com", "eu-west-1": "apigateway.eu-west-1.amazonaws.com", "us-gov-west-1": "apigateway.us-gov-west-1.amazonaws.com", "ap-southeast-2": "apigateway.ap-southeast-2.amazonaws.com", "ca-central-1": "apigateway.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_ImportApi_402656477 = ref object of OpenApiRestCall_402656044
proc url_ImportApi_402656479(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportApi_402656478(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  ##   
                                                                                                                            ## failOnWarnings: JBool
                                                                                                                            ##                 
                                                                                                                            ## : 
                                                                                                                            ## Specifies 
                                                                                                                            ## whether 
                                                                                                                            ## to 
                                                                                                                            ## rollback 
                                                                                                                            ## the 
                                                                                                                            ## API 
                                                                                                                            ## creation 
                                                                                                                            ## (true) 
                                                                                                                            ## or 
                                                                                                                            ## not 
                                                                                                                            ## (false) 
                                                                                                                            ## when 
                                                                                                                            ## a 
                                                                                                                            ## warning 
                                                                                                                            ## is 
                                                                                                                            ## encountered. 
                                                                                                                            ## The 
                                                                                                                            ## default 
                                                                                                                            ## value 
                                                                                                                            ## is 
                                                                                                                            ## false.
  section = newJObject()
  var valid_402656480 = query.getOrDefault("basepath")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "basepath", valid_402656480
  var valid_402656481 = query.getOrDefault("failOnWarnings")
  valid_402656481 = validateParameter(valid_402656481, JBool, required = false,
                                      default = nil)
  if valid_402656481 != nil:
    section.add "failOnWarnings", valid_402656481
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656482 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Security-Token", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Signature")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Signature", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Algorithm", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Date")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Date", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Credential")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Credential", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656488
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

proc call*(call_402656490: Call_ImportApi_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports an API.
                                                                                         ## 
  let valid = call_402656490.validator(path, query, header, formData, body, _)
  let scheme = call_402656490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656490.makeUrl(scheme.get, call_402656490.host, call_402656490.base,
                                   call_402656490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656490, uri, valid, _)

proc call*(call_402656491: Call_ImportApi_402656477; body: JsonNode;
           basepath: string = ""; failOnWarnings: bool = false): Recallable =
  ## importApi
  ## Imports an API.
  ##   basepath: string
                    ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   
                                                                                                              ## failOnWarnings: bool
                                                                                                              ##                 
                                                                                                              ## : 
                                                                                                              ## Specifies 
                                                                                                              ## whether 
                                                                                                              ## to 
                                                                                                              ## rollback 
                                                                                                              ## the 
                                                                                                              ## API 
                                                                                                              ## creation 
                                                                                                              ## (true) 
                                                                                                              ## or 
                                                                                                              ## not 
                                                                                                              ## (false) 
                                                                                                              ## when 
                                                                                                              ## a 
                                                                                                              ## warning 
                                                                                                              ## is 
                                                                                                              ## encountered. 
                                                                                                              ## The 
                                                                                                              ## default 
                                                                                                              ## value 
                                                                                                              ## is 
                                                                                                              ## false.
  ##   
                                                                                                                       ## body: JObject (required)
  var query_402656492 = newJObject()
  var body_402656493 = newJObject()
  add(query_402656492, "basepath", newJString(basepath))
  add(query_402656492, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_402656493 = body
  result = call_402656491.call(nil, query_402656492, nil, nil, body_402656493)

var importApi* = Call_ImportApi_402656477(name: "importApi",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com",
    route: "/v2/apis", validator: validate_ImportApi_402656478, base: "/",
    makeUrl: url_ImportApi_402656479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApi_402656494 = ref object of OpenApiRestCall_402656044
proc url_CreateApi_402656496(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApi_402656495(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656497 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Security-Token", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Signature")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Signature", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Algorithm", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Date")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Date", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Credential")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Credential", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656503
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

proc call*(call_402656505: Call_CreateApi_402656494; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Api resource.
                                                                                         ## 
  let valid = call_402656505.validator(path, query, header, formData, body, _)
  let scheme = call_402656505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656505.makeUrl(scheme.get, call_402656505.host, call_402656505.base,
                                   call_402656505.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656505, uri, valid, _)

proc call*(call_402656506: Call_CreateApi_402656494; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_402656507 = newJObject()
  if body != nil:
    body_402656507 = body
  result = call_402656506.call(nil, nil, nil, nil, body_402656507)

var createApi* = Call_CreateApi_402656494(name: "createApi",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis", validator: validate_CreateApi_402656495, base: "/",
    makeUrl: url_CreateApi_402656496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetApis_402656296(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApis_402656295(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
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
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656375 = query.getOrDefault("maxResults")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "maxResults", valid_402656375
  var valid_402656376 = query.getOrDefault("nextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "nextToken", valid_402656376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_GetApis_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a collection of Api resources.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_GetApis_402656294; maxResults: string = "";
           nextToken: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   maxResults: string
                                        ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                         ## nextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## next 
                                                                                                                         ## page 
                                                                                                                         ## of 
                                                                                                                         ## elements 
                                                                                                                         ## from 
                                                                                                                         ## this 
                                                                                                                         ## collection. 
                                                                                                                         ## Not 
                                                                                                                         ## valid 
                                                                                                                         ## for 
                                                                                                                         ## the 
                                                                                                                         ## last 
                                                                                                                         ## element 
                                                                                                                         ## of 
                                                                                                                         ## the 
                                                                                                                         ## collection.
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJString(maxResults))
  add(query_402656447, "nextToken", newJString(nextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var getApis* = Call_GetApis_402656294(name: "getApis", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/apis",
                                      validator: validate_GetApis_402656295,
                                      base: "/", makeUrl: url_GetApis_402656296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_402656536 = ref object of OpenApiRestCall_402656044
proc url_CreateApiMapping_402656538(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_CreateApiMapping_402656537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656539 = path.getOrDefault("domainName")
  valid_402656539 = validateParameter(valid_402656539, JString, required = true,
                                      default = nil)
  if valid_402656539 != nil:
    section.add "domainName", valid_402656539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
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

proc call*(call_402656548: Call_CreateApiMapping_402656536;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an API mapping.
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_CreateApiMapping_402656536; domainName: string;
           body: JsonNode): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   domainName: string (required)
                            ##             : The domain name.
  ##   body: JObject (required)
  var path_402656550 = newJObject()
  var body_402656551 = newJObject()
  add(path_402656550, "domainName", newJString(domainName))
  if body != nil:
    body_402656551 = body
  result = call_402656549.call(path_402656550, nil, nil, nil, body_402656551)

var createApiMapping* = Call_CreateApiMapping_402656536(
    name: "createApiMapping", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_402656537, base: "/",
    makeUrl: url_CreateApiMapping_402656538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_402656508 = ref object of OpenApiRestCall_402656044
proc url_GetApiMappings_402656510(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMappings_402656509(path: JsonNode; query: JsonNode;
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
  var valid_402656522 = path.getOrDefault("domainName")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true,
                                      default = nil)
  if valid_402656522 != nil:
    section.add "domainName", valid_402656522
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656523 = query.getOrDefault("maxResults")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "maxResults", valid_402656523
  var valid_402656524 = query.getOrDefault("nextToken")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "nextToken", valid_402656524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656525 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Security-Token", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Signature")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Signature", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Algorithm", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Date")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Date", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Credential")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Credential", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656532: Call_GetApiMappings_402656508; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets API mappings.
                                                                                         ## 
  let valid = call_402656532.validator(path, query, header, formData, body, _)
  let scheme = call_402656532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656532.makeUrl(scheme.get, call_402656532.host, call_402656532.base,
                                   call_402656532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656532, uri, valid, _)

proc call*(call_402656533: Call_GetApiMappings_402656508; domainName: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getApiMappings
  ## Gets API mappings.
  ##   domainName: string (required)
                       ##             : The domain name.
  ##   maxResults: string
                                                        ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                         ## nextToken: string
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## next 
                                                                                                                                         ## page 
                                                                                                                                         ## of 
                                                                                                                                         ## elements 
                                                                                                                                         ## from 
                                                                                                                                         ## this 
                                                                                                                                         ## collection. 
                                                                                                                                         ## Not 
                                                                                                                                         ## valid 
                                                                                                                                         ## for 
                                                                                                                                         ## the 
                                                                                                                                         ## last 
                                                                                                                                         ## element 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## collection.
  var path_402656534 = newJObject()
  var query_402656535 = newJObject()
  add(path_402656534, "domainName", newJString(domainName))
  add(query_402656535, "maxResults", newJString(maxResults))
  add(query_402656535, "nextToken", newJString(nextToken))
  result = call_402656533.call(path_402656534, query_402656535, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_402656508(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_402656509, base: "/",
    makeUrl: url_GetApiMappings_402656510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_402656569 = ref object of OpenApiRestCall_402656044
proc url_CreateAuthorizer_402656571(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_CreateAuthorizer_402656570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656572 = path.getOrDefault("apiId")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "apiId", valid_402656572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656579
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

proc call*(call_402656581: Call_CreateAuthorizer_402656569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Authorizer for an API.
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_CreateAuthorizer_402656569; apiId: string;
           body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
                                      ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656583 = newJObject()
  var body_402656584 = newJObject()
  add(path_402656583, "apiId", newJString(apiId))
  if body != nil:
    body_402656584 = body
  result = call_402656582.call(path_402656583, nil, nil, nil, body_402656584)

var createAuthorizer* = Call_CreateAuthorizer_402656569(
    name: "createAuthorizer", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/authorizers",
    validator: validate_CreateAuthorizer_402656570, base: "/",
    makeUrl: url_CreateAuthorizer_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_402656552 = ref object of OpenApiRestCall_402656044
proc url_GetAuthorizers_402656554(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_402656553(path: JsonNode; query: JsonNode;
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
  var valid_402656555 = path.getOrDefault("apiId")
  valid_402656555 = validateParameter(valid_402656555, JString, required = true,
                                      default = nil)
  if valid_402656555 != nil:
    section.add "apiId", valid_402656555
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656556 = query.getOrDefault("maxResults")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "maxResults", valid_402656556
  var valid_402656557 = query.getOrDefault("nextToken")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "nextToken", valid_402656557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656565: Call_GetAuthorizers_402656552; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Authorizers for an API.
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_GetAuthorizers_402656552; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   maxResults: string
                                                                    ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                     ## nextToken: string
                                                                                                                                                     ##            
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## next 
                                                                                                                                                     ## page 
                                                                                                                                                     ## of 
                                                                                                                                                     ## elements 
                                                                                                                                                     ## from 
                                                                                                                                                     ## this 
                                                                                                                                                     ## collection. 
                                                                                                                                                     ## Not 
                                                                                                                                                     ## valid 
                                                                                                                                                     ## for 
                                                                                                                                                     ## the 
                                                                                                                                                     ## last 
                                                                                                                                                     ## element 
                                                                                                                                                     ## of 
                                                                                                                                                     ## the 
                                                                                                                                                     ## collection.
  var path_402656567 = newJObject()
  var query_402656568 = newJObject()
  add(path_402656567, "apiId", newJString(apiId))
  add(query_402656568, "maxResults", newJString(maxResults))
  add(query_402656568, "nextToken", newJString(nextToken))
  result = call_402656566.call(path_402656567, query_402656568, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_402656552(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_402656553,
    base: "/", makeUrl: url_GetAuthorizers_402656554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_402656602 = ref object of OpenApiRestCall_402656044
proc url_CreateDeployment_402656604(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_CreateDeployment_402656603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656605 = path.getOrDefault("apiId")
  valid_402656605 = validateParameter(valid_402656605, JString, required = true,
                                      default = nil)
  if valid_402656605 != nil:
    section.add "apiId", valid_402656605
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656606 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Security-Token", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Signature")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Signature", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Algorithm", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Date")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Date", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Credential")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Credential", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656612
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

proc call*(call_402656614: Call_CreateDeployment_402656602;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Deployment for an API.
                                                                                         ## 
  let valid = call_402656614.validator(path, query, header, formData, body, _)
  let scheme = call_402656614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656614.makeUrl(scheme.get, call_402656614.host, call_402656614.base,
                                   call_402656614.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656614, uri, valid, _)

proc call*(call_402656615: Call_CreateDeployment_402656602; apiId: string;
           body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656616 = newJObject()
  var body_402656617 = newJObject()
  add(path_402656616, "apiId", newJString(apiId))
  if body != nil:
    body_402656617 = body
  result = call_402656615.call(path_402656616, nil, nil, nil, body_402656617)

var createDeployment* = Call_CreateDeployment_402656602(
    name: "createDeployment", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/deployments",
    validator: validate_CreateDeployment_402656603, base: "/",
    makeUrl: url_CreateDeployment_402656604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_402656585 = ref object of OpenApiRestCall_402656044
proc url_GetDeployments_402656587(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_402656586(path: JsonNode; query: JsonNode;
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
  var valid_402656588 = path.getOrDefault("apiId")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true,
                                      default = nil)
  if valid_402656588 != nil:
    section.add "apiId", valid_402656588
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656589 = query.getOrDefault("maxResults")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "maxResults", valid_402656589
  var valid_402656590 = query.getOrDefault("nextToken")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "nextToken", valid_402656590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656598: Call_GetDeployments_402656585; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Deployments for an API.
                                                                                         ## 
  let valid = call_402656598.validator(path, query, header, formData, body, _)
  let scheme = call_402656598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656598.makeUrl(scheme.get, call_402656598.host, call_402656598.base,
                                   call_402656598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656598, uri, valid, _)

proc call*(call_402656599: Call_GetDeployments_402656585; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   maxResults: string
                                                                    ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                     ## nextToken: string
                                                                                                                                                     ##            
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## next 
                                                                                                                                                     ## page 
                                                                                                                                                     ## of 
                                                                                                                                                     ## elements 
                                                                                                                                                     ## from 
                                                                                                                                                     ## this 
                                                                                                                                                     ## collection. 
                                                                                                                                                     ## Not 
                                                                                                                                                     ## valid 
                                                                                                                                                     ## for 
                                                                                                                                                     ## the 
                                                                                                                                                     ## last 
                                                                                                                                                     ## element 
                                                                                                                                                     ## of 
                                                                                                                                                     ## the 
                                                                                                                                                     ## collection.
  var path_402656600 = newJObject()
  var query_402656601 = newJObject()
  add(path_402656600, "apiId", newJString(apiId))
  add(query_402656601, "maxResults", newJString(maxResults))
  add(query_402656601, "nextToken", newJString(nextToken))
  result = call_402656599.call(path_402656600, query_402656601, nil, nil, nil)

var getDeployments* = Call_GetDeployments_402656585(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_402656586,
    base: "/", makeUrl: url_GetDeployments_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_402656633 = ref object of OpenApiRestCall_402656044
proc url_CreateDomainName_402656635(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainName_402656634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Security-Token", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Signature")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Signature", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Algorithm", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Date")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Date", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Credential")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Credential", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656642
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

proc call*(call_402656644: Call_CreateDomainName_402656633;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a domain name.
                                                                                         ## 
  let valid = call_402656644.validator(path, query, header, formData, body, _)
  let scheme = call_402656644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656644.makeUrl(scheme.get, call_402656644.host, call_402656644.base,
                                   call_402656644.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656644, uri, valid, _)

proc call*(call_402656645: Call_CreateDomainName_402656633; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_402656646 = newJObject()
  if body != nil:
    body_402656646 = body
  result = call_402656645.call(nil, nil, nil, nil, body_402656646)

var createDomainName* = Call_CreateDomainName_402656633(
    name: "createDomainName", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/domainnames",
    validator: validate_CreateDomainName_402656634, base: "/",
    makeUrl: url_CreateDomainName_402656635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_402656618 = ref object of OpenApiRestCall_402656044
proc url_GetDomainNames_402656620(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomainNames_402656619(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656621 = query.getOrDefault("maxResults")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "maxResults", valid_402656621
  var valid_402656622 = query.getOrDefault("nextToken")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "nextToken", valid_402656622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656623 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Security-Token", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Signature")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Signature", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Algorithm", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Date")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Date", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Credential")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Credential", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656630: Call_GetDomainNames_402656618; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the domain names for an AWS account.
                                                                                         ## 
  let valid = call_402656630.validator(path, query, header, formData, body, _)
  let scheme = call_402656630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656630.makeUrl(scheme.get, call_402656630.host, call_402656630.base,
                                   call_402656630.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656630, uri, valid, _)

proc call*(call_402656631: Call_GetDomainNames_402656618;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   maxResults: string
                                              ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                               ## nextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## next 
                                                                                                                               ## page 
                                                                                                                               ## of 
                                                                                                                               ## elements 
                                                                                                                               ## from 
                                                                                                                               ## this 
                                                                                                                               ## collection. 
                                                                                                                               ## Not 
                                                                                                                               ## valid 
                                                                                                                               ## for 
                                                                                                                               ## the 
                                                                                                                               ## last 
                                                                                                                               ## element 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## collection.
  var query_402656632 = newJObject()
  add(query_402656632, "maxResults", newJString(maxResults))
  add(query_402656632, "nextToken", newJString(nextToken))
  result = call_402656631.call(nil, query_402656632, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_402656618(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_402656619,
    base: "/", makeUrl: url_GetDomainNames_402656620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_402656664 = ref object of OpenApiRestCall_402656044
proc url_CreateIntegration_402656666(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateIntegration_402656665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656667 = path.getOrDefault("apiId")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "apiId", valid_402656667
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
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

proc call*(call_402656676: Call_CreateIntegration_402656664;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Integration.
                                                                                         ## 
  let valid = call_402656676.validator(path, query, header, formData, body, _)
  let scheme = call_402656676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656676.makeUrl(scheme.get, call_402656676.host, call_402656676.base,
                                   call_402656676.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656676, uri, valid, _)

proc call*(call_402656677: Call_CreateIntegration_402656664; apiId: string;
           body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
                            ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656678 = newJObject()
  var body_402656679 = newJObject()
  add(path_402656678, "apiId", newJString(apiId))
  if body != nil:
    body_402656679 = body
  result = call_402656677.call(path_402656678, nil, nil, nil, body_402656679)

var createIntegration* = Call_CreateIntegration_402656664(
    name: "createIntegration", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations",
    validator: validate_CreateIntegration_402656665, base: "/",
    makeUrl: url_CreateIntegration_402656666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_402656647 = ref object of OpenApiRestCall_402656044
proc url_GetIntegrations_402656649(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_GetIntegrations_402656648(path: JsonNode; query: JsonNode;
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
  var valid_402656650 = path.getOrDefault("apiId")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "apiId", valid_402656650
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656651 = query.getOrDefault("maxResults")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "maxResults", valid_402656651
  var valid_402656652 = query.getOrDefault("nextToken")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "nextToken", valid_402656652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656653 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Security-Token", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Signature")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Signature", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Algorithm", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Date")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Date", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Credential")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Credential", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656660: Call_GetIntegrations_402656647; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Integrations for an API.
                                                                                         ## 
  let valid = call_402656660.validator(path, query, header, formData, body, _)
  let scheme = call_402656660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656660.makeUrl(scheme.get, call_402656660.host, call_402656660.base,
                                   call_402656660.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656660, uri, valid, _)

proc call*(call_402656661: Call_GetIntegrations_402656647; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   apiId: string (required)
                                      ##        : The API identifier.
  ##   maxResults: string
                                                                     ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                      ## nextToken: string
                                                                                                                                                      ##            
                                                                                                                                                      ## : 
                                                                                                                                                      ## The 
                                                                                                                                                      ## next 
                                                                                                                                                      ## page 
                                                                                                                                                      ## of 
                                                                                                                                                      ## elements 
                                                                                                                                                      ## from 
                                                                                                                                                      ## this 
                                                                                                                                                      ## collection. 
                                                                                                                                                      ## Not 
                                                                                                                                                      ## valid 
                                                                                                                                                      ## for 
                                                                                                                                                      ## the 
                                                                                                                                                      ## last 
                                                                                                                                                      ## element 
                                                                                                                                                      ## of 
                                                                                                                                                      ## the 
                                                                                                                                                      ## collection.
  var path_402656662 = newJObject()
  var query_402656663 = newJObject()
  add(path_402656662, "apiId", newJString(apiId))
  add(query_402656663, "maxResults", newJString(maxResults))
  add(query_402656663, "nextToken", newJString(nextToken))
  result = call_402656661.call(path_402656662, query_402656663, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_402656647(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_402656648,
    base: "/", makeUrl: url_GetIntegrations_402656649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_402656698 = ref object of OpenApiRestCall_402656044
proc url_CreateIntegrationResponse_402656700(protocol: Scheme; host: string;
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

proc validate_CreateIntegrationResponse_402656699(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656701 = path.getOrDefault("apiId")
  valid_402656701 = validateParameter(valid_402656701, JString, required = true,
                                      default = nil)
  if valid_402656701 != nil:
    section.add "apiId", valid_402656701
  var valid_402656702 = path.getOrDefault("integrationId")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true,
                                      default = nil)
  if valid_402656702 != nil:
    section.add "integrationId", valid_402656702
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_CreateIntegrationResponse_402656698;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an IntegrationResponses.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_CreateIntegrationResponse_402656698;
           apiId: string; integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   
                                                                    ## integrationId: string (required)
                                                                    ##                
                                                                    ## : 
                                                                    ## The 
                                                                    ## integration ID.
  ##   
                                                                                      ## body: JObject (required)
  var path_402656713 = newJObject()
  var body_402656714 = newJObject()
  add(path_402656713, "apiId", newJString(apiId))
  add(path_402656713, "integrationId", newJString(integrationId))
  if body != nil:
    body_402656714 = body
  result = call_402656712.call(path_402656713, nil, nil, nil, body_402656714)

var createIntegrationResponse* = Call_CreateIntegrationResponse_402656698(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_402656699, base: "/",
    makeUrl: url_CreateIntegrationResponse_402656700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_402656680 = ref object of OpenApiRestCall_402656044
proc url_GetIntegrationResponses_402656682(protocol: Scheme; host: string;
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

proc validate_GetIntegrationResponses_402656681(path: JsonNode; query: JsonNode;
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
  var valid_402656683 = path.getOrDefault("apiId")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "apiId", valid_402656683
  var valid_402656684 = path.getOrDefault("integrationId")
  valid_402656684 = validateParameter(valid_402656684, JString, required = true,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "integrationId", valid_402656684
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656685 = query.getOrDefault("maxResults")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "maxResults", valid_402656685
  var valid_402656686 = query.getOrDefault("nextToken")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "nextToken", valid_402656686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Security-Token", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Signature")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Signature", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Algorithm", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Date")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Date", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Credential")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Credential", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656694: Call_GetIntegrationResponses_402656680;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the IntegrationResponses for an Integration.
                                                                                         ## 
  let valid = call_402656694.validator(path, query, header, formData, body, _)
  let scheme = call_402656694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656694.makeUrl(scheme.get, call_402656694.host, call_402656694.base,
                                   call_402656694.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656694, uri, valid, _)

proc call*(call_402656695: Call_GetIntegrationResponses_402656680;
           apiId: string; integrationId: string; maxResults: string = "";
           nextToken: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   apiId: string (required)
                                                      ##        : The API identifier.
  ##   
                                                                                     ## maxResults: string
                                                                                     ##             
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## maximum 
                                                                                     ## number 
                                                                                     ## of 
                                                                                     ## elements 
                                                                                     ## to 
                                                                                     ## be 
                                                                                     ## returned 
                                                                                     ## for 
                                                                                     ## this 
                                                                                     ## resource.
  ##   
                                                                                                 ## integrationId: string (required)
                                                                                                 ##                
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## integration 
                                                                                                 ## ID.
  ##   
                                                                                                       ## nextToken: string
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## next 
                                                                                                       ## page 
                                                                                                       ## of 
                                                                                                       ## elements 
                                                                                                       ## from 
                                                                                                       ## this 
                                                                                                       ## collection. 
                                                                                                       ## Not 
                                                                                                       ## valid 
                                                                                                       ## for 
                                                                                                       ## the 
                                                                                                       ## last 
                                                                                                       ## element 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## collection.
  var path_402656696 = newJObject()
  var query_402656697 = newJObject()
  add(path_402656696, "apiId", newJString(apiId))
  add(query_402656697, "maxResults", newJString(maxResults))
  add(path_402656696, "integrationId", newJString(integrationId))
  add(query_402656697, "nextToken", newJString(nextToken))
  result = call_402656695.call(path_402656696, query_402656697, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_402656680(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_402656681, base: "/",
    makeUrl: url_GetIntegrationResponses_402656682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_402656732 = ref object of OpenApiRestCall_402656044
proc url_CreateModel_402656734(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_402656733(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656735 = path.getOrDefault("apiId")
  valid_402656735 = validateParameter(valid_402656735, JString, required = true,
                                      default = nil)
  if valid_402656735 != nil:
    section.add "apiId", valid_402656735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656736 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Security-Token", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Signature")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Signature", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Algorithm", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Date")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Date", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Credential")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Credential", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656742
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

proc call*(call_402656744: Call_CreateModel_402656732; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Model for an API.
                                                                                         ## 
  let valid = call_402656744.validator(path, query, header, formData, body, _)
  let scheme = call_402656744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656744.makeUrl(scheme.get, call_402656744.host, call_402656744.base,
                                   call_402656744.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656744, uri, valid, _)

proc call*(call_402656745: Call_CreateModel_402656732; apiId: string;
           body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656746 = newJObject()
  var body_402656747 = newJObject()
  add(path_402656746, "apiId", newJString(apiId))
  if body != nil:
    body_402656747 = body
  result = call_402656745.call(path_402656746, nil, nil, nil, body_402656747)

var createModel* = Call_CreateModel_402656732(name: "createModel",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models", validator: validate_CreateModel_402656733,
    base: "/", makeUrl: url_CreateModel_402656734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_402656715 = ref object of OpenApiRestCall_402656044
proc url_GetModels_402656717(protocol: Scheme; host: string; base: string;
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

proc validate_GetModels_402656716(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656718 = path.getOrDefault("apiId")
  valid_402656718 = validateParameter(valid_402656718, JString, required = true,
                                      default = nil)
  if valid_402656718 != nil:
    section.add "apiId", valid_402656718
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656719 = query.getOrDefault("maxResults")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "maxResults", valid_402656719
  var valid_402656720 = query.getOrDefault("nextToken")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "nextToken", valid_402656720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656721 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Security-Token", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Signature")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Signature", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Algorithm", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Date")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Date", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Credential")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Credential", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656728: Call_GetModels_402656715; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Models for an API.
                                                                                         ## 
  let valid = call_402656728.validator(path, query, header, formData, body, _)
  let scheme = call_402656728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656728.makeUrl(scheme.get, call_402656728.host, call_402656728.base,
                                   call_402656728.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656728, uri, valid, _)

proc call*(call_402656729: Call_GetModels_402656715; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   maxResults: string
                                                               ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                ## nextToken: string
                                                                                                                                                ##            
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## next 
                                                                                                                                                ## page 
                                                                                                                                                ## of 
                                                                                                                                                ## elements 
                                                                                                                                                ## from 
                                                                                                                                                ## this 
                                                                                                                                                ## collection. 
                                                                                                                                                ## Not 
                                                                                                                                                ## valid 
                                                                                                                                                ## for 
                                                                                                                                                ## the 
                                                                                                                                                ## last 
                                                                                                                                                ## element 
                                                                                                                                                ## of 
                                                                                                                                                ## the 
                                                                                                                                                ## collection.
  var path_402656730 = newJObject()
  var query_402656731 = newJObject()
  add(path_402656730, "apiId", newJString(apiId))
  add(query_402656731, "maxResults", newJString(maxResults))
  add(query_402656731, "nextToken", newJString(nextToken))
  result = call_402656729.call(path_402656730, query_402656731, nil, nil, nil)

var getModels* = Call_GetModels_402656715(name: "getModels",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models", validator: validate_GetModels_402656716,
    base: "/", makeUrl: url_GetModels_402656717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_402656765 = ref object of OpenApiRestCall_402656044
proc url_CreateRoute_402656767(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_402656766(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656768 = path.getOrDefault("apiId")
  valid_402656768 = validateParameter(valid_402656768, JString, required = true,
                                      default = nil)
  if valid_402656768 != nil:
    section.add "apiId", valid_402656768
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
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

proc call*(call_402656777: Call_CreateRoute_402656765; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Route for an API.
                                                                                         ## 
  let valid = call_402656777.validator(path, query, header, formData, body, _)
  let scheme = call_402656777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656777.makeUrl(scheme.get, call_402656777.host, call_402656777.base,
                                   call_402656777.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656777, uri, valid, _)

proc call*(call_402656778: Call_CreateRoute_402656765; apiId: string;
           body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656779 = newJObject()
  var body_402656780 = newJObject()
  add(path_402656779, "apiId", newJString(apiId))
  if body != nil:
    body_402656780 = body
  result = call_402656778.call(path_402656779, nil, nil, nil, body_402656780)

var createRoute* = Call_CreateRoute_402656765(name: "createRoute",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes", validator: validate_CreateRoute_402656766,
    base: "/", makeUrl: url_CreateRoute_402656767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_402656748 = ref object of OpenApiRestCall_402656044
proc url_GetRoutes_402656750(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoutes_402656749(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656751 = path.getOrDefault("apiId")
  valid_402656751 = validateParameter(valid_402656751, JString, required = true,
                                      default = nil)
  if valid_402656751 != nil:
    section.add "apiId", valid_402656751
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656752 = query.getOrDefault("maxResults")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "maxResults", valid_402656752
  var valid_402656753 = query.getOrDefault("nextToken")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "nextToken", valid_402656753
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656754 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Security-Token", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Signature")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Signature", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Algorithm", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Date")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Date", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Credential")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Credential", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656761: Call_GetRoutes_402656748; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Routes for an API.
                                                                                         ## 
  let valid = call_402656761.validator(path, query, header, formData, body, _)
  let scheme = call_402656761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656761.makeUrl(scheme.get, call_402656761.host, call_402656761.base,
                                   call_402656761.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656761, uri, valid, _)

proc call*(call_402656762: Call_GetRoutes_402656748; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   maxResults: string
                                                               ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                ## nextToken: string
                                                                                                                                                ##            
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## next 
                                                                                                                                                ## page 
                                                                                                                                                ## of 
                                                                                                                                                ## elements 
                                                                                                                                                ## from 
                                                                                                                                                ## this 
                                                                                                                                                ## collection. 
                                                                                                                                                ## Not 
                                                                                                                                                ## valid 
                                                                                                                                                ## for 
                                                                                                                                                ## the 
                                                                                                                                                ## last 
                                                                                                                                                ## element 
                                                                                                                                                ## of 
                                                                                                                                                ## the 
                                                                                                                                                ## collection.
  var path_402656763 = newJObject()
  var query_402656764 = newJObject()
  add(path_402656763, "apiId", newJString(apiId))
  add(query_402656764, "maxResults", newJString(maxResults))
  add(query_402656764, "nextToken", newJString(nextToken))
  result = call_402656762.call(path_402656763, query_402656764, nil, nil, nil)

var getRoutes* = Call_GetRoutes_402656748(name: "getRoutes",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes", validator: validate_GetRoutes_402656749,
    base: "/", makeUrl: url_GetRoutes_402656750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_402656799 = ref object of OpenApiRestCall_402656044
proc url_CreateRouteResponse_402656801(protocol: Scheme; host: string;
                                       base: string; route: string;
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
                 (kind: VariableSegment, value: "routeId"),
                 (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRouteResponse_402656800(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a RouteResponse for a Route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   apiId: JString (required)
                                                            ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402656802 = path.getOrDefault("routeId")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "routeId", valid_402656802
  var valid_402656803 = path.getOrDefault("apiId")
  valid_402656803 = validateParameter(valid_402656803, JString, required = true,
                                      default = nil)
  if valid_402656803 != nil:
    section.add "apiId", valid_402656803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656804 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Security-Token", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Signature")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Signature", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Algorithm", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Date")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Date", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Credential")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Credential", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656810
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

proc call*(call_402656812: Call_CreateRouteResponse_402656799;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a RouteResponse for a Route.
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_CreateRouteResponse_402656799; routeId: string;
           apiId: string; body: JsonNode): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   routeId: string (required)
                                         ##          : The route ID.
  ##   apiId: string (required)
                                                                    ##        : The API identifier.
  ##   
                                                                                                   ## body: JObject (required)
  var path_402656814 = newJObject()
  var body_402656815 = newJObject()
  add(path_402656814, "routeId", newJString(routeId))
  add(path_402656814, "apiId", newJString(apiId))
  if body != nil:
    body_402656815 = body
  result = call_402656813.call(path_402656814, nil, nil, nil, body_402656815)

var createRouteResponse* = Call_CreateRouteResponse_402656799(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_402656800, base: "/",
    makeUrl: url_CreateRouteResponse_402656801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_402656781 = ref object of OpenApiRestCall_402656044
proc url_GetRouteResponses_402656783(protocol: Scheme; host: string;
                                     base: string; route: string;
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
                 (kind: VariableSegment, value: "routeId"),
                 (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRouteResponses_402656782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the RouteResponses for a Route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   apiId: JString (required)
                                                            ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402656784 = path.getOrDefault("routeId")
  valid_402656784 = validateParameter(valid_402656784, JString, required = true,
                                      default = nil)
  if valid_402656784 != nil:
    section.add "routeId", valid_402656784
  var valid_402656785 = path.getOrDefault("apiId")
  valid_402656785 = validateParameter(valid_402656785, JString, required = true,
                                      default = nil)
  if valid_402656785 != nil:
    section.add "apiId", valid_402656785
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656786 = query.getOrDefault("maxResults")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "maxResults", valid_402656786
  var valid_402656787 = query.getOrDefault("nextToken")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "nextToken", valid_402656787
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656788 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Security-Token", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Signature")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Signature", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Algorithm", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Date")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Date", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Credential")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Credential", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656795: Call_GetRouteResponses_402656781;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the RouteResponses for a Route.
                                                                                         ## 
  let valid = call_402656795.validator(path, query, header, formData, body, _)
  let scheme = call_402656795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656795.makeUrl(scheme.get, call_402656795.host, call_402656795.base,
                                   call_402656795.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656795, uri, valid, _)

proc call*(call_402656796: Call_GetRouteResponses_402656781; routeId: string;
           apiId: string; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   routeId: string (required)
                                         ##          : The route ID.
  ##   apiId: string (required)
                                                                    ##        : The API identifier.
  ##   
                                                                                                   ## maxResults: string
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## maximum 
                                                                                                   ## number 
                                                                                                   ## of 
                                                                                                   ## elements 
                                                                                                   ## to 
                                                                                                   ## be 
                                                                                                   ## returned 
                                                                                                   ## for 
                                                                                                   ## this 
                                                                                                   ## resource.
  ##   
                                                                                                               ## nextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## next 
                                                                                                               ## page 
                                                                                                               ## of 
                                                                                                               ## elements 
                                                                                                               ## from 
                                                                                                               ## this 
                                                                                                               ## collection. 
                                                                                                               ## Not 
                                                                                                               ## valid 
                                                                                                               ## for 
                                                                                                               ## the 
                                                                                                               ## last 
                                                                                                               ## element 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## collection.
  var path_402656797 = newJObject()
  var query_402656798 = newJObject()
  add(path_402656797, "routeId", newJString(routeId))
  add(path_402656797, "apiId", newJString(apiId))
  add(query_402656798, "maxResults", newJString(maxResults))
  add(query_402656798, "nextToken", newJString(nextToken))
  result = call_402656796.call(path_402656797, query_402656798, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_402656781(
    name: "getRouteResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_402656782, base: "/",
    makeUrl: url_GetRouteResponses_402656783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_402656833 = ref object of OpenApiRestCall_402656044
proc url_CreateStage_402656835(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_402656834(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656836 = path.getOrDefault("apiId")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "apiId", valid_402656836
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
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

proc call*(call_402656845: Call_CreateStage_402656833; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Stage for an API.
                                                                                         ## 
  let valid = call_402656845.validator(path, query, header, formData, body, _)
  let scheme = call_402656845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656845.makeUrl(scheme.get, call_402656845.host, call_402656845.base,
                                   call_402656845.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656845, uri, valid, _)

proc call*(call_402656846: Call_CreateStage_402656833; apiId: string;
           body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656847 = newJObject()
  var body_402656848 = newJObject()
  add(path_402656847, "apiId", newJString(apiId))
  if body != nil:
    body_402656848 = body
  result = call_402656846.call(path_402656847, nil, nil, nil, body_402656848)

var createStage* = Call_CreateStage_402656833(name: "createStage",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages", validator: validate_CreateStage_402656834,
    base: "/", makeUrl: url_CreateStage_402656835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_402656816 = ref object of OpenApiRestCall_402656044
proc url_GetStages_402656818(protocol: Scheme; host: string; base: string;
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

proc validate_GetStages_402656817(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656819 = path.getOrDefault("apiId")
  valid_402656819 = validateParameter(valid_402656819, JString, required = true,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "apiId", valid_402656819
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## next 
                                                                                                                   ## page 
                                                                                                                   ## of 
                                                                                                                   ## elements 
                                                                                                                   ## from 
                                                                                                                   ## this 
                                                                                                                   ## collection. 
                                                                                                                   ## Not 
                                                                                                                   ## valid 
                                                                                                                   ## for 
                                                                                                                   ## the 
                                                                                                                   ## last 
                                                                                                                   ## element 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## collection.
  section = newJObject()
  var valid_402656820 = query.getOrDefault("maxResults")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "maxResults", valid_402656820
  var valid_402656821 = query.getOrDefault("nextToken")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "nextToken", valid_402656821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Security-Token", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Signature")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Signature", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Algorithm", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Date")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Date", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Credential")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Credential", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656829: Call_GetStages_402656816; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Stages for an API.
                                                                                         ## 
  let valid = call_402656829.validator(path, query, header, formData, body, _)
  let scheme = call_402656829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656829.makeUrl(scheme.get, call_402656829.host, call_402656829.base,
                                   call_402656829.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656829, uri, valid, _)

proc call*(call_402656830: Call_GetStages_402656816; apiId: string;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   apiId: string (required)
                                ##        : The API identifier.
  ##   maxResults: string
                                                               ##             : The maximum number of elements to be returned for this resource.
  ##   
                                                                                                                                                ## nextToken: string
                                                                                                                                                ##            
                                                                                                                                                ## : 
                                                                                                                                                ## The 
                                                                                                                                                ## next 
                                                                                                                                                ## page 
                                                                                                                                                ## of 
                                                                                                                                                ## elements 
                                                                                                                                                ## from 
                                                                                                                                                ## this 
                                                                                                                                                ## collection. 
                                                                                                                                                ## Not 
                                                                                                                                                ## valid 
                                                                                                                                                ## for 
                                                                                                                                                ## the 
                                                                                                                                                ## last 
                                                                                                                                                ## element 
                                                                                                                                                ## of 
                                                                                                                                                ## the 
                                                                                                                                                ## collection.
  var path_402656831 = newJObject()
  var query_402656832 = newJObject()
  add(path_402656831, "apiId", newJString(apiId))
  add(query_402656832, "maxResults", newJString(maxResults))
  add(query_402656832, "nextToken", newJString(nextToken))
  result = call_402656830.call(path_402656831, query_402656832, nil, nil, nil)

var getStages* = Call_GetStages_402656816(name: "getStages",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages", validator: validate_GetStages_402656817,
    base: "/", makeUrl: url_GetStages_402656818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReimportApi_402656863 = ref object of OpenApiRestCall_402656044
proc url_ReimportApi_402656865(protocol: Scheme; host: string; base: string;
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

proc validate_ReimportApi_402656864(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656866 = path.getOrDefault("apiId")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "apiId", valid_402656866
  result.add "path", section
  ## parameters in `query` object:
  ##   basepath: JString
                                  ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   
                                                                                                                            ## failOnWarnings: JBool
                                                                                                                            ##                 
                                                                                                                            ## : 
                                                                                                                            ## Specifies 
                                                                                                                            ## whether 
                                                                                                                            ## to 
                                                                                                                            ## rollback 
                                                                                                                            ## the 
                                                                                                                            ## API 
                                                                                                                            ## creation 
                                                                                                                            ## (true) 
                                                                                                                            ## or 
                                                                                                                            ## not 
                                                                                                                            ## (false) 
                                                                                                                            ## when 
                                                                                                                            ## a 
                                                                                                                            ## warning 
                                                                                                                            ## is 
                                                                                                                            ## encountered. 
                                                                                                                            ## The 
                                                                                                                            ## default 
                                                                                                                            ## value 
                                                                                                                            ## is 
                                                                                                                            ## false.
  section = newJObject()
  var valid_402656867 = query.getOrDefault("basepath")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "basepath", valid_402656867
  var valid_402656868 = query.getOrDefault("failOnWarnings")
  valid_402656868 = validateParameter(valid_402656868, JBool, required = false,
                                      default = nil)
  if valid_402656868 != nil:
    section.add "failOnWarnings", valid_402656868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656869 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Security-Token", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Signature")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Signature", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Algorithm", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Date")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Date", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Credential")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Credential", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656875
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

proc call*(call_402656877: Call_ReimportApi_402656863; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Puts an Api resource.
                                                                                         ## 
  let valid = call_402656877.validator(path, query, header, formData, body, _)
  let scheme = call_402656877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656877.makeUrl(scheme.get, call_402656877.host, call_402656877.base,
                                   call_402656877.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656877, uri, valid, _)

proc call*(call_402656878: Call_ReimportApi_402656863; apiId: string;
           body: JsonNode; basepath: string = ""; failOnWarnings: bool = false): Recallable =
  ## reimportApi
  ## Puts an Api resource.
  ##   basepath: string
                          ##           : Represents the base path of the imported API. Supported only for HTTP APIs.
  ##   
                                                                                                                    ## apiId: string (required)
                                                                                                                    ##        
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## API 
                                                                                                                    ## identifier.
  ##   
                                                                                                                                  ## failOnWarnings: bool
                                                                                                                                  ##                 
                                                                                                                                  ## : 
                                                                                                                                  ## Specifies 
                                                                                                                                  ## whether 
                                                                                                                                  ## to 
                                                                                                                                  ## rollback 
                                                                                                                                  ## the 
                                                                                                                                  ## API 
                                                                                                                                  ## creation 
                                                                                                                                  ## (true) 
                                                                                                                                  ## or 
                                                                                                                                  ## not 
                                                                                                                                  ## (false) 
                                                                                                                                  ## when 
                                                                                                                                  ## a 
                                                                                                                                  ## warning 
                                                                                                                                  ## is 
                                                                                                                                  ## encountered. 
                                                                                                                                  ## The 
                                                                                                                                  ## default 
                                                                                                                                  ## value 
                                                                                                                                  ## is 
                                                                                                                                  ## false.
  ##   
                                                                                                                                           ## body: JObject (required)
  var path_402656879 = newJObject()
  var query_402656880 = newJObject()
  var body_402656881 = newJObject()
  add(query_402656880, "basepath", newJString(basepath))
  add(path_402656879, "apiId", newJString(apiId))
  add(query_402656880, "failOnWarnings", newJBool(failOnWarnings))
  if body != nil:
    body_402656881 = body
  result = call_402656878.call(path_402656879, query_402656880, nil, nil, body_402656881)

var reimportApi* = Call_ReimportApi_402656863(name: "reimportApi",
    meth: HttpMethod.HttpPut, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}", validator: validate_ReimportApi_402656864,
    base: "/", makeUrl: url_ReimportApi_402656865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_402656849 = ref object of OpenApiRestCall_402656044
proc url_GetApi_402656851(protocol: Scheme; host: string; base: string;
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

proc validate_GetApi_402656850(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656852 = path.getOrDefault("apiId")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true,
                                      default = nil)
  if valid_402656852 != nil:
    section.add "apiId", valid_402656852
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656860: Call_GetApi_402656849; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Api resource.
                                                                                         ## 
  let valid = call_402656860.validator(path, query, header, formData, body, _)
  let scheme = call_402656860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656860.makeUrl(scheme.get, call_402656860.host, call_402656860.base,
                                   call_402656860.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656860, uri, valid, _)

proc call*(call_402656861: Call_GetApi_402656849; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
                          ##        : The API identifier.
  var path_402656862 = newJObject()
  add(path_402656862, "apiId", newJString(apiId))
  result = call_402656861.call(path_402656862, nil, nil, nil, nil)

var getApi* = Call_GetApi_402656849(name: "getApi", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_GetApi_402656850,
                                    base: "/", makeUrl: url_GetApi_402656851,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_402656896 = ref object of OpenApiRestCall_402656044
proc url_UpdateApi_402656898(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApi_402656897(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656899 = path.getOrDefault("apiId")
  valid_402656899 = validateParameter(valid_402656899, JString, required = true,
                                      default = nil)
  if valid_402656899 != nil:
    section.add "apiId", valid_402656899
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Security-Token", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Signature")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Signature", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Algorithm", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Date")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Date", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Credential")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Credential", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656906
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

proc call*(call_402656908: Call_UpdateApi_402656896; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Api resource.
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_UpdateApi_402656896; apiId: string;
           body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
                             ##        : The API identifier.
  ##   body: JObject (required)
  var path_402656910 = newJObject()
  var body_402656911 = newJObject()
  add(path_402656910, "apiId", newJString(apiId))
  if body != nil:
    body_402656911 = body
  result = call_402656909.call(path_402656910, nil, nil, nil, body_402656911)

var updateApi* = Call_UpdateApi_402656896(name: "updateApi",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}", validator: validate_UpdateApi_402656897,
    base: "/", makeUrl: url_UpdateApi_402656898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_402656882 = ref object of OpenApiRestCall_402656044
proc url_DeleteApi_402656884(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApi_402656883(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656885 = path.getOrDefault("apiId")
  valid_402656885 = validateParameter(valid_402656885, JString, required = true,
                                      default = nil)
  if valid_402656885 != nil:
    section.add "apiId", valid_402656885
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656893: Call_DeleteApi_402656882; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Api resource.
                                                                                         ## 
  let valid = call_402656893.validator(path, query, header, formData, body, _)
  let scheme = call_402656893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656893.makeUrl(scheme.get, call_402656893.host, call_402656893.base,
                                   call_402656893.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656893, uri, valid, _)

proc call*(call_402656894: Call_DeleteApi_402656882; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
                             ##        : The API identifier.
  var path_402656895 = newJObject()
  add(path_402656895, "apiId", newJString(apiId))
  result = call_402656894.call(path_402656895, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_402656882(name: "deleteApi",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}", validator: validate_DeleteApi_402656883,
    base: "/", makeUrl: url_DeleteApi_402656884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_402656912 = ref object of OpenApiRestCall_402656044
proc url_GetApiMapping_402656914(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMapping_402656913(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656915 = path.getOrDefault("domainName")
  valid_402656915 = validateParameter(valid_402656915, JString, required = true,
                                      default = nil)
  if valid_402656915 != nil:
    section.add "domainName", valid_402656915
  var valid_402656916 = path.getOrDefault("apiMappingId")
  valid_402656916 = validateParameter(valid_402656916, JString, required = true,
                                      default = nil)
  if valid_402656916 != nil:
    section.add "apiMappingId", valid_402656916
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656917 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Security-Token", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Signature")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Signature", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Algorithm", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Date")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Date", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Credential")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Credential", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656924: Call_GetApiMapping_402656912; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an API mapping.
                                                                                         ## 
  let valid = call_402656924.validator(path, query, header, formData, body, _)
  let scheme = call_402656924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656924.makeUrl(scheme.get, call_402656924.host, call_402656924.base,
                                   call_402656924.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656924, uri, valid, _)

proc call*(call_402656925: Call_GetApiMapping_402656912; domainName: string;
           apiMappingId: string): Recallable =
  ## getApiMapping
  ## Gets an API mapping.
  ##   domainName: string (required)
                         ##             : The domain name.
  ##   apiMappingId: string (required)
                                                          ##               : The API mapping identifier.
  var path_402656926 = newJObject()
  add(path_402656926, "domainName", newJString(domainName))
  add(path_402656926, "apiMappingId", newJString(apiMappingId))
  result = call_402656925.call(path_402656926, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_402656912(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_402656913, base: "/",
    makeUrl: url_GetApiMapping_402656914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_402656942 = ref object of OpenApiRestCall_402656044
proc url_UpdateApiMapping_402656944(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateApiMapping_402656943(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656945 = path.getOrDefault("domainName")
  valid_402656945 = validateParameter(valid_402656945, JString, required = true,
                                      default = nil)
  if valid_402656945 != nil:
    section.add "domainName", valid_402656945
  var valid_402656946 = path.getOrDefault("apiMappingId")
  valid_402656946 = validateParameter(valid_402656946, JString, required = true,
                                      default = nil)
  if valid_402656946 != nil:
    section.add "apiMappingId", valid_402656946
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656947 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Security-Token", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Signature")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Signature", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Algorithm", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Date")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Date", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Credential")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Credential", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656953
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

proc call*(call_402656955: Call_UpdateApiMapping_402656942;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The API mapping.
                                                                                         ## 
  let valid = call_402656955.validator(path, query, header, formData, body, _)
  let scheme = call_402656955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656955.makeUrl(scheme.get, call_402656955.host, call_402656955.base,
                                   call_402656955.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656955, uri, valid, _)

proc call*(call_402656956: Call_UpdateApiMapping_402656942; domainName: string;
           body: JsonNode; apiMappingId: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   domainName: string (required)
                     ##             : The domain name.
  ##   body: JObject (required)
  ##   apiMappingId: string (required)
                               ##               : The API mapping identifier.
  var path_402656957 = newJObject()
  var body_402656958 = newJObject()
  add(path_402656957, "domainName", newJString(domainName))
  if body != nil:
    body_402656958 = body
  add(path_402656957, "apiMappingId", newJString(apiMappingId))
  result = call_402656956.call(path_402656957, nil, nil, nil, body_402656958)

var updateApiMapping* = Call_UpdateApiMapping_402656942(
    name: "updateApiMapping", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_402656943, base: "/",
    makeUrl: url_UpdateApiMapping_402656944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_402656927 = ref object of OpenApiRestCall_402656044
proc url_DeleteApiMapping_402656929(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteApiMapping_402656928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656930 = path.getOrDefault("domainName")
  valid_402656930 = validateParameter(valid_402656930, JString, required = true,
                                      default = nil)
  if valid_402656930 != nil:
    section.add "domainName", valid_402656930
  var valid_402656931 = path.getOrDefault("apiMappingId")
  valid_402656931 = validateParameter(valid_402656931, JString, required = true,
                                      default = nil)
  if valid_402656931 != nil:
    section.add "apiMappingId", valid_402656931
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656932 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Security-Token", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Signature")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Signature", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Algorithm", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Date")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Date", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Credential")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Credential", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656939: Call_DeleteApiMapping_402656927;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an API mapping.
                                                                                         ## 
  let valid = call_402656939.validator(path, query, header, formData, body, _)
  let scheme = call_402656939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656939.makeUrl(scheme.get, call_402656939.host, call_402656939.base,
                                   call_402656939.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656939, uri, valid, _)

proc call*(call_402656940: Call_DeleteApiMapping_402656927; domainName: string;
           apiMappingId: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   domainName: string (required)
                            ##             : The domain name.
  ##   apiMappingId: string (required)
                                                             ##               : The API mapping identifier.
  var path_402656941 = newJObject()
  add(path_402656941, "domainName", newJString(domainName))
  add(path_402656941, "apiMappingId", newJString(apiMappingId))
  result = call_402656940.call(path_402656941, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_402656927(
    name: "deleteApiMapping", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_402656928, base: "/",
    makeUrl: url_DeleteApiMapping_402656929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_402656959 = ref object of OpenApiRestCall_402656044
proc url_GetAuthorizer_402656961(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_402656960(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an Authorizer.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizerId: JString (required)
                                 ##               : The authorizer identifier.
  ##   
                                                                              ## apiId: JString (required)
                                                                              ##        
                                                                              ## : 
                                                                              ## The 
                                                                              ## API 
                                                                              ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `authorizerId` field"
  var valid_402656962 = path.getOrDefault("authorizerId")
  valid_402656962 = validateParameter(valid_402656962, JString, required = true,
                                      default = nil)
  if valid_402656962 != nil:
    section.add "authorizerId", valid_402656962
  var valid_402656963 = path.getOrDefault("apiId")
  valid_402656963 = validateParameter(valid_402656963, JString, required = true,
                                      default = nil)
  if valid_402656963 != nil:
    section.add "apiId", valid_402656963
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656964 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Security-Token", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Signature")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Signature", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Algorithm", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Date")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Date", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Credential")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Credential", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656971: Call_GetAuthorizer_402656959; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Authorizer.
                                                                                         ## 
  let valid = call_402656971.validator(path, query, header, formData, body, _)
  let scheme = call_402656971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656971.makeUrl(scheme.get, call_402656971.host, call_402656971.base,
                                   call_402656971.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656971, uri, valid, _)

proc call*(call_402656972: Call_GetAuthorizer_402656959; authorizerId: string;
           apiId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   authorizerId: string (required)
                        ##               : The authorizer identifier.
  ##   apiId: string (required)
                                                                     ##        : The API identifier.
  var path_402656973 = newJObject()
  add(path_402656973, "authorizerId", newJString(authorizerId))
  add(path_402656973, "apiId", newJString(apiId))
  result = call_402656972.call(path_402656973, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_402656959(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_402656960, base: "/",
    makeUrl: url_GetAuthorizer_402656961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_402656989 = ref object of OpenApiRestCall_402656044
proc url_UpdateAuthorizer_402656991(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateAuthorizer_402656990(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Authorizer.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizerId: JString (required)
                                 ##               : The authorizer identifier.
  ##   
                                                                              ## apiId: JString (required)
                                                                              ##        
                                                                              ## : 
                                                                              ## The 
                                                                              ## API 
                                                                              ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `authorizerId` field"
  var valid_402656992 = path.getOrDefault("authorizerId")
  valid_402656992 = validateParameter(valid_402656992, JString, required = true,
                                      default = nil)
  if valid_402656992 != nil:
    section.add "authorizerId", valid_402656992
  var valid_402656993 = path.getOrDefault("apiId")
  valid_402656993 = validateParameter(valid_402656993, JString, required = true,
                                      default = nil)
  if valid_402656993 != nil:
    section.add "apiId", valid_402656993
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656994 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Security-Token", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Signature")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Signature", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Algorithm", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Date")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Date", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Credential")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Credential", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657000
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

proc call*(call_402657002: Call_UpdateAuthorizer_402656989;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Authorizer.
                                                                                         ## 
  let valid = call_402657002.validator(path, query, header, formData, body, _)
  let scheme = call_402657002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657002.makeUrl(scheme.get, call_402657002.host, call_402657002.base,
                                   call_402657002.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657002, uri, valid, _)

proc call*(call_402657003: Call_UpdateAuthorizer_402656989;
           authorizerId: string; apiId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   authorizerId: string (required)
                           ##               : The authorizer identifier.
  ##   apiId: string 
                                                                        ## (required)
                                                                        ##        
                                                                        ## : 
                                                                        ## The API 
                                                                        ## identifier.
  ##   
                                                                                      ## body: JObject (required)
  var path_402657004 = newJObject()
  var body_402657005 = newJObject()
  add(path_402657004, "authorizerId", newJString(authorizerId))
  add(path_402657004, "apiId", newJString(apiId))
  if body != nil:
    body_402657005 = body
  result = call_402657003.call(path_402657004, nil, nil, nil, body_402657005)

var updateAuthorizer* = Call_UpdateAuthorizer_402656989(
    name: "updateAuthorizer", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_402656990, base: "/",
    makeUrl: url_UpdateAuthorizer_402656991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_402656974 = ref object of OpenApiRestCall_402656044
proc url_DeleteAuthorizer_402656976(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteAuthorizer_402656975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Authorizer.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   authorizerId: JString (required)
                                 ##               : The authorizer identifier.
  ##   
                                                                              ## apiId: JString (required)
                                                                              ##        
                                                                              ## : 
                                                                              ## The 
                                                                              ## API 
                                                                              ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `authorizerId` field"
  var valid_402656977 = path.getOrDefault("authorizerId")
  valid_402656977 = validateParameter(valid_402656977, JString, required = true,
                                      default = nil)
  if valid_402656977 != nil:
    section.add "authorizerId", valid_402656977
  var valid_402656978 = path.getOrDefault("apiId")
  valid_402656978 = validateParameter(valid_402656978, JString, required = true,
                                      default = nil)
  if valid_402656978 != nil:
    section.add "apiId", valid_402656978
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656979 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Security-Token", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Signature")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Signature", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Algorithm", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Date")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Date", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Credential")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Credential", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656986: Call_DeleteAuthorizer_402656974;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Authorizer.
                                                                                         ## 
  let valid = call_402656986.validator(path, query, header, formData, body, _)
  let scheme = call_402656986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656986.makeUrl(scheme.get, call_402656986.host, call_402656986.base,
                                   call_402656986.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656986, uri, valid, _)

proc call*(call_402656987: Call_DeleteAuthorizer_402656974;
           authorizerId: string; apiId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   authorizerId: string (required)
                           ##               : The authorizer identifier.
  ##   apiId: string 
                                                                        ## (required)
                                                                        ##        
                                                                        ## : 
                                                                        ## The API 
                                                                        ## identifier.
  var path_402656988 = newJObject()
  add(path_402656988, "authorizerId", newJString(authorizerId))
  add(path_402656988, "apiId", newJString(apiId))
  result = call_402656987.call(path_402656988, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_402656974(
    name: "deleteAuthorizer", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_402656975, base: "/",
    makeUrl: url_DeleteAuthorizer_402656976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCorsConfiguration_402657006 = ref object of OpenApiRestCall_402656044
proc url_DeleteCorsConfiguration_402657008(protocol: Scheme; host: string;
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

proc validate_DeleteCorsConfiguration_402657007(path: JsonNode; query: JsonNode;
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
  var valid_402657009 = path.getOrDefault("apiId")
  valid_402657009 = validateParameter(valid_402657009, JString, required = true,
                                      default = nil)
  if valid_402657009 != nil:
    section.add "apiId", valid_402657009
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657010 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Security-Token", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Signature")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Signature", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Algorithm", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Date")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Date", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Credential")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Credential", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657017: Call_DeleteCorsConfiguration_402657006;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a CORS configuration.
                                                                                         ## 
  let valid = call_402657017.validator(path, query, header, formData, body, _)
  let scheme = call_402657017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657017.makeUrl(scheme.get, call_402657017.host, call_402657017.base,
                                   call_402657017.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657017, uri, valid, _)

proc call*(call_402657018: Call_DeleteCorsConfiguration_402657006; apiId: string): Recallable =
  ## deleteCorsConfiguration
  ## Deletes a CORS configuration.
  ##   apiId: string (required)
                                  ##        : The API identifier.
  var path_402657019 = newJObject()
  add(path_402657019, "apiId", newJString(apiId))
  result = call_402657018.call(path_402657019, nil, nil, nil, nil)

var deleteCorsConfiguration* = Call_DeleteCorsConfiguration_402657006(
    name: "deleteCorsConfiguration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/cors",
    validator: validate_DeleteCorsConfiguration_402657007, base: "/",
    makeUrl: url_DeleteCorsConfiguration_402657008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_402657020 = ref object of OpenApiRestCall_402656044
proc url_GetDeployment_402657022(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_402657021(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deploymentId: JString (required)
                                 ##               : The deployment ID.
  ##   apiId: JString (required)
                                                                      ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deploymentId` field"
  var valid_402657023 = path.getOrDefault("deploymentId")
  valid_402657023 = validateParameter(valid_402657023, JString, required = true,
                                      default = nil)
  if valid_402657023 != nil:
    section.add "deploymentId", valid_402657023
  var valid_402657024 = path.getOrDefault("apiId")
  valid_402657024 = validateParameter(valid_402657024, JString, required = true,
                                      default = nil)
  if valid_402657024 != nil:
    section.add "apiId", valid_402657024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657025 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Security-Token", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Signature")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Signature", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Algorithm", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Date")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Date", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Credential")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Credential", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657032: Call_GetDeployment_402657020; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Deployment.
                                                                                         ## 
  let valid = call_402657032.validator(path, query, header, formData, body, _)
  let scheme = call_402657032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657032.makeUrl(scheme.get, call_402657032.host, call_402657032.base,
                                   call_402657032.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657032, uri, valid, _)

proc call*(call_402657033: Call_GetDeployment_402657020; deploymentId: string;
           apiId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   deploymentId: string (required)
                       ##               : The deployment ID.
  ##   apiId: string (required)
                                                            ##        : The API identifier.
  var path_402657034 = newJObject()
  add(path_402657034, "deploymentId", newJString(deploymentId))
  add(path_402657034, "apiId", newJString(apiId))
  result = call_402657033.call(path_402657034, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_402657020(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_402657021, base: "/",
    makeUrl: url_GetDeployment_402657022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_402657050 = ref object of OpenApiRestCall_402656044
proc url_UpdateDeployment_402657052(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateDeployment_402657051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deploymentId: JString (required)
                                 ##               : The deployment ID.
  ##   apiId: JString (required)
                                                                      ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deploymentId` field"
  var valid_402657053 = path.getOrDefault("deploymentId")
  valid_402657053 = validateParameter(valid_402657053, JString, required = true,
                                      default = nil)
  if valid_402657053 != nil:
    section.add "deploymentId", valid_402657053
  var valid_402657054 = path.getOrDefault("apiId")
  valid_402657054 = validateParameter(valid_402657054, JString, required = true,
                                      default = nil)
  if valid_402657054 != nil:
    section.add "apiId", valid_402657054
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657055 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Security-Token", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Signature")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Signature", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Algorithm", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Date")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Date", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Credential")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Credential", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657061
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

proc call*(call_402657063: Call_UpdateDeployment_402657050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Deployment.
                                                                                         ## 
  let valid = call_402657063.validator(path, query, header, formData, body, _)
  let scheme = call_402657063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657063.makeUrl(scheme.get, call_402657063.host, call_402657063.base,
                                   call_402657063.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657063, uri, valid, _)

proc call*(call_402657064: Call_UpdateDeployment_402657050;
           deploymentId: string; apiId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   deploymentId: string (required)
                          ##               : The deployment ID.
  ##   apiId: string (required)
                                                               ##        : The API identifier.
  ##   
                                                                                              ## body: JObject (required)
  var path_402657065 = newJObject()
  var body_402657066 = newJObject()
  add(path_402657065, "deploymentId", newJString(deploymentId))
  add(path_402657065, "apiId", newJString(apiId))
  if body != nil:
    body_402657066 = body
  result = call_402657064.call(path_402657065, nil, nil, nil, body_402657066)

var updateDeployment* = Call_UpdateDeployment_402657050(
    name: "updateDeployment", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_402657051, base: "/",
    makeUrl: url_UpdateDeployment_402657052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_402657035 = ref object of OpenApiRestCall_402656044
proc url_DeleteDeployment_402657037(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteDeployment_402657036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Deployment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deploymentId: JString (required)
                                 ##               : The deployment ID.
  ##   apiId: JString (required)
                                                                      ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deploymentId` field"
  var valid_402657038 = path.getOrDefault("deploymentId")
  valid_402657038 = validateParameter(valid_402657038, JString, required = true,
                                      default = nil)
  if valid_402657038 != nil:
    section.add "deploymentId", valid_402657038
  var valid_402657039 = path.getOrDefault("apiId")
  valid_402657039 = validateParameter(valid_402657039, JString, required = true,
                                      default = nil)
  if valid_402657039 != nil:
    section.add "apiId", valid_402657039
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657040 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Security-Token", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Signature")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Signature", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Algorithm", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Date")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Date", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Credential")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Credential", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657047: Call_DeleteDeployment_402657035;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Deployment.
                                                                                         ## 
  let valid = call_402657047.validator(path, query, header, formData, body, _)
  let scheme = call_402657047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657047.makeUrl(scheme.get, call_402657047.host, call_402657047.base,
                                   call_402657047.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657047, uri, valid, _)

proc call*(call_402657048: Call_DeleteDeployment_402657035;
           deploymentId: string; apiId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   deploymentId: string (required)
                          ##               : The deployment ID.
  ##   apiId: string (required)
                                                               ##        : The API identifier.
  var path_402657049 = newJObject()
  add(path_402657049, "deploymentId", newJString(deploymentId))
  add(path_402657049, "apiId", newJString(apiId))
  result = call_402657048.call(path_402657049, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_402657035(
    name: "deleteDeployment", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_402657036, base: "/",
    makeUrl: url_DeleteDeployment_402657037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_402657067 = ref object of OpenApiRestCall_402656044
proc url_GetDomainName_402657069(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_402657068(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657070 = path.getOrDefault("domainName")
  valid_402657070 = validateParameter(valid_402657070, JString, required = true,
                                      default = nil)
  if valid_402657070 != nil:
    section.add "domainName", valid_402657070
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657071 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Security-Token", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Signature")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Signature", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Algorithm", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Date")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Date", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Credential")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Credential", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657078: Call_GetDomainName_402657067; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a domain name.
                                                                                         ## 
  let valid = call_402657078.validator(path, query, header, formData, body, _)
  let scheme = call_402657078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657078.makeUrl(scheme.get, call_402657078.host, call_402657078.base,
                                   call_402657078.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657078, uri, valid, _)

proc call*(call_402657079: Call_GetDomainName_402657067; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
                        ##             : The domain name.
  var path_402657080 = newJObject()
  add(path_402657080, "domainName", newJString(domainName))
  result = call_402657079.call(path_402657080, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_402657067(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_402657068,
    base: "/", makeUrl: url_GetDomainName_402657069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_402657095 = ref object of OpenApiRestCall_402656044
proc url_UpdateDomainName_402657097(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateDomainName_402657096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657098 = path.getOrDefault("domainName")
  valid_402657098 = validateParameter(valid_402657098, JString, required = true,
                                      default = nil)
  if valid_402657098 != nil:
    section.add "domainName", valid_402657098
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657099 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Security-Token", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Signature")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Signature", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Algorithm", valid_402657102
  var valid_402657103 = header.getOrDefault("X-Amz-Date")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "X-Amz-Date", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-Credential")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-Credential", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657105
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

proc call*(call_402657107: Call_UpdateDomainName_402657095;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a domain name.
                                                                                         ## 
  let valid = call_402657107.validator(path, query, header, formData, body, _)
  let scheme = call_402657107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657107.makeUrl(scheme.get, call_402657107.host, call_402657107.base,
                                   call_402657107.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657107, uri, valid, _)

proc call*(call_402657108: Call_UpdateDomainName_402657095; domainName: string;
           body: JsonNode): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   domainName: string (required)
                           ##             : The domain name.
  ##   body: JObject (required)
  var path_402657109 = newJObject()
  var body_402657110 = newJObject()
  add(path_402657109, "domainName", newJString(domainName))
  if body != nil:
    body_402657110 = body
  result = call_402657108.call(path_402657109, nil, nil, nil, body_402657110)

var updateDomainName* = Call_UpdateDomainName_402657095(
    name: "updateDomainName", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/domainnames/{domainName}",
    validator: validate_UpdateDomainName_402657096, base: "/",
    makeUrl: url_UpdateDomainName_402657097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_402657081 = ref object of OpenApiRestCall_402656044
proc url_DeleteDomainName_402657083(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteDomainName_402657082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657084 = path.getOrDefault("domainName")
  valid_402657084 = validateParameter(valid_402657084, JString, required = true,
                                      default = nil)
  if valid_402657084 != nil:
    section.add "domainName", valid_402657084
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657085 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Security-Token", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Signature")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Signature", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Algorithm", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Date")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Date", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Credential")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Credential", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657092: Call_DeleteDomainName_402657081;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a domain name.
                                                                                         ## 
  let valid = call_402657092.validator(path, query, header, formData, body, _)
  let scheme = call_402657092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657092.makeUrl(scheme.get, call_402657092.host, call_402657092.base,
                                   call_402657092.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657092, uri, valid, _)

proc call*(call_402657093: Call_DeleteDomainName_402657081; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
                           ##             : The domain name.
  var path_402657094 = newJObject()
  add(path_402657094, "domainName", newJString(domainName))
  result = call_402657093.call(path_402657094, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_402657081(
    name: "deleteDomainName", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/domainnames/{domainName}",
    validator: validate_DeleteDomainName_402657082, base: "/",
    makeUrl: url_DeleteDomainName_402657083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_402657111 = ref object of OpenApiRestCall_402656044
proc url_GetIntegration_402657113(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_402657112(path: JsonNode; query: JsonNode;
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
  var valid_402657114 = path.getOrDefault("apiId")
  valid_402657114 = validateParameter(valid_402657114, JString, required = true,
                                      default = nil)
  if valid_402657114 != nil:
    section.add "apiId", valid_402657114
  var valid_402657115 = path.getOrDefault("integrationId")
  valid_402657115 = validateParameter(valid_402657115, JString, required = true,
                                      default = nil)
  if valid_402657115 != nil:
    section.add "integrationId", valid_402657115
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657116 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Security-Token", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Signature")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Signature", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Algorithm", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-Date")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-Date", valid_402657120
  var valid_402657121 = header.getOrDefault("X-Amz-Credential")
  valid_402657121 = validateParameter(valid_402657121, JString,
                                      required = false, default = nil)
  if valid_402657121 != nil:
    section.add "X-Amz-Credential", valid_402657121
  var valid_402657122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657123: Call_GetIntegration_402657111; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an Integration.
                                                                                         ## 
  let valid = call_402657123.validator(path, query, header, formData, body, _)
  let scheme = call_402657123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657123.makeUrl(scheme.get, call_402657123.host, call_402657123.base,
                                   call_402657123.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657123, uri, valid, _)

proc call*(call_402657124: Call_GetIntegration_402657111; apiId: string;
           integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
                         ##        : The API identifier.
  ##   integrationId: string (required)
                                                        ##                : The integration ID.
  var path_402657125 = newJObject()
  add(path_402657125, "apiId", newJString(apiId))
  add(path_402657125, "integrationId", newJString(integrationId))
  result = call_402657124.call(path_402657125, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_402657111(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_402657112, base: "/",
    makeUrl: url_GetIntegration_402657113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_402657141 = ref object of OpenApiRestCall_402656044
proc url_UpdateIntegration_402657143(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateIntegration_402657142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657144 = path.getOrDefault("apiId")
  valid_402657144 = validateParameter(valid_402657144, JString, required = true,
                                      default = nil)
  if valid_402657144 != nil:
    section.add "apiId", valid_402657144
  var valid_402657145 = path.getOrDefault("integrationId")
  valid_402657145 = validateParameter(valid_402657145, JString, required = true,
                                      default = nil)
  if valid_402657145 != nil:
    section.add "integrationId", valid_402657145
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657146 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-Security-Token", valid_402657146
  var valid_402657147 = header.getOrDefault("X-Amz-Signature")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Signature", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Algorithm", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-Date")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Date", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Credential")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Credential", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657152
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

proc call*(call_402657154: Call_UpdateIntegration_402657141;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Integration.
                                                                                         ## 
  let valid = call_402657154.validator(path, query, header, formData, body, _)
  let scheme = call_402657154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657154.makeUrl(scheme.get, call_402657154.host, call_402657154.base,
                                   call_402657154.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657154, uri, valid, _)

proc call*(call_402657155: Call_UpdateIntegration_402657141; apiId: string;
           integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
                            ##        : The API identifier.
  ##   integrationId: string (required)
                                                           ##                : The integration ID.
  ##   
                                                                                                  ## body: JObject (required)
  var path_402657156 = newJObject()
  var body_402657157 = newJObject()
  add(path_402657156, "apiId", newJString(apiId))
  add(path_402657156, "integrationId", newJString(integrationId))
  if body != nil:
    body_402657157 = body
  result = call_402657155.call(path_402657156, nil, nil, nil, body_402657157)

var updateIntegration* = Call_UpdateIntegration_402657141(
    name: "updateIntegration", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_402657142, base: "/",
    makeUrl: url_UpdateIntegration_402657143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_402657126 = ref object of OpenApiRestCall_402656044
proc url_DeleteIntegration_402657128(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteIntegration_402657127(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657129 = path.getOrDefault("apiId")
  valid_402657129 = validateParameter(valid_402657129, JString, required = true,
                                      default = nil)
  if valid_402657129 != nil:
    section.add "apiId", valid_402657129
  var valid_402657130 = path.getOrDefault("integrationId")
  valid_402657130 = validateParameter(valid_402657130, JString, required = true,
                                      default = nil)
  if valid_402657130 != nil:
    section.add "integrationId", valid_402657130
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657131 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Security-Token", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Signature")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Signature", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Algorithm", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Date")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Date", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Credential")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Credential", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657138: Call_DeleteIntegration_402657126;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Integration.
                                                                                         ## 
  let valid = call_402657138.validator(path, query, header, formData, body, _)
  let scheme = call_402657138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657138.makeUrl(scheme.get, call_402657138.host, call_402657138.base,
                                   call_402657138.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657138, uri, valid, _)

proc call*(call_402657139: Call_DeleteIntegration_402657126; apiId: string;
           integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
                            ##        : The API identifier.
  ##   integrationId: string (required)
                                                           ##                : The integration ID.
  var path_402657140 = newJObject()
  add(path_402657140, "apiId", newJString(apiId))
  add(path_402657140, "integrationId", newJString(integrationId))
  result = call_402657139.call(path_402657140, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_402657126(
    name: "deleteIntegration", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_402657127, base: "/",
    makeUrl: url_DeleteIntegration_402657128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_402657158 = ref object of OpenApiRestCall_402656044
proc url_GetIntegrationResponse_402657160(protocol: Scheme; host: string;
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

proc validate_GetIntegrationResponse_402657159(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets an IntegrationResponses.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The API identifier.
  ##   integrationId: JString (required)
                                                                ##                : The integration ID.
  ##   
                                                                                                       ## integrationResponseId: JString (required)
                                                                                                       ##                        
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## integration 
                                                                                                       ## response 
                                                                                                       ## ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402657161 = path.getOrDefault("apiId")
  valid_402657161 = validateParameter(valid_402657161, JString, required = true,
                                      default = nil)
  if valid_402657161 != nil:
    section.add "apiId", valid_402657161
  var valid_402657162 = path.getOrDefault("integrationId")
  valid_402657162 = validateParameter(valid_402657162, JString, required = true,
                                      default = nil)
  if valid_402657162 != nil:
    section.add "integrationId", valid_402657162
  var valid_402657163 = path.getOrDefault("integrationResponseId")
  valid_402657163 = validateParameter(valid_402657163, JString, required = true,
                                      default = nil)
  if valid_402657163 != nil:
    section.add "integrationResponseId", valid_402657163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657164 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Security-Token", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Signature")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Signature", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Algorithm", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Date")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Date", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Credential")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Credential", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657171: Call_GetIntegrationResponse_402657158;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets an IntegrationResponses.
                                                                                         ## 
  let valid = call_402657171.validator(path, query, header, formData, body, _)
  let scheme = call_402657171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657171.makeUrl(scheme.get, call_402657171.host, call_402657171.base,
                                   call_402657171.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657171, uri, valid, _)

proc call*(call_402657172: Call_GetIntegrationResponse_402657158; apiId: string;
           integrationId: string; integrationResponseId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   apiId: string (required)
                                  ##        : The API identifier.
  ##   integrationId: string (required)
                                                                 ##                : The integration ID.
  ##   
                                                                                                        ## integrationResponseId: string (required)
                                                                                                        ##                        
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## integration 
                                                                                                        ## response 
                                                                                                        ## ID.
  var path_402657173 = newJObject()
  add(path_402657173, "apiId", newJString(apiId))
  add(path_402657173, "integrationId", newJString(integrationId))
  add(path_402657173, "integrationResponseId", newJString(integrationResponseId))
  result = call_402657172.call(path_402657173, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_402657158(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_402657159, base: "/",
    makeUrl: url_GetIntegrationResponse_402657160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_402657190 = ref object of OpenApiRestCall_402656044
proc url_UpdateIntegrationResponse_402657192(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_402657191(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates an IntegrationResponses.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The API identifier.
  ##   integrationId: JString (required)
                                                                ##                : The integration ID.
  ##   
                                                                                                       ## integrationResponseId: JString (required)
                                                                                                       ##                        
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## integration 
                                                                                                       ## response 
                                                                                                       ## ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402657193 = path.getOrDefault("apiId")
  valid_402657193 = validateParameter(valid_402657193, JString, required = true,
                                      default = nil)
  if valid_402657193 != nil:
    section.add "apiId", valid_402657193
  var valid_402657194 = path.getOrDefault("integrationId")
  valid_402657194 = validateParameter(valid_402657194, JString, required = true,
                                      default = nil)
  if valid_402657194 != nil:
    section.add "integrationId", valid_402657194
  var valid_402657195 = path.getOrDefault("integrationResponseId")
  valid_402657195 = validateParameter(valid_402657195, JString, required = true,
                                      default = nil)
  if valid_402657195 != nil:
    section.add "integrationResponseId", valid_402657195
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657196 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "X-Amz-Security-Token", valid_402657196
  var valid_402657197 = header.getOrDefault("X-Amz-Signature")
  valid_402657197 = validateParameter(valid_402657197, JString,
                                      required = false, default = nil)
  if valid_402657197 != nil:
    section.add "X-Amz-Signature", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Algorithm", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Date")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Date", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Credential")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Credential", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657202
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

proc call*(call_402657204: Call_UpdateIntegrationResponse_402657190;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an IntegrationResponses.
                                                                                         ## 
  let valid = call_402657204.validator(path, query, header, formData, body, _)
  let scheme = call_402657204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657204.makeUrl(scheme.get, call_402657204.host, call_402657204.base,
                                   call_402657204.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657204, uri, valid, _)

proc call*(call_402657205: Call_UpdateIntegrationResponse_402657190;
           apiId: string; integrationId: string; body: JsonNode;
           integrationResponseId: string): Recallable =
  ## updateIntegrationResponse
  ## Updates an IntegrationResponses.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   
                                                                    ## integrationId: string (required)
                                                                    ##                
                                                                    ## : 
                                                                    ## The 
                                                                    ## integration ID.
  ##   
                                                                                      ## body: JObject (required)
  ##   
                                                                                                                 ## integrationResponseId: string (required)
                                                                                                                 ##                        
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## integration 
                                                                                                                 ## response 
                                                                                                                 ## ID.
  var path_402657206 = newJObject()
  var body_402657207 = newJObject()
  add(path_402657206, "apiId", newJString(apiId))
  add(path_402657206, "integrationId", newJString(integrationId))
  if body != nil:
    body_402657207 = body
  add(path_402657206, "integrationResponseId", newJString(integrationResponseId))
  result = call_402657205.call(path_402657206, nil, nil, nil, body_402657207)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_402657190(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_402657191, base: "/",
    makeUrl: url_UpdateIntegrationResponse_402657192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_402657174 = ref object of OpenApiRestCall_402656044
proc url_DeleteIntegrationResponse_402657176(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_402657175(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an IntegrationResponses.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The API identifier.
  ##   integrationId: JString (required)
                                                                ##                : The integration ID.
  ##   
                                                                                                       ## integrationResponseId: JString (required)
                                                                                                       ##                        
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## integration 
                                                                                                       ## response 
                                                                                                       ## ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402657177 = path.getOrDefault("apiId")
  valid_402657177 = validateParameter(valid_402657177, JString, required = true,
                                      default = nil)
  if valid_402657177 != nil:
    section.add "apiId", valid_402657177
  var valid_402657178 = path.getOrDefault("integrationId")
  valid_402657178 = validateParameter(valid_402657178, JString, required = true,
                                      default = nil)
  if valid_402657178 != nil:
    section.add "integrationId", valid_402657178
  var valid_402657179 = path.getOrDefault("integrationResponseId")
  valid_402657179 = validateParameter(valid_402657179, JString, required = true,
                                      default = nil)
  if valid_402657179 != nil:
    section.add "integrationResponseId", valid_402657179
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657180 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-Security-Token", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-Signature")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-Signature", valid_402657181
  var valid_402657182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657182 = validateParameter(valid_402657182, JString,
                                      required = false, default = nil)
  if valid_402657182 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Algorithm", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Date")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Date", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Credential")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Credential", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657187: Call_DeleteIntegrationResponse_402657174;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an IntegrationResponses.
                                                                                         ## 
  let valid = call_402657187.validator(path, query, header, formData, body, _)
  let scheme = call_402657187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657187.makeUrl(scheme.get, call_402657187.host, call_402657187.base,
                                   call_402657187.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657187, uri, valid, _)

proc call*(call_402657188: Call_DeleteIntegrationResponse_402657174;
           apiId: string; integrationId: string; integrationResponseId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   apiId: string (required)
                                     ##        : The API identifier.
  ##   
                                                                    ## integrationId: string (required)
                                                                    ##                
                                                                    ## : 
                                                                    ## The 
                                                                    ## integration ID.
  ##   
                                                                                      ## integrationResponseId: string (required)
                                                                                      ##                        
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## integration 
                                                                                      ## response 
                                                                                      ## ID.
  var path_402657189 = newJObject()
  add(path_402657189, "apiId", newJString(apiId))
  add(path_402657189, "integrationId", newJString(integrationId))
  add(path_402657189, "integrationResponseId", newJString(integrationResponseId))
  result = call_402657188.call(path_402657189, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_402657174(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_402657175, base: "/",
    makeUrl: url_DeleteIntegrationResponse_402657176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_402657208 = ref object of OpenApiRestCall_402656044
proc url_GetModel_402657210(protocol: Scheme; host: string; base: string;
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

proc validate_GetModel_402657209(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657211 = path.getOrDefault("apiId")
  valid_402657211 = validateParameter(valid_402657211, JString, required = true,
                                      default = nil)
  if valid_402657211 != nil:
    section.add "apiId", valid_402657211
  var valid_402657212 = path.getOrDefault("modelId")
  valid_402657212 = validateParameter(valid_402657212, JString, required = true,
                                      default = nil)
  if valid_402657212 != nil:
    section.add "modelId", valid_402657212
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657213 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Security-Token", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Signature")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Signature", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Algorithm", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Date")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Date", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Credential")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Credential", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657220: Call_GetModel_402657208; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Model.
                                                                                         ## 
  let valid = call_402657220.validator(path, query, header, formData, body, _)
  let scheme = call_402657220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657220.makeUrl(scheme.get, call_402657220.host, call_402657220.base,
                                   call_402657220.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657220, uri, valid, _)

proc call*(call_402657221: Call_GetModel_402657208; apiId: string;
           modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
                  ##        : The API identifier.
  ##   modelId: string (required)
                                                 ##          : The model ID.
  var path_402657222 = newJObject()
  add(path_402657222, "apiId", newJString(apiId))
  add(path_402657222, "modelId", newJString(modelId))
  result = call_402657221.call(path_402657222, nil, nil, nil, nil)

var getModel* = Call_GetModel_402657208(name: "getModel",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_GetModel_402657209,
                                        base: "/", makeUrl: url_GetModel_402657210,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_402657238 = ref object of OpenApiRestCall_402656044
proc url_UpdateModel_402657240(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_402657239(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657241 = path.getOrDefault("apiId")
  valid_402657241 = validateParameter(valid_402657241, JString, required = true,
                                      default = nil)
  if valid_402657241 != nil:
    section.add "apiId", valid_402657241
  var valid_402657242 = path.getOrDefault("modelId")
  valid_402657242 = validateParameter(valid_402657242, JString, required = true,
                                      default = nil)
  if valid_402657242 != nil:
    section.add "modelId", valid_402657242
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657243 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Security-Token", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Signature")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Signature", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Algorithm", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Date")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Date", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Credential")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Credential", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657249
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

proc call*(call_402657251: Call_UpdateModel_402657238; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Model.
                                                                                         ## 
  let valid = call_402657251.validator(path, query, header, formData, body, _)
  let scheme = call_402657251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657251.makeUrl(scheme.get, call_402657251.host, call_402657251.base,
                                   call_402657251.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657251, uri, valid, _)

proc call*(call_402657252: Call_UpdateModel_402657238; apiId: string;
           modelId: string; body: JsonNode): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
                     ##        : The API identifier.
  ##   modelId: string (required)
                                                    ##          : The model ID.
  ##   
                                                                               ## body: JObject (required)
  var path_402657253 = newJObject()
  var body_402657254 = newJObject()
  add(path_402657253, "apiId", newJString(apiId))
  add(path_402657253, "modelId", newJString(modelId))
  if body != nil:
    body_402657254 = body
  result = call_402657252.call(path_402657253, nil, nil, nil, body_402657254)

var updateModel* = Call_UpdateModel_402657238(name: "updateModel",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}", validator: validate_UpdateModel_402657239,
    base: "/", makeUrl: url_UpdateModel_402657240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_402657223 = ref object of OpenApiRestCall_402656044
proc url_DeleteModel_402657225(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_402657224(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657226 = path.getOrDefault("apiId")
  valid_402657226 = validateParameter(valid_402657226, JString, required = true,
                                      default = nil)
  if valid_402657226 != nil:
    section.add "apiId", valid_402657226
  var valid_402657227 = path.getOrDefault("modelId")
  valid_402657227 = validateParameter(valid_402657227, JString, required = true,
                                      default = nil)
  if valid_402657227 != nil:
    section.add "modelId", valid_402657227
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657228 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Security-Token", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Signature")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Signature", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Algorithm", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Date")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Date", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Credential")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Credential", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657235: Call_DeleteModel_402657223; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Model.
                                                                                         ## 
  let valid = call_402657235.validator(path, query, header, formData, body, _)
  let scheme = call_402657235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657235.makeUrl(scheme.get, call_402657235.host, call_402657235.base,
                                   call_402657235.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657235, uri, valid, _)

proc call*(call_402657236: Call_DeleteModel_402657223; apiId: string;
           modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
                     ##        : The API identifier.
  ##   modelId: string (required)
                                                    ##          : The model ID.
  var path_402657237 = newJObject()
  add(path_402657237, "apiId", newJString(apiId))
  add(path_402657237, "modelId", newJString(modelId))
  result = call_402657236.call(path_402657237, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_402657223(name: "deleteModel",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}", validator: validate_DeleteModel_402657224,
    base: "/", makeUrl: url_DeleteModel_402657225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_402657255 = ref object of OpenApiRestCall_402656044
proc url_GetRoute_402657257(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoute_402657256(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   apiId: JString (required)
                                                            ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657258 = path.getOrDefault("routeId")
  valid_402657258 = validateParameter(valid_402657258, JString, required = true,
                                      default = nil)
  if valid_402657258 != nil:
    section.add "routeId", valid_402657258
  var valid_402657259 = path.getOrDefault("apiId")
  valid_402657259 = validateParameter(valid_402657259, JString, required = true,
                                      default = nil)
  if valid_402657259 != nil:
    section.add "apiId", valid_402657259
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657260 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Security-Token", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-Signature")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Signature", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Algorithm", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Date")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Date", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Credential")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Credential", valid_402657265
  var valid_402657266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657266 = validateParameter(valid_402657266, JString,
                                      required = false, default = nil)
  if valid_402657266 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657267: Call_GetRoute_402657255; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Route.
                                                                                         ## 
  let valid = call_402657267.validator(path, query, header, formData, body, _)
  let scheme = call_402657267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657267.makeUrl(scheme.get, call_402657267.host, call_402657267.base,
                                   call_402657267.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657267, uri, valid, _)

proc call*(call_402657268: Call_GetRoute_402657255; routeId: string;
           apiId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   routeId: string (required)
                  ##          : The route ID.
  ##   apiId: string (required)
                                             ##        : The API identifier.
  var path_402657269 = newJObject()
  add(path_402657269, "routeId", newJString(routeId))
  add(path_402657269, "apiId", newJString(apiId))
  result = call_402657268.call(path_402657269, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_402657255(name: "getRoute",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_GetRoute_402657256,
                                        base: "/", makeUrl: url_GetRoute_402657257,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_402657285 = ref object of OpenApiRestCall_402656044
proc url_UpdateRoute_402657287(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_402657286(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   apiId: JString (required)
                                                            ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657288 = path.getOrDefault("routeId")
  valid_402657288 = validateParameter(valid_402657288, JString, required = true,
                                      default = nil)
  if valid_402657288 != nil:
    section.add "routeId", valid_402657288
  var valid_402657289 = path.getOrDefault("apiId")
  valid_402657289 = validateParameter(valid_402657289, JString, required = true,
                                      default = nil)
  if valid_402657289 != nil:
    section.add "apiId", valid_402657289
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657290 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657290 = validateParameter(valid_402657290, JString,
                                      required = false, default = nil)
  if valid_402657290 != nil:
    section.add "X-Amz-Security-Token", valid_402657290
  var valid_402657291 = header.getOrDefault("X-Amz-Signature")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Signature", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Algorithm", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-Date")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Date", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Credential")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Credential", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657296
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

proc call*(call_402657298: Call_UpdateRoute_402657285; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Route.
                                                                                         ## 
  let valid = call_402657298.validator(path, query, header, formData, body, _)
  let scheme = call_402657298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657298.makeUrl(scheme.get, call_402657298.host, call_402657298.base,
                                   call_402657298.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657298, uri, valid, _)

proc call*(call_402657299: Call_UpdateRoute_402657285; routeId: string;
           apiId: string; body: JsonNode): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   routeId: string (required)
                     ##          : The route ID.
  ##   apiId: string (required)
                                                ##        : The API identifier.
  ##   
                                                                               ## body: JObject (required)
  var path_402657300 = newJObject()
  var body_402657301 = newJObject()
  add(path_402657300, "routeId", newJString(routeId))
  add(path_402657300, "apiId", newJString(apiId))
  if body != nil:
    body_402657301 = body
  result = call_402657299.call(path_402657300, nil, nil, nil, body_402657301)

var updateRoute* = Call_UpdateRoute_402657285(name: "updateRoute",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}", validator: validate_UpdateRoute_402657286,
    base: "/", makeUrl: url_UpdateRoute_402657287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_402657270 = ref object of OpenApiRestCall_402656044
proc url_DeleteRoute_402657272(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_402657271(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Route.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   apiId: JString (required)
                                                            ##        : The API identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657273 = path.getOrDefault("routeId")
  valid_402657273 = validateParameter(valid_402657273, JString, required = true,
                                      default = nil)
  if valid_402657273 != nil:
    section.add "routeId", valid_402657273
  var valid_402657274 = path.getOrDefault("apiId")
  valid_402657274 = validateParameter(valid_402657274, JString, required = true,
                                      default = nil)
  if valid_402657274 != nil:
    section.add "apiId", valid_402657274
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657275 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "X-Amz-Security-Token", valid_402657275
  var valid_402657276 = header.getOrDefault("X-Amz-Signature")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Signature", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Algorithm", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-Date")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Date", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Credential")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Credential", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657282: Call_DeleteRoute_402657270; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Route.
                                                                                         ## 
  let valid = call_402657282.validator(path, query, header, formData, body, _)
  let scheme = call_402657282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657282.makeUrl(scheme.get, call_402657282.host, call_402657282.base,
                                   call_402657282.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657282, uri, valid, _)

proc call*(call_402657283: Call_DeleteRoute_402657270; routeId: string;
           apiId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   routeId: string (required)
                     ##          : The route ID.
  ##   apiId: string (required)
                                                ##        : The API identifier.
  var path_402657284 = newJObject()
  add(path_402657284, "routeId", newJString(routeId))
  add(path_402657284, "apiId", newJString(apiId))
  result = call_402657283.call(path_402657284, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_402657270(name: "deleteRoute",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}", validator: validate_DeleteRoute_402657271,
    base: "/", makeUrl: url_DeleteRoute_402657272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_402657302 = ref object of OpenApiRestCall_402656044
proc url_GetRouteResponse_402657304(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path,
         "`routeResponseId` is a required path parameter"
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

proc validate_GetRouteResponse_402657303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a RouteResponse.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   routeResponseId: JString (required)
                                                            ##                  : The route response ID.
  ##   
                                                                                                        ## apiId: JString (required)
                                                                                                        ##        
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## API 
                                                                                                        ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657305 = path.getOrDefault("routeId")
  valid_402657305 = validateParameter(valid_402657305, JString, required = true,
                                      default = nil)
  if valid_402657305 != nil:
    section.add "routeId", valid_402657305
  var valid_402657306 = path.getOrDefault("routeResponseId")
  valid_402657306 = validateParameter(valid_402657306, JString, required = true,
                                      default = nil)
  if valid_402657306 != nil:
    section.add "routeResponseId", valid_402657306
  var valid_402657307 = path.getOrDefault("apiId")
  valid_402657307 = validateParameter(valid_402657307, JString, required = true,
                                      default = nil)
  if valid_402657307 != nil:
    section.add "apiId", valid_402657307
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657308 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Security-Token", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-Signature")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-Signature", valid_402657309
  var valid_402657310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657310 = validateParameter(valid_402657310, JString,
                                      required = false, default = nil)
  if valid_402657310 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657310
  var valid_402657311 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "X-Amz-Algorithm", valid_402657311
  var valid_402657312 = header.getOrDefault("X-Amz-Date")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Date", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-Credential")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-Credential", valid_402657313
  var valid_402657314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657315: Call_GetRouteResponse_402657302;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a RouteResponse.
                                                                                         ## 
  let valid = call_402657315.validator(path, query, header, formData, body, _)
  let scheme = call_402657315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657315.makeUrl(scheme.get, call_402657315.host, call_402657315.base,
                                   call_402657315.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657315, uri, valid, _)

proc call*(call_402657316: Call_GetRouteResponse_402657302; routeId: string;
           routeResponseId: string; apiId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   routeId: string (required)
                          ##          : The route ID.
  ##   routeResponseId: string (required)
                                                     ##                  : The route response ID.
  ##   
                                                                                                 ## apiId: string (required)
                                                                                                 ##        
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## API 
                                                                                                 ## identifier.
  var path_402657317 = newJObject()
  add(path_402657317, "routeId", newJString(routeId))
  add(path_402657317, "routeResponseId", newJString(routeResponseId))
  add(path_402657317, "apiId", newJString(apiId))
  result = call_402657316.call(path_402657317, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_402657302(
    name: "getRouteResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_402657303, base: "/",
    makeUrl: url_GetRouteResponse_402657304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_402657334 = ref object of OpenApiRestCall_402656044
proc url_UpdateRouteResponse_402657336(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path,
         "`routeResponseId` is a required path parameter"
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

proc validate_UpdateRouteResponse_402657335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a RouteResponse.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   routeResponseId: JString (required)
                                                            ##                  : The route response ID.
  ##   
                                                                                                        ## apiId: JString (required)
                                                                                                        ##        
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## API 
                                                                                                        ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657337 = path.getOrDefault("routeId")
  valid_402657337 = validateParameter(valid_402657337, JString, required = true,
                                      default = nil)
  if valid_402657337 != nil:
    section.add "routeId", valid_402657337
  var valid_402657338 = path.getOrDefault("routeResponseId")
  valid_402657338 = validateParameter(valid_402657338, JString, required = true,
                                      default = nil)
  if valid_402657338 != nil:
    section.add "routeResponseId", valid_402657338
  var valid_402657339 = path.getOrDefault("apiId")
  valid_402657339 = validateParameter(valid_402657339, JString, required = true,
                                      default = nil)
  if valid_402657339 != nil:
    section.add "apiId", valid_402657339
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657340 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "X-Amz-Security-Token", valid_402657340
  var valid_402657341 = header.getOrDefault("X-Amz-Signature")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "X-Amz-Signature", valid_402657341
  var valid_402657342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657342 = validateParameter(valid_402657342, JString,
                                      required = false, default = nil)
  if valid_402657342 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657342
  var valid_402657343 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657343 = validateParameter(valid_402657343, JString,
                                      required = false, default = nil)
  if valid_402657343 != nil:
    section.add "X-Amz-Algorithm", valid_402657343
  var valid_402657344 = header.getOrDefault("X-Amz-Date")
  valid_402657344 = validateParameter(valid_402657344, JString,
                                      required = false, default = nil)
  if valid_402657344 != nil:
    section.add "X-Amz-Date", valid_402657344
  var valid_402657345 = header.getOrDefault("X-Amz-Credential")
  valid_402657345 = validateParameter(valid_402657345, JString,
                                      required = false, default = nil)
  if valid_402657345 != nil:
    section.add "X-Amz-Credential", valid_402657345
  var valid_402657346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657346 = validateParameter(valid_402657346, JString,
                                      required = false, default = nil)
  if valid_402657346 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657346
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

proc call*(call_402657348: Call_UpdateRouteResponse_402657334;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a RouteResponse.
                                                                                         ## 
  let valid = call_402657348.validator(path, query, header, formData, body, _)
  let scheme = call_402657348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657348.makeUrl(scheme.get, call_402657348.host, call_402657348.base,
                                   call_402657348.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657348, uri, valid, _)

proc call*(call_402657349: Call_UpdateRouteResponse_402657334; routeId: string;
           routeResponseId: string; apiId: string; body: JsonNode): Recallable =
  ## updateRouteResponse
  ## Updates a RouteResponse.
  ##   routeId: string (required)
                             ##          : The route ID.
  ##   routeResponseId: string (required)
                                                        ##                  : The route response ID.
  ##   
                                                                                                    ## apiId: string (required)
                                                                                                    ##        
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## API 
                                                                                                    ## identifier.
  ##   
                                                                                                                  ## body: JObject (required)
  var path_402657350 = newJObject()
  var body_402657351 = newJObject()
  add(path_402657350, "routeId", newJString(routeId))
  add(path_402657350, "routeResponseId", newJString(routeResponseId))
  add(path_402657350, "apiId", newJString(apiId))
  if body != nil:
    body_402657351 = body
  result = call_402657349.call(path_402657350, nil, nil, nil, body_402657351)

var updateRouteResponse* = Call_UpdateRouteResponse_402657334(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_402657335, base: "/",
    makeUrl: url_UpdateRouteResponse_402657336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_402657318 = ref object of OpenApiRestCall_402656044
proc url_DeleteRouteResponse_402657320(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path,
         "`routeResponseId` is a required path parameter"
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

proc validate_DeleteRouteResponse_402657319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a RouteResponse.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeId: JString (required)
                                 ##          : The route ID.
  ##   routeResponseId: JString (required)
                                                            ##                  : The route response ID.
  ##   
                                                                                                        ## apiId: JString (required)
                                                                                                        ##        
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## API 
                                                                                                        ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `routeId` field"
  var valid_402657321 = path.getOrDefault("routeId")
  valid_402657321 = validateParameter(valid_402657321, JString, required = true,
                                      default = nil)
  if valid_402657321 != nil:
    section.add "routeId", valid_402657321
  var valid_402657322 = path.getOrDefault("routeResponseId")
  valid_402657322 = validateParameter(valid_402657322, JString, required = true,
                                      default = nil)
  if valid_402657322 != nil:
    section.add "routeResponseId", valid_402657322
  var valid_402657323 = path.getOrDefault("apiId")
  valid_402657323 = validateParameter(valid_402657323, JString, required = true,
                                      default = nil)
  if valid_402657323 != nil:
    section.add "apiId", valid_402657323
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657324 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-Security-Token", valid_402657324
  var valid_402657325 = header.getOrDefault("X-Amz-Signature")
  valid_402657325 = validateParameter(valid_402657325, JString,
                                      required = false, default = nil)
  if valid_402657325 != nil:
    section.add "X-Amz-Signature", valid_402657325
  var valid_402657326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657326 = validateParameter(valid_402657326, JString,
                                      required = false, default = nil)
  if valid_402657326 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657326
  var valid_402657327 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657327 = validateParameter(valid_402657327, JString,
                                      required = false, default = nil)
  if valid_402657327 != nil:
    section.add "X-Amz-Algorithm", valid_402657327
  var valid_402657328 = header.getOrDefault("X-Amz-Date")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "X-Amz-Date", valid_402657328
  var valid_402657329 = header.getOrDefault("X-Amz-Credential")
  valid_402657329 = validateParameter(valid_402657329, JString,
                                      required = false, default = nil)
  if valid_402657329 != nil:
    section.add "X-Amz-Credential", valid_402657329
  var valid_402657330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657331: Call_DeleteRouteResponse_402657318;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a RouteResponse.
                                                                                         ## 
  let valid = call_402657331.validator(path, query, header, formData, body, _)
  let scheme = call_402657331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657331.makeUrl(scheme.get, call_402657331.host, call_402657331.base,
                                   call_402657331.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657331, uri, valid, _)

proc call*(call_402657332: Call_DeleteRouteResponse_402657318; routeId: string;
           routeResponseId: string; apiId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   routeId: string (required)
                             ##          : The route ID.
  ##   routeResponseId: string (required)
                                                        ##                  : The route response ID.
  ##   
                                                                                                    ## apiId: string (required)
                                                                                                    ##        
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## API 
                                                                                                    ## identifier.
  var path_402657333 = newJObject()
  add(path_402657333, "routeId", newJString(routeId))
  add(path_402657333, "routeResponseId", newJString(routeResponseId))
  add(path_402657333, "apiId", newJString(apiId))
  result = call_402657332.call(path_402657333, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_402657318(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_402657319, base: "/",
    makeUrl: url_DeleteRouteResponse_402657320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteSettings_402657352 = ref object of OpenApiRestCall_402656044
proc url_DeleteRouteSettings_402657354(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteRouteSettings_402657353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the RouteSettings for a stage.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
                                 ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                                  ## apiId: JString (required)
                                                                                                                                                                                  ##        
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## API 
                                                                                                                                                                                  ## identifier.
  ##   
                                                                                                                                                                                                ## routeKey: JString (required)
                                                                                                                                                                                                ##           
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## route 
                                                                                                                                                                                                ## key.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `stageName` field"
  var valid_402657355 = path.getOrDefault("stageName")
  valid_402657355 = validateParameter(valid_402657355, JString, required = true,
                                      default = nil)
  if valid_402657355 != nil:
    section.add "stageName", valid_402657355
  var valid_402657356 = path.getOrDefault("apiId")
  valid_402657356 = validateParameter(valid_402657356, JString, required = true,
                                      default = nil)
  if valid_402657356 != nil:
    section.add "apiId", valid_402657356
  var valid_402657357 = path.getOrDefault("routeKey")
  valid_402657357 = validateParameter(valid_402657357, JString, required = true,
                                      default = nil)
  if valid_402657357 != nil:
    section.add "routeKey", valid_402657357
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657358 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657358 = validateParameter(valid_402657358, JString,
                                      required = false, default = nil)
  if valid_402657358 != nil:
    section.add "X-Amz-Security-Token", valid_402657358
  var valid_402657359 = header.getOrDefault("X-Amz-Signature")
  valid_402657359 = validateParameter(valid_402657359, JString,
                                      required = false, default = nil)
  if valid_402657359 != nil:
    section.add "X-Amz-Signature", valid_402657359
  var valid_402657360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657360 = validateParameter(valid_402657360, JString,
                                      required = false, default = nil)
  if valid_402657360 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657360
  var valid_402657361 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657361 = validateParameter(valid_402657361, JString,
                                      required = false, default = nil)
  if valid_402657361 != nil:
    section.add "X-Amz-Algorithm", valid_402657361
  var valid_402657362 = header.getOrDefault("X-Amz-Date")
  valid_402657362 = validateParameter(valid_402657362, JString,
                                      required = false, default = nil)
  if valid_402657362 != nil:
    section.add "X-Amz-Date", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Credential")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Credential", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657365: Call_DeleteRouteSettings_402657352;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the RouteSettings for a stage.
                                                                                         ## 
  let valid = call_402657365.validator(path, query, header, formData, body, _)
  let scheme = call_402657365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657365.makeUrl(scheme.get, call_402657365.host, call_402657365.base,
                                   call_402657365.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657365, uri, valid, _)

proc call*(call_402657366: Call_DeleteRouteSettings_402657352;
           stageName: string; apiId: string; routeKey: string): Recallable =
  ## deleteRouteSettings
  ## Deletes the RouteSettings for a stage.
  ##   stageName: string (required)
                                           ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                                            ## apiId: string (required)
                                                                                                                                                                                            ##        
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## The 
                                                                                                                                                                                            ## API 
                                                                                                                                                                                            ## identifier.
  ##   
                                                                                                                                                                                                          ## routeKey: string (required)
                                                                                                                                                                                                          ##           
                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                          ## route 
                                                                                                                                                                                                          ## key.
  var path_402657367 = newJObject()
  add(path_402657367, "stageName", newJString(stageName))
  add(path_402657367, "apiId", newJString(apiId))
  add(path_402657367, "routeKey", newJString(routeKey))
  result = call_402657366.call(path_402657367, nil, nil, nil, nil)

var deleteRouteSettings* = Call_DeleteRouteSettings_402657352(
    name: "deleteRouteSettings", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}/routesettings/{routeKey}",
    validator: validate_DeleteRouteSettings_402657353, base: "/",
    makeUrl: url_DeleteRouteSettings_402657354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_402657368 = ref object of OpenApiRestCall_402656044
proc url_GetStage_402657370(protocol: Scheme; host: string; base: string;
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

proc validate_GetStage_402657369(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a Stage.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
                                 ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                                  ## apiId: JString (required)
                                                                                                                                                                                  ##        
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## API 
                                                                                                                                                                                  ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `stageName` field"
  var valid_402657371 = path.getOrDefault("stageName")
  valid_402657371 = validateParameter(valid_402657371, JString, required = true,
                                      default = nil)
  if valid_402657371 != nil:
    section.add "stageName", valid_402657371
  var valid_402657372 = path.getOrDefault("apiId")
  valid_402657372 = validateParameter(valid_402657372, JString, required = true,
                                      default = nil)
  if valid_402657372 != nil:
    section.add "apiId", valid_402657372
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657373 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-Security-Token", valid_402657373
  var valid_402657374 = header.getOrDefault("X-Amz-Signature")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-Signature", valid_402657374
  var valid_402657375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657375
  var valid_402657376 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657376 = validateParameter(valid_402657376, JString,
                                      required = false, default = nil)
  if valid_402657376 != nil:
    section.add "X-Amz-Algorithm", valid_402657376
  var valid_402657377 = header.getOrDefault("X-Amz-Date")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-Date", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Credential")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Credential", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657380: Call_GetStage_402657368; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a Stage.
                                                                                         ## 
  let valid = call_402657380.validator(path, query, header, formData, body, _)
  let scheme = call_402657380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657380.makeUrl(scheme.get, call_402657380.host, call_402657380.base,
                                   call_402657380.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657380, uri, valid, _)

proc call*(call_402657381: Call_GetStage_402657368; stageName: string;
           apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
                  ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                   ## apiId: string (required)
                                                                                                                                                                   ##        
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## The 
                                                                                                                                                                   ## API 
                                                                                                                                                                   ## identifier.
  var path_402657382 = newJObject()
  add(path_402657382, "stageName", newJString(stageName))
  add(path_402657382, "apiId", newJString(apiId))
  result = call_402657381.call(path_402657382, nil, nil, nil, nil)

var getStage* = Call_GetStage_402657368(name: "getStage",
                                        meth: HttpMethod.HttpGet,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_GetStage_402657369,
                                        base: "/", makeUrl: url_GetStage_402657370,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_402657398 = ref object of OpenApiRestCall_402656044
proc url_UpdateStage_402657400(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_402657399(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a Stage.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
                                 ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                                  ## apiId: JString (required)
                                                                                                                                                                                  ##        
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## API 
                                                                                                                                                                                  ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `stageName` field"
  var valid_402657401 = path.getOrDefault("stageName")
  valid_402657401 = validateParameter(valid_402657401, JString, required = true,
                                      default = nil)
  if valid_402657401 != nil:
    section.add "stageName", valid_402657401
  var valid_402657402 = path.getOrDefault("apiId")
  valid_402657402 = validateParameter(valid_402657402, JString, required = true,
                                      default = nil)
  if valid_402657402 != nil:
    section.add "apiId", valid_402657402
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657403 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Security-Token", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Signature")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Signature", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Algorithm", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-Date")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-Date", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-Credential")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Credential", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657409
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

proc call*(call_402657411: Call_UpdateStage_402657398; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a Stage.
                                                                                         ## 
  let valid = call_402657411.validator(path, query, header, formData, body, _)
  let scheme = call_402657411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657411.makeUrl(scheme.get, call_402657411.host, call_402657411.base,
                                   call_402657411.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657411, uri, valid, _)

proc call*(call_402657412: Call_UpdateStage_402657398; stageName: string;
           apiId: string; body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
                     ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                      ## apiId: string (required)
                                                                                                                                                                      ##        
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## The 
                                                                                                                                                                      ## API 
                                                                                                                                                                      ## identifier.
  ##   
                                                                                                                                                                                    ## body: JObject (required)
  var path_402657413 = newJObject()
  var body_402657414 = newJObject()
  add(path_402657413, "stageName", newJString(stageName))
  add(path_402657413, "apiId", newJString(apiId))
  if body != nil:
    body_402657414 = body
  result = call_402657412.call(path_402657413, nil, nil, nil, body_402657414)

var updateStage* = Call_UpdateStage_402657398(name: "updateStage",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}",
    validator: validate_UpdateStage_402657399, base: "/",
    makeUrl: url_UpdateStage_402657400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_402657383 = ref object of OpenApiRestCall_402656044
proc url_DeleteStage_402657385(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_402657384(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Stage.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
                                 ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                                  ## apiId: JString (required)
                                                                                                                                                                                  ##        
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## API 
                                                                                                                                                                                  ## identifier.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `stageName` field"
  var valid_402657386 = path.getOrDefault("stageName")
  valid_402657386 = validateParameter(valid_402657386, JString, required = true,
                                      default = nil)
  if valid_402657386 != nil:
    section.add "stageName", valid_402657386
  var valid_402657387 = path.getOrDefault("apiId")
  valid_402657387 = validateParameter(valid_402657387, JString, required = true,
                                      default = nil)
  if valid_402657387 != nil:
    section.add "apiId", valid_402657387
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657388 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Security-Token", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-Signature")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-Signature", valid_402657389
  var valid_402657390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657390
  var valid_402657391 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657391 = validateParameter(valid_402657391, JString,
                                      required = false, default = nil)
  if valid_402657391 != nil:
    section.add "X-Amz-Algorithm", valid_402657391
  var valid_402657392 = header.getOrDefault("X-Amz-Date")
  valid_402657392 = validateParameter(valid_402657392, JString,
                                      required = false, default = nil)
  if valid_402657392 != nil:
    section.add "X-Amz-Date", valid_402657392
  var valid_402657393 = header.getOrDefault("X-Amz-Credential")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "X-Amz-Credential", valid_402657393
  var valid_402657394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657394 = validateParameter(valid_402657394, JString,
                                      required = false, default = nil)
  if valid_402657394 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657395: Call_DeleteStage_402657383; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Stage.
                                                                                         ## 
  let valid = call_402657395.validator(path, query, header, formData, body, _)
  let scheme = call_402657395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657395.makeUrl(scheme.get, call_402657395.host, call_402657395.base,
                                   call_402657395.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657395, uri, valid, _)

proc call*(call_402657396: Call_DeleteStage_402657383; stageName: string;
           apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
                     ##            : The stage name. Stage names can only contain alphanumeric characters, hyphens, and underscores. Maximum length is 128 characters.
  ##   
                                                                                                                                                                      ## apiId: string (required)
                                                                                                                                                                      ##        
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## The 
                                                                                                                                                                      ## API 
                                                                                                                                                                      ## identifier.
  var path_402657397 = newJObject()
  add(path_402657397, "stageName", newJString(stageName))
  add(path_402657397, "apiId", newJString(apiId))
  result = call_402657396.call(path_402657397, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_402657383(name: "deleteStage",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/stages/{stageName}",
    validator: validate_DeleteStage_402657384, base: "/",
    makeUrl: url_DeleteStage_402657385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_402657415 = ref object of OpenApiRestCall_402656044
proc url_GetModelTemplate_402657417(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_GetModelTemplate_402657416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657418 = path.getOrDefault("apiId")
  valid_402657418 = validateParameter(valid_402657418, JString, required = true,
                                      default = nil)
  if valid_402657418 != nil:
    section.add "apiId", valid_402657418
  var valid_402657419 = path.getOrDefault("modelId")
  valid_402657419 = validateParameter(valid_402657419, JString, required = true,
                                      default = nil)
  if valid_402657419 != nil:
    section.add "modelId", valid_402657419
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657420 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Security-Token", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Signature")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Signature", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Algorithm", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-Date")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Date", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-Credential")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-Credential", valid_402657425
  var valid_402657426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657427: Call_GetModelTemplate_402657415;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a model template.
                                                                                         ## 
  let valid = call_402657427.validator(path, query, header, formData, body, _)
  let scheme = call_402657427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657427.makeUrl(scheme.get, call_402657427.host, call_402657427.base,
                                   call_402657427.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657427, uri, valid, _)

proc call*(call_402657428: Call_GetModelTemplate_402657415; apiId: string;
           modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
                           ##        : The API identifier.
  ##   modelId: string (required)
                                                          ##          : The model ID.
  var path_402657429 = newJObject()
  add(path_402657429, "apiId", newJString(apiId))
  add(path_402657429, "modelId", newJString(modelId))
  result = call_402657428.call(path_402657429, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_402657415(
    name: "getModelTemplate", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_402657416, base: "/",
    makeUrl: url_GetModelTemplate_402657417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657444 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657446(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402657445(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657447 = path.getOrDefault("resource-arn")
  valid_402657447 = validateParameter(valid_402657447, JString, required = true,
                                      default = nil)
  if valid_402657447 != nil:
    section.add "resource-arn", valid_402657447
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657448 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Security-Token", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Signature")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Signature", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Algorithm", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Date")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Date", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Credential")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Credential", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657454
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

proc call*(call_402657456: Call_TagResource_402657444; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Tag resource to represent a tag.
                                                                                         ## 
  let valid = call_402657456.validator(path, query, header, formData, body, _)
  let scheme = call_402657456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657456.makeUrl(scheme.get, call_402657456.host, call_402657456.base,
                                   call_402657456.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657456, uri, valid, _)

proc call*(call_402657457: Call_TagResource_402657444; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Creates a new Tag resource to represent a tag.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The resource ARN for the tag.
  var path_402657458 = newJObject()
  var body_402657459 = newJObject()
  if body != nil:
    body_402657459 = body
  add(path_402657458, "resource-arn", newJString(resourceArn))
  result = call_402657457.call(path_402657458, nil, nil, nil, body_402657459)

var tagResource* = Call_TagResource_402657444(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}", validator: validate_TagResource_402657445,
    base: "/", makeUrl: url_TagResource_402657446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_402657430 = ref object of OpenApiRestCall_402656044
proc url_GetTags_402657432(protocol: Scheme; host: string; base: string;
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

proc validate_GetTags_402657431(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657433 = path.getOrDefault("resource-arn")
  valid_402657433 = validateParameter(valid_402657433, JString, required = true,
                                      default = nil)
  if valid_402657433 != nil:
    section.add "resource-arn", valid_402657433
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657434 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Security-Token", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-Signature")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-Signature", valid_402657435
  var valid_402657436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657436
  var valid_402657437 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Algorithm", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Date")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Date", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Credential")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Credential", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657441: Call_GetTags_402657430; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a collection of Tag resources.
                                                                                         ## 
  let valid = call_402657441.validator(path, query, header, formData, body, _)
  let scheme = call_402657441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657441.makeUrl(scheme.get, call_402657441.host, call_402657441.base,
                                   call_402657441.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657441, uri, valid, _)

proc call*(call_402657442: Call_GetTags_402657430; resourceArn: string): Recallable =
  ## getTags
  ## Gets a collection of Tag resources.
  ##   resourceArn: string (required)
                                        ##              : The resource ARN for the tag.
  var path_402657443 = newJObject()
  add(path_402657443, "resource-arn", newJString(resourceArn))
  result = call_402657442.call(path_402657443, nil, nil, nil, nil)

var getTags* = Call_GetTags_402657430(name: "getTags", meth: HttpMethod.HttpGet,
                                      host: "apigateway.amazonaws.com",
                                      route: "/v2/tags/{resource-arn}",
                                      validator: validate_GetTags_402657431,
                                      base: "/", makeUrl: url_GetTags_402657432,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657460 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657462(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402657461(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657463 = path.getOrDefault("resource-arn")
  valid_402657463 = validateParameter(valid_402657463, JString, required = true,
                                      default = nil)
  if valid_402657463 != nil:
    section.add "resource-arn", valid_402657463
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : 
                                  ##             <p>The Tag keys to delete.</p>
                                  ##          
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657464 = query.getOrDefault("tagKeys")
  valid_402657464 = validateParameter(valid_402657464, JArray, required = true,
                                      default = nil)
  if valid_402657464 != nil:
    section.add "tagKeys", valid_402657464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657465 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Security-Token", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Signature")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Signature", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Algorithm", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-Date")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-Date", valid_402657469
  var valid_402657470 = header.getOrDefault("X-Amz-Credential")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "X-Amz-Credential", valid_402657470
  var valid_402657471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657472: Call_UntagResource_402657460; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Tag.
                                                                                         ## 
  let valid = call_402657472.validator(path, query, header, formData, body, _)
  let scheme = call_402657472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657472.makeUrl(scheme.get, call_402657472.host, call_402657472.base,
                                   call_402657472.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657472, uri, valid, _)

proc call*(call_402657473: Call_UntagResource_402657460; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Deletes a Tag.
  ##   tagKeys: JArray (required)
                   ##          : 
                   ##             <p>The Tag keys to delete.</p>
                   ##          
  ##   resourceArn: string (required)
                               ##              : The resource ARN for the tag.
  var path_402657474 = newJObject()
  var query_402657475 = newJObject()
  if tagKeys != nil:
    query_402657475.add "tagKeys", tagKeys
  add(path_402657474, "resource-arn", newJString(resourceArn))
  result = call_402657473.call(path_402657474, query_402657475, nil, nil, nil)

var untagResource* = Call_UntagResource_402657460(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402657461,
    base: "/", makeUrl: url_UntagResource_402657462,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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