
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonMQ
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon MQ is a managed message broker service for Apache ActiveMQ that makes it easy to set up and operate message brokers in the cloud. A message broker allows software applications and components to communicate using various programming languages, operating systems, and formal messaging protocols.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mq/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mq.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mq.ap-southeast-1.amazonaws.com",
                               "us-west-2": "mq.us-west-2.amazonaws.com",
                               "eu-west-2": "mq.eu-west-2.amazonaws.com", "ap-northeast-3": "mq.ap-northeast-3.amazonaws.com",
                               "eu-central-1": "mq.eu-central-1.amazonaws.com",
                               "us-east-2": "mq.us-east-2.amazonaws.com",
                               "us-east-1": "mq.us-east-1.amazonaws.com", "cn-northwest-1": "mq.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "mq.ap-south-1.amazonaws.com",
                               "eu-north-1": "mq.eu-north-1.amazonaws.com", "ap-northeast-2": "mq.ap-northeast-2.amazonaws.com",
                               "us-west-1": "mq.us-west-1.amazonaws.com", "us-gov-east-1": "mq.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "mq.eu-west-3.amazonaws.com",
                               "cn-north-1": "mq.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "mq.sa-east-1.amazonaws.com",
                               "eu-west-1": "mq.eu-west-1.amazonaws.com", "us-gov-west-1": "mq.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mq.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "mq.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mq.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mq.ap-southeast-1.amazonaws.com",
      "us-west-2": "mq.us-west-2.amazonaws.com",
      "eu-west-2": "mq.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mq.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mq.eu-central-1.amazonaws.com",
      "us-east-2": "mq.us-east-2.amazonaws.com",
      "us-east-1": "mq.us-east-1.amazonaws.com",
      "cn-northwest-1": "mq.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mq.ap-south-1.amazonaws.com",
      "eu-north-1": "mq.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mq.ap-northeast-2.amazonaws.com",
      "us-west-1": "mq.us-west-1.amazonaws.com",
      "us-gov-east-1": "mq.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mq.eu-west-3.amazonaws.com",
      "cn-north-1": "mq.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mq.sa-east-1.amazonaws.com",
      "eu-west-1": "mq.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mq.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mq.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mq.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mq"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateBroker_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateBroker_402656479(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBroker_402656478(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a broker. Note: This API is asynchronous.
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
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
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

proc call*(call_402656488: Call_CreateBroker_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a broker. Note: This API is asynchronous.
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateBroker_402656477; body: JsonNode): Recallable =
  ## createBroker
  ## Creates a broker. Note: This API is asynchronous.
  ##   body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createBroker* = Call_CreateBroker_402656477(name: "createBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_CreateBroker_402656478, base: "/",
    makeUrl: url_CreateBroker_402656479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBrokers_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListBrokers_402656296(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBrokers_402656295(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all brokers.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                 ##            
                                                                                                                                                                                 ## : 
                                                                                                                                                                                 ## The 
                                                                                                                                                                                 ## token 
                                                                                                                                                                                 ## that 
                                                                                                                                                                                 ## specifies 
                                                                                                                                                                                 ## the 
                                                                                                                                                                                 ## next 
                                                                                                                                                                                 ## page 
                                                                                                                                                                                 ## of 
                                                                                                                                                                                 ## results 
                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                 ## MQ 
                                                                                                                                                                                 ## should 
                                                                                                                                                                                 ## return. 
                                                                                                                                                                                 ## To 
                                                                                                                                                                                 ## request 
                                                                                                                                                                                 ## the 
                                                                                                                                                                                 ## first 
                                                                                                                                                                                 ## page, 
                                                                                                                                                                                 ## leave 
                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                 ## empty.
  section = newJObject()
  var valid_402656375 = query.getOrDefault("maxResults")
  valid_402656375 = validateParameter(valid_402656375, JInt, required = false,
                                      default = nil)
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

proc call*(call_402656397: Call_ListBrokers_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all brokers.
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

proc call*(call_402656446: Call_ListBrokers_402656294; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listBrokers
  ## Returns a list of all brokers.
  ##   maxResults: int
                                   ##             : The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                  ## nextToken: string
                                                                                                                                                                                  ##            
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## The 
                                                                                                                                                                                  ## token 
                                                                                                                                                                                  ## that 
                                                                                                                                                                                  ## specifies 
                                                                                                                                                                                  ## the 
                                                                                                                                                                                  ## next 
                                                                                                                                                                                  ## page 
                                                                                                                                                                                  ## of 
                                                                                                                                                                                  ## results 
                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                  ## MQ 
                                                                                                                                                                                  ## should 
                                                                                                                                                                                  ## return. 
                                                                                                                                                                                  ## To 
                                                                                                                                                                                  ## request 
                                                                                                                                                                                  ## the 
                                                                                                                                                                                  ## first 
                                                                                                                                                                                  ## page, 
                                                                                                                                                                                  ## leave 
                                                                                                                                                                                  ## nextToken 
                                                                                                                                                                                  ## empty.
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJInt(maxResults))
  add(query_402656447, "nextToken", newJString(nextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listBrokers* = Call_ListBrokers_402656294(name: "listBrokers",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com", route: "/v1/brokers",
    validator: validate_ListBrokers_402656295, base: "/",
    makeUrl: url_ListBrokers_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_402656506 = ref object of OpenApiRestCall_402656044
proc url_CreateConfiguration_402656508(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_402656507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
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
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
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

proc call*(call_402656517: Call_CreateConfiguration_402656506;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_CreateConfiguration_402656506; body: JsonNode): Recallable =
  ## createConfiguration
  ## Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
  ##   
                                                                                                                                              ## body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var createConfiguration* = Call_CreateConfiguration_402656506(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_402656507, base: "/",
    makeUrl: url_CreateConfiguration_402656508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurations_402656493(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_402656492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all configurations.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                        ## nextToken: JString
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## The 
                                                                                                                                                                                        ## token 
                                                                                                                                                                                        ## that 
                                                                                                                                                                                        ## specifies 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## page 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## results 
                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                        ## MQ 
                                                                                                                                                                                        ## should 
                                                                                                                                                                                        ## return. 
                                                                                                                                                                                        ## To 
                                                                                                                                                                                        ## request 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## first 
                                                                                                                                                                                        ## page, 
                                                                                                                                                                                        ## leave 
                                                                                                                                                                                        ## nextToken 
                                                                                                                                                                                        ## empty.
  section = newJObject()
  var valid_402656494 = query.getOrDefault("maxResults")
  valid_402656494 = validateParameter(valid_402656494, JInt, required = false,
                                      default = nil)
  if valid_402656494 != nil:
    section.add "maxResults", valid_402656494
  var valid_402656495 = query.getOrDefault("nextToken")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "nextToken", valid_402656495
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
  var valid_402656496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Security-Token", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Signature")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Signature", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Algorithm", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Date")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Date", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Credential")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Credential", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656503: Call_ListConfigurations_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all configurations.
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_ListConfigurations_402656491;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurations
  ## Returns a list of all configurations.
  ##   maxResults: int
                                          ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                                ## nextToken: string
                                                                                                                                                                                                ##            
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## token 
                                                                                                                                                                                                ## that 
                                                                                                                                                                                                ## specifies 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## next 
                                                                                                                                                                                                ## page 
                                                                                                                                                                                                ## of 
                                                                                                                                                                                                ## results 
                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                ## MQ 
                                                                                                                                                                                                ## should 
                                                                                                                                                                                                ## return. 
                                                                                                                                                                                                ## To 
                                                                                                                                                                                                ## request 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## first 
                                                                                                                                                                                                ## page, 
                                                                                                                                                                                                ## leave 
                                                                                                                                                                                                ## nextToken 
                                                                                                                                                                                                ## empty.
  var query_402656505 = newJObject()
  add(query_402656505, "maxResults", newJInt(maxResults))
  add(query_402656505, "nextToken", newJString(nextToken))
  result = call_402656504.call(nil, query_402656505, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_402656491(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_402656492, base: "/",
    makeUrl: url_ListConfigurations_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_402656545 = ref object of OpenApiRestCall_402656044
proc url_CreateTags_402656547(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_402656546(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add a tag to a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656548 = path.getOrDefault("resource-arn")
  valid_402656548 = validateParameter(valid_402656548, JString, required = true,
                                      default = nil)
  if valid_402656548 != nil:
    section.add "resource-arn", valid_402656548
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
  var valid_402656549 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Security-Token", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Signature")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Signature", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Algorithm", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Date")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Date", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Credential")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Credential", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656555
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

proc call*(call_402656557: Call_CreateTags_402656545; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a tag to a resource.
                                                                                         ## 
  let valid = call_402656557.validator(path, query, header, formData, body, _)
  let scheme = call_402656557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656557.makeUrl(scheme.get, call_402656557.host, call_402656557.base,
                                   call_402656557.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656557, uri, valid, _)

proc call*(call_402656558: Call_CreateTags_402656545; body: JsonNode;
           resourceArn: string): Recallable =
  ## createTags
  ## Add a tag to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_402656559 = newJObject()
  var body_402656560 = newJObject()
  if body != nil:
    body_402656560 = body
  add(path_402656559, "resource-arn", newJString(resourceArn))
  result = call_402656558.call(path_402656559, nil, nil, nil, body_402656560)

var createTags* = Call_CreateTags_402656545(name: "createTags",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/tags/{resource-arn}", validator: validate_CreateTags_402656546,
    base: "/", makeUrl: url_CreateTags_402656547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_402656520 = ref object of OpenApiRestCall_402656044
proc url_ListTags_402656522(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_402656521(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists tags for a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656534 = path.getOrDefault("resource-arn")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "resource-arn", valid_402656534
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
  var valid_402656535 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Security-Token", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Signature")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Signature", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Algorithm", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Date")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Date", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Credential")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Credential", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656542: Call_ListTags_402656520; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists tags for a resource.
                                                                                         ## 
  let valid = call_402656542.validator(path, query, header, formData, body, _)
  let scheme = call_402656542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656542.makeUrl(scheme.get, call_402656542.host, call_402656542.base,
                                   call_402656542.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656542, uri, valid, _)

proc call*(call_402656543: Call_ListTags_402656520; resourceArn: string): Recallable =
  ## listTags
  ## Lists tags for a resource.
  ##   resourceArn: string (required)
                               ##              : The Amazon Resource Name (ARN) of the resource tag.
  var path_402656544 = newJObject()
  add(path_402656544, "resource-arn", newJString(resourceArn))
  result = call_402656543.call(path_402656544, nil, nil, nil, nil)

var listTags* = Call_ListTags_402656520(name: "listTags",
                                        meth: HttpMethod.HttpGet,
                                        host: "mq.amazonaws.com",
                                        route: "/v1/tags/{resource-arn}",
                                        validator: validate_ListTags_402656521,
                                        base: "/", makeUrl: url_ListTags_402656522,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_402656576 = ref object of OpenApiRestCall_402656044
proc url_UpdateUser_402656578(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/users/"),
                 (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_402656577(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the information for an ActiveMQ user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   username: JString (required)
                                 ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                               ## broker-id: JString (required)
                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                               ## unique 
                                                                                                                                                                                                                                               ## ID 
                                                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                                                               ## Amazon 
                                                                                                                                                                                                                                               ## MQ 
                                                                                                                                                                                                                                               ## generates 
                                                                                                                                                                                                                                               ## for 
                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                               ## broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `username` field"
  var valid_402656579 = path.getOrDefault("username")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "username", valid_402656579
  var valid_402656580 = path.getOrDefault("broker-id")
  valid_402656580 = validateParameter(valid_402656580, JString, required = true,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "broker-id", valid_402656580
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
  var valid_402656581 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Security-Token", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Signature")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Signature", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Algorithm", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Date")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Date", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Credential")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Credential", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656587
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

proc call*(call_402656589: Call_UpdateUser_402656576; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the information for an ActiveMQ user.
                                                                                         ## 
  let valid = call_402656589.validator(path, query, header, formData, body, _)
  let scheme = call_402656589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656589.makeUrl(scheme.get, call_402656589.host, call_402656589.base,
                                   call_402656589.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656589, uri, valid, _)

proc call*(call_402656590: Call_UpdateUser_402656576; username: string;
           brokerId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the information for an ActiveMQ user.
  ##   username: string (required)
                                                  ##           : Required. The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                                                ## brokerId: string (required)
                                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                ## unique 
                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                ## MQ 
                                                                                                                                                                                                                                                                ## generates 
                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## broker.
  ##   
                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var path_402656591 = newJObject()
  var body_402656592 = newJObject()
  add(path_402656591, "username", newJString(username))
  add(path_402656591, "broker-id", newJString(brokerId))
  if body != nil:
    body_402656592 = body
  result = call_402656590.call(path_402656591, nil, nil, nil, body_402656592)

var updateUser* = Call_UpdateUser_402656576(name: "updateUser",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_UpdateUser_402656577, base: "/",
    makeUrl: url_UpdateUser_402656578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_402656593 = ref object of OpenApiRestCall_402656044
proc url_CreateUser_402656595(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/users/"),
                 (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_402656594(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an ActiveMQ user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   username: JString (required)
                                 ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                     ## broker-id: JString (required)
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                     ## MQ 
                                                                                                                                                                                                                                     ## generates 
                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `username` field"
  var valid_402656596 = path.getOrDefault("username")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = nil)
  if valid_402656596 != nil:
    section.add "username", valid_402656596
  var valid_402656597 = path.getOrDefault("broker-id")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true,
                                      default = nil)
  if valid_402656597 != nil:
    section.add "broker-id", valid_402656597
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
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_CreateUser_402656593; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an ActiveMQ user.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateUser_402656593; username: string;
           brokerId: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates an ActiveMQ user.
  ##   username: string (required)
                              ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                  ## brokerId: string (required)
                                                                                                                                                                                                                                  ##           
                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                  ## unique 
                                                                                                                                                                                                                                  ## ID 
                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                  ## MQ 
                                                                                                                                                                                                                                  ## generates 
                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                  ## broker.
  ##   
                                                                                                                                                                                                                                            ## body: JObject (required)
  var path_402656608 = newJObject()
  var body_402656609 = newJObject()
  add(path_402656608, "username", newJString(username))
  add(path_402656608, "broker-id", newJString(brokerId))
  if body != nil:
    body_402656609 = body
  result = call_402656607.call(path_402656608, nil, nil, nil, body_402656609)

var createUser* = Call_CreateUser_402656593(name: "createUser",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_CreateUser_402656594, base: "/",
    makeUrl: url_CreateUser_402656595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_402656561 = ref object of OpenApiRestCall_402656044
proc url_DescribeUser_402656563(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/users/"),
                 (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_402656562(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about an ActiveMQ user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   username: JString (required)
                                 ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                     ## broker-id: JString (required)
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                     ## MQ 
                                                                                                                                                                                                                                     ## generates 
                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `username` field"
  var valid_402656564 = path.getOrDefault("username")
  valid_402656564 = validateParameter(valid_402656564, JString, required = true,
                                      default = nil)
  if valid_402656564 != nil:
    section.add "username", valid_402656564
  var valid_402656565 = path.getOrDefault("broker-id")
  valid_402656565 = validateParameter(valid_402656565, JString, required = true,
                                      default = nil)
  if valid_402656565 != nil:
    section.add "broker-id", valid_402656565
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
  var valid_402656566 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Security-Token", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Signature")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Signature", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Algorithm", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Date")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Date", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Credential")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Credential", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656573: Call_DescribeUser_402656561; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about an ActiveMQ user.
                                                                                         ## 
  let valid = call_402656573.validator(path, query, header, formData, body, _)
  let scheme = call_402656573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656573.makeUrl(scheme.get, call_402656573.host, call_402656573.base,
                                   call_402656573.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656573, uri, valid, _)

proc call*(call_402656574: Call_DescribeUser_402656561; username: string;
           brokerId: string): Recallable =
  ## describeUser
  ## Returns information about an ActiveMQ user.
  ##   username: string (required)
                                                ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                                    ## brokerId: string (required)
                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                                    ## MQ 
                                                                                                                                                                                                                                                    ## generates 
                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                    ## broker.
  var path_402656575 = newJObject()
  add(path_402656575, "username", newJString(username))
  add(path_402656575, "broker-id", newJString(brokerId))
  result = call_402656574.call(path_402656575, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_402656561(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DescribeUser_402656562, base: "/",
    makeUrl: url_DescribeUser_402656563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402656610 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402656612(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  assert "username" in path, "`username` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/users/"),
                 (kind: VariableSegment, value: "username")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_402656611(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an ActiveMQ user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   username: JString (required)
                                 ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                     ## broker-id: JString (required)
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                     ## MQ 
                                                                                                                                                                                                                                     ## generates 
                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `username` field"
  var valid_402656613 = path.getOrDefault("username")
  valid_402656613 = validateParameter(valid_402656613, JString, required = true,
                                      default = nil)
  if valid_402656613 != nil:
    section.add "username", valid_402656613
  var valid_402656614 = path.getOrDefault("broker-id")
  valid_402656614 = validateParameter(valid_402656614, JString, required = true,
                                      default = nil)
  if valid_402656614 != nil:
    section.add "broker-id", valid_402656614
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
  var valid_402656615 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Security-Token", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Signature")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Signature", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Algorithm", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Date")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Date", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Credential")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Credential", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656622: Call_DeleteUser_402656610; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an ActiveMQ user.
                                                                                         ## 
  let valid = call_402656622.validator(path, query, header, formData, body, _)
  let scheme = call_402656622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656622.makeUrl(scheme.get, call_402656622.host, call_402656622.base,
                                   call_402656622.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656622, uri, valid, _)

proc call*(call_402656623: Call_DeleteUser_402656610; username: string;
           brokerId: string): Recallable =
  ## deleteUser
  ## Deletes an ActiveMQ user.
  ##   username: string (required)
                              ##           : The username of the ActiveMQ user. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  ##   
                                                                                                                                                                                                                                  ## brokerId: string (required)
                                                                                                                                                                                                                                  ##           
                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                  ## unique 
                                                                                                                                                                                                                                  ## ID 
                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                  ## MQ 
                                                                                                                                                                                                                                  ## generates 
                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                  ## broker.
  var path_402656624 = newJObject()
  add(path_402656624, "username", newJString(username))
  add(path_402656624, "broker-id", newJString(brokerId))
  result = call_402656623.call(path_402656624, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_402656610(name: "deleteUser",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users/{username}",
    validator: validate_DeleteUser_402656611, base: "/",
    makeUrl: url_DeleteUser_402656612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBroker_402656639 = ref object of OpenApiRestCall_402656044
proc url_UpdateBroker_402656641(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBroker_402656640(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a pending configuration change to a broker.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
                                 ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `broker-id` field"
  var valid_402656642 = path.getOrDefault("broker-id")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true,
                                      default = nil)
  if valid_402656642 != nil:
    section.add "broker-id", valid_402656642
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
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_UpdateBroker_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a pending configuration change to a broker.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_UpdateBroker_402656639; brokerId: string;
           body: JsonNode): Recallable =
  ## updateBroker
  ## Adds a pending configuration change to a broker.
  ##   brokerId: string (required)
                                                     ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  ##   
                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var path_402656653 = newJObject()
  var body_402656654 = newJObject()
  add(path_402656653, "broker-id", newJString(brokerId))
  if body != nil:
    body_402656654 = body
  result = call_402656652.call(path_402656653, nil, nil, nil, body_402656654)

var updateBroker* = Call_UpdateBroker_402656639(name: "updateBroker",
    meth: HttpMethod.HttpPut, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_UpdateBroker_402656640,
    base: "/", makeUrl: url_UpdateBroker_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBroker_402656625 = ref object of OpenApiRestCall_402656044
proc url_DescribeBroker_402656627(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBroker_402656626(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the specified broker.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
                                 ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `broker-id` field"
  var valid_402656628 = path.getOrDefault("broker-id")
  valid_402656628 = validateParameter(valid_402656628, JString, required = true,
                                      default = nil)
  if valid_402656628 != nil:
    section.add "broker-id", valid_402656628
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
  var valid_402656629 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Security-Token", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Signature")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Signature", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Algorithm", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Date")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Date", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Credential")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Credential", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_DescribeBroker_402656625; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified broker.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DescribeBroker_402656625; brokerId: string): Recallable =
  ## describeBroker
  ## Returns information about the specified broker.
  ##   brokerId: string (required)
                                                    ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_402656638 = newJObject()
  add(path_402656638, "broker-id", newJString(brokerId))
  result = call_402656637.call(path_402656638, nil, nil, nil, nil)

var describeBroker* = Call_DescribeBroker_402656625(name: "describeBroker",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DescribeBroker_402656626,
    base: "/", makeUrl: url_DescribeBroker_402656627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBroker_402656655 = ref object of OpenApiRestCall_402656044
proc url_DeleteBroker_402656657(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBroker_402656656(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a broker. Note: This API is asynchronous.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
                                 ##            : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `broker-id` field"
  var valid_402656658 = path.getOrDefault("broker-id")
  valid_402656658 = validateParameter(valid_402656658, JString, required = true,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "broker-id", valid_402656658
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
  var valid_402656659 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Security-Token", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Signature")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Signature", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Algorithm", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Date")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Date", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Credential")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Credential", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_DeleteBroker_402656655; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a broker. Note: This API is asynchronous.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DeleteBroker_402656655; brokerId: string): Recallable =
  ## deleteBroker
  ## Deletes a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
                                                      ##           : The name of the broker. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain whitespaces, brackets, wildcard characters, or special characters.
  var path_402656668 = newJObject()
  add(path_402656668, "broker-id", newJString(brokerId))
  result = call_402656667.call(path_402656668, nil, nil, nil, nil)

var deleteBroker* = Call_DeleteBroker_402656655(name: "deleteBroker",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}", validator: validate_DeleteBroker_402656656,
    base: "/", makeUrl: url_DeleteBroker_402656657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_402656669 = ref object of OpenApiRestCall_402656044
proc url_DeleteTags_402656671(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
                 (kind: VariableSegment, value: "resource-arn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_402656670(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes a tag from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : The Amazon Resource Name (ARN) of the resource tag.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656672 = path.getOrDefault("resource-arn")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "resource-arn", valid_402656672
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656673 = query.getOrDefault("tagKeys")
  valid_402656673 = validateParameter(valid_402656673, JArray, required = true,
                                      default = nil)
  if valid_402656673 != nil:
    section.add "tagKeys", valid_402656673
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
  var valid_402656674 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Security-Token", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Signature")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Signature", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Algorithm", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Date")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Date", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Credential")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Credential", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_DeleteTags_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from a resource.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DeleteTags_402656669; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## deleteTags
  ## Removes a tag from a resource.
  ##   tagKeys: JArray (required)
                                   ##          : An array of tag keys to delete
  ##   
                                                                               ## resourceArn: string (required)
                                                                               ##              
                                                                               ## : 
                                                                               ## The 
                                                                               ## Amazon 
                                                                               ## Resource 
                                                                               ## Name 
                                                                               ## (ARN) 
                                                                               ## of 
                                                                               ## the 
                                                                               ## resource 
                                                                               ## tag.
  var path_402656683 = newJObject()
  var query_402656684 = newJObject()
  if tagKeys != nil:
    query_402656684.add "tagKeys", tagKeys
  add(path_402656683, "resource-arn", newJString(resourceArn))
  result = call_402656682.call(path_402656683, query_402656684, nil, nil, nil)

var deleteTags* = Call_DeleteTags_402656669(name: "deleteTags",
    meth: HttpMethod.HttpDelete, host: "mq.amazonaws.com",
    route: "/v1/tags/{resource-arn}#tagKeys", validator: validate_DeleteTags_402656670,
    base: "/", makeUrl: url_DeleteTags_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerEngineTypes_402656685 = ref object of OpenApiRestCall_402656044
proc url_DescribeBrokerEngineTypes_402656687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerEngineTypes_402656686(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describe available engine types and versions.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                      ## nextToken: JString
                                                                                                                                                                                      ##            
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## The 
                                                                                                                                                                                      ## token 
                                                                                                                                                                                      ## that 
                                                                                                                                                                                      ## specifies 
                                                                                                                                                                                      ## the 
                                                                                                                                                                                      ## next 
                                                                                                                                                                                      ## page 
                                                                                                                                                                                      ## of 
                                                                                                                                                                                      ## results 
                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                      ## MQ 
                                                                                                                                                                                      ## should 
                                                                                                                                                                                      ## return. 
                                                                                                                                                                                      ## To 
                                                                                                                                                                                      ## request 
                                                                                                                                                                                      ## the 
                                                                                                                                                                                      ## first 
                                                                                                                                                                                      ## page, 
                                                                                                                                                                                      ## leave 
                                                                                                                                                                                      ## nextToken 
                                                                                                                                                                                      ## empty.
  ##   
                                                                                                                                                                                               ## engineType: JString
                                                                                                                                                                                               ##             
                                                                                                                                                                                               ## : 
                                                                                                                                                                                               ## Filter 
                                                                                                                                                                                               ## response 
                                                                                                                                                                                               ## by 
                                                                                                                                                                                               ## engine 
                                                                                                                                                                                               ## type.
  section = newJObject()
  var valid_402656688 = query.getOrDefault("maxResults")
  valid_402656688 = validateParameter(valid_402656688, JInt, required = false,
                                      default = nil)
  if valid_402656688 != nil:
    section.add "maxResults", valid_402656688
  var valid_402656689 = query.getOrDefault("nextToken")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "nextToken", valid_402656689
  var valid_402656690 = query.getOrDefault("engineType")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "engineType", valid_402656690
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
  var valid_402656691 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Security-Token", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Signature")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Signature", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Algorithm", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Date")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Date", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Credential")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Credential", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656698: Call_DescribeBrokerEngineTypes_402656685;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe available engine types and versions.
                                                                                         ## 
  let valid = call_402656698.validator(path, query, header, formData, body, _)
  let scheme = call_402656698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656698.makeUrl(scheme.get, call_402656698.host, call_402656698.base,
                                   call_402656698.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656698, uri, valid, _)

proc call*(call_402656699: Call_DescribeBrokerEngineTypes_402656685;
           maxResults: int = 0; nextToken: string = ""; engineType: string = ""): Recallable =
  ## describeBrokerEngineTypes
  ## Describe available engine types and versions.
  ##   maxResults: int
                                                  ##             : The maximum number of engine types that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                                      ## nextToken: string
                                                                                                                                                                                                      ##            
                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                      ## token 
                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                      ## specifies 
                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                      ## next 
                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                      ## results 
                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                      ## MQ 
                                                                                                                                                                                                      ## should 
                                                                                                                                                                                                      ## return. 
                                                                                                                                                                                                      ## To 
                                                                                                                                                                                                      ## request 
                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                      ## first 
                                                                                                                                                                                                      ## page, 
                                                                                                                                                                                                      ## leave 
                                                                                                                                                                                                      ## nextToken 
                                                                                                                                                                                                      ## empty.
  ##   
                                                                                                                                                                                                               ## engineType: string
                                                                                                                                                                                                               ##             
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## Filter 
                                                                                                                                                                                                               ## response 
                                                                                                                                                                                                               ## by 
                                                                                                                                                                                                               ## engine 
                                                                                                                                                                                                               ## type.
  var query_402656700 = newJObject()
  add(query_402656700, "maxResults", newJInt(maxResults))
  add(query_402656700, "nextToken", newJString(nextToken))
  add(query_402656700, "engineType", newJString(engineType))
  result = call_402656699.call(nil, query_402656700, nil, nil, nil)

var describeBrokerEngineTypes* = Call_DescribeBrokerEngineTypes_402656685(
    name: "describeBrokerEngineTypes", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-engine-types",
    validator: validate_DescribeBrokerEngineTypes_402656686, base: "/",
    makeUrl: url_DescribeBrokerEngineTypes_402656687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBrokerInstanceOptions_402656701 = ref object of OpenApiRestCall_402656044
proc url_DescribeBrokerInstanceOptions_402656703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBrokerInstanceOptions_402656702(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describe available broker instance options.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                          ## storageType: JString
                                                                                                                                                                                          ##              
                                                                                                                                                                                          ## : 
                                                                                                                                                                                          ## Filter 
                                                                                                                                                                                          ## response 
                                                                                                                                                                                          ## by 
                                                                                                                                                                                          ## storage 
                                                                                                                                                                                          ## type.
  ##   
                                                                                                                                                                                                  ## nextToken: JString
                                                                                                                                                                                                  ##            
                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                  ## token 
                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                  ## specifies 
                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                  ## next 
                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                  ## results 
                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                  ## MQ 
                                                                                                                                                                                                  ## should 
                                                                                                                                                                                                  ## return. 
                                                                                                                                                                                                  ## To 
                                                                                                                                                                                                  ## request 
                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                  ## first 
                                                                                                                                                                                                  ## page, 
                                                                                                                                                                                                  ## leave 
                                                                                                                                                                                                  ## nextToken 
                                                                                                                                                                                                  ## empty.
  ##   
                                                                                                                                                                                                           ## engineType: JString
                                                                                                                                                                                                           ##             
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## Filter 
                                                                                                                                                                                                           ## response 
                                                                                                                                                                                                           ## by 
                                                                                                                                                                                                           ## engine 
                                                                                                                                                                                                           ## type.
  ##   
                                                                                                                                                                                                                   ## hostInstanceType: JString
                                                                                                                                                                                                                   ##                   
                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                   ## Filter 
                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                   ## by 
                                                                                                                                                                                                                   ## host 
                                                                                                                                                                                                                   ## instance 
                                                                                                                                                                                                                   ## type.
  section = newJObject()
  var valid_402656704 = query.getOrDefault("maxResults")
  valid_402656704 = validateParameter(valid_402656704, JInt, required = false,
                                      default = nil)
  if valid_402656704 != nil:
    section.add "maxResults", valid_402656704
  var valid_402656705 = query.getOrDefault("storageType")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "storageType", valid_402656705
  var valid_402656706 = query.getOrDefault("nextToken")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "nextToken", valid_402656706
  var valid_402656707 = query.getOrDefault("engineType")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "engineType", valid_402656707
  var valid_402656708 = query.getOrDefault("hostInstanceType")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "hostInstanceType", valid_402656708
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
  var valid_402656709 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Security-Token", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Signature")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Signature", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Algorithm", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Date")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Date", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Credential")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Credential", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656716: Call_DescribeBrokerInstanceOptions_402656701;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe available broker instance options.
                                                                                         ## 
  let valid = call_402656716.validator(path, query, header, formData, body, _)
  let scheme = call_402656716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656716.makeUrl(scheme.get, call_402656716.host, call_402656716.base,
                                   call_402656716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656716, uri, valid, _)

proc call*(call_402656717: Call_DescribeBrokerInstanceOptions_402656701;
           maxResults: int = 0; storageType: string = "";
           nextToken: string = ""; engineType: string = "";
           hostInstanceType: string = ""): Recallable =
  ## describeBrokerInstanceOptions
  ## Describe available broker instance options.
  ##   maxResults: int
                                                ##             : The maximum number of instance options that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                                        ## storageType: string
                                                                                                                                                                                                        ##              
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## Filter 
                                                                                                                                                                                                        ## response 
                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                        ## storage 
                                                                                                                                                                                                        ## type.
  ##   
                                                                                                                                                                                                                ## nextToken: string
                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                ## specifies 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                ## page 
                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                ## results 
                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                ## MQ 
                                                                                                                                                                                                                ## should 
                                                                                                                                                                                                                ## return. 
                                                                                                                                                                                                                ## To 
                                                                                                                                                                                                                ## request 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## first 
                                                                                                                                                                                                                ## page, 
                                                                                                                                                                                                                ## leave 
                                                                                                                                                                                                                ## nextToken 
                                                                                                                                                                                                                ## empty.
  ##   
                                                                                                                                                                                                                         ## engineType: string
                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## Filter 
                                                                                                                                                                                                                         ## response 
                                                                                                                                                                                                                         ## by 
                                                                                                                                                                                                                         ## engine 
                                                                                                                                                                                                                         ## type.
  ##   
                                                                                                                                                                                                                                 ## hostInstanceType: string
                                                                                                                                                                                                                                 ##                   
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Filter 
                                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                                 ## by 
                                                                                                                                                                                                                                 ## host 
                                                                                                                                                                                                                                 ## instance 
                                                                                                                                                                                                                                 ## type.
  var query_402656718 = newJObject()
  add(query_402656718, "maxResults", newJInt(maxResults))
  add(query_402656718, "storageType", newJString(storageType))
  add(query_402656718, "nextToken", newJString(nextToken))
  add(query_402656718, "engineType", newJString(engineType))
  add(query_402656718, "hostInstanceType", newJString(hostInstanceType))
  result = call_402656717.call(nil, query_402656718, nil, nil, nil)

var describeBrokerInstanceOptions* = Call_DescribeBrokerInstanceOptions_402656701(
    name: "describeBrokerInstanceOptions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/broker-instance-options",
    validator: validate_DescribeBrokerInstanceOptions_402656702, base: "/",
    makeUrl: url_DescribeBrokerInstanceOptions_402656703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfiguration_402656733 = ref object of OpenApiRestCall_402656044
proc url_UpdateConfiguration_402656735(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
         "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
                 (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfiguration_402656734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
                                 ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configuration-id` field"
  var valid_402656736 = path.getOrDefault("configuration-id")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true,
                                      default = nil)
  if valid_402656736 != nil:
    section.add "configuration-id", valid_402656736
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
  var valid_402656737 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Security-Token", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Signature")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Signature", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Algorithm", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Date")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Date", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Credential")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Credential", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656743
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

proc call*(call_402656745: Call_UpdateConfiguration_402656733;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified configuration.
                                                                                         ## 
  let valid = call_402656745.validator(path, query, header, formData, body, _)
  let scheme = call_402656745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656745.makeUrl(scheme.get, call_402656745.host, call_402656745.base,
                                   call_402656745.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656745, uri, valid, _)

proc call*(call_402656746: Call_UpdateConfiguration_402656733;
           configurationId: string; body: JsonNode): Recallable =
  ## updateConfiguration
  ## Updates the specified configuration.
  ##   configurationId: string (required)
                                         ##                  : The unique ID that Amazon MQ generates for the configuration.
  ##   
                                                                                                                            ## body: JObject (required)
  var path_402656747 = newJObject()
  var body_402656748 = newJObject()
  add(path_402656747, "configuration-id", newJString(configurationId))
  if body != nil:
    body_402656748 = body
  result = call_402656746.call(path_402656747, nil, nil, nil, body_402656748)

var updateConfiguration* = Call_UpdateConfiguration_402656733(
    name: "updateConfiguration", meth: HttpMethod.HttpPut,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_UpdateConfiguration_402656734, base: "/",
    makeUrl: url_UpdateConfiguration_402656735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_402656719 = ref object of OpenApiRestCall_402656044
proc url_DescribeConfiguration_402656721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
         "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
                 (kind: VariableSegment, value: "configuration-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_402656720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the specified configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
                                 ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configuration-id` field"
  var valid_402656722 = path.getOrDefault("configuration-id")
  valid_402656722 = validateParameter(valid_402656722, JString, required = true,
                                      default = nil)
  if valid_402656722 != nil:
    section.add "configuration-id", valid_402656722
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
  var valid_402656723 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Security-Token", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Signature")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Signature", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Algorithm", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Date")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Date", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Credential")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Credential", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656730: Call_DescribeConfiguration_402656719;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified configuration.
                                                                                         ## 
  let valid = call_402656730.validator(path, query, header, formData, body, _)
  let scheme = call_402656730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656730.makeUrl(scheme.get, call_402656730.host, call_402656730.base,
                                   call_402656730.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656730, uri, valid, _)

proc call*(call_402656731: Call_DescribeConfiguration_402656719;
           configurationId: string): Recallable =
  ## describeConfiguration
  ## Returns information about the specified configuration.
  ##   configurationId: string (required)
                                                           ##                  : The unique ID that Amazon MQ generates for the configuration.
  var path_402656732 = newJObject()
  add(path_402656732, "configuration-id", newJString(configurationId))
  result = call_402656731.call(path_402656732, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_402656719(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}",
    validator: validate_DescribeConfiguration_402656720, base: "/",
    makeUrl: url_DescribeConfiguration_402656721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_402656749 = ref object of OpenApiRestCall_402656044
proc url_DescribeConfigurationRevision_402656751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
         "`configuration-id` is a required path parameter"
  assert "configuration-revision" in path,
         "`configuration-revision` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
                 (kind: VariableSegment, value: "configuration-id"),
                 (kind: ConstantSegment, value: "/revisions/"),
                 (kind: VariableSegment, value: "configuration-revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_402656750(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the specified configuration revision for the specified configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-revision: JString (required)
                                 ##                         : The revision of the configuration.
  ##   
                                                                                                ## configuration-id: JString (required)
                                                                                                ##                   
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## unique 
                                                                                                ## ID 
                                                                                                ## that 
                                                                                                ## Amazon 
                                                                                                ## MQ 
                                                                                                ## generates 
                                                                                                ## for 
                                                                                                ## the 
                                                                                                ## configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configuration-revision` field"
  var valid_402656752 = path.getOrDefault("configuration-revision")
  valid_402656752 = validateParameter(valid_402656752, JString, required = true,
                                      default = nil)
  if valid_402656752 != nil:
    section.add "configuration-revision", valid_402656752
  var valid_402656753 = path.getOrDefault("configuration-id")
  valid_402656753 = validateParameter(valid_402656753, JString, required = true,
                                      default = nil)
  if valid_402656753 != nil:
    section.add "configuration-id", valid_402656753
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

proc call*(call_402656761: Call_DescribeConfigurationRevision_402656749;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the specified configuration revision for the specified configuration.
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

proc call*(call_402656762: Call_DescribeConfigurationRevision_402656749;
           configurationRevision: string; configurationId: string): Recallable =
  ## describeConfigurationRevision
  ## Returns the specified configuration revision for the specified configuration.
  ##   
                                                                                  ## configurationRevision: string (required)
                                                                                  ##                        
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## revision 
                                                                                  ## of 
                                                                                  ## the 
                                                                                  ## configuration.
  ##   
                                                                                                   ## configurationId: string (required)
                                                                                                   ##                  
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## unique 
                                                                                                   ## ID 
                                                                                                   ## that 
                                                                                                   ## Amazon 
                                                                                                   ## MQ 
                                                                                                   ## generates 
                                                                                                   ## for 
                                                                                                   ## the 
                                                                                                   ## configuration.
  var path_402656763 = newJObject()
  add(path_402656763, "configuration-revision",
      newJString(configurationRevision))
  add(path_402656763, "configuration-id", newJString(configurationId))
  result = call_402656762.call(path_402656763, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_402656749(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com", route: "/v1/configurations/{configuration-id}/revisions/{configuration-revision}",
    validator: validate_DescribeConfigurationRevision_402656750, base: "/",
    makeUrl: url_DescribeConfigurationRevision_402656751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_402656764 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurationRevisions_402656766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configuration-id" in path,
         "`configuration-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
                 (kind: VariableSegment, value: "configuration-id"),
                 (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_402656765(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of all revisions for the specified configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configuration-id: JString (required)
                                 ##                   : The unique ID that Amazon MQ generates for the configuration.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configuration-id` field"
  var valid_402656767 = path.getOrDefault("configuration-id")
  valid_402656767 = validateParameter(valid_402656767, JString, required = true,
                                      default = nil)
  if valid_402656767 != nil:
    section.add "configuration-id", valid_402656767
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                        ## nextToken: JString
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## The 
                                                                                                                                                                                        ## token 
                                                                                                                                                                                        ## that 
                                                                                                                                                                                        ## specifies 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## page 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## results 
                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                        ## MQ 
                                                                                                                                                                                        ## should 
                                                                                                                                                                                        ## return. 
                                                                                                                                                                                        ## To 
                                                                                                                                                                                        ## request 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## first 
                                                                                                                                                                                        ## page, 
                                                                                                                                                                                        ## leave 
                                                                                                                                                                                        ## nextToken 
                                                                                                                                                                                        ## empty.
  section = newJObject()
  var valid_402656768 = query.getOrDefault("maxResults")
  valid_402656768 = validateParameter(valid_402656768, JInt, required = false,
                                      default = nil)
  if valid_402656768 != nil:
    section.add "maxResults", valid_402656768
  var valid_402656769 = query.getOrDefault("nextToken")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "nextToken", valid_402656769
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
  var valid_402656770 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Security-Token", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Signature")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Signature", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Algorithm", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Date")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Date", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Credential")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Credential", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656777: Call_ListConfigurationRevisions_402656764;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all revisions for the specified configuration.
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

proc call*(call_402656778: Call_ListConfigurationRevisions_402656764;
           configurationId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## Returns a list of all revisions for the specified configuration.
  ##   maxResults: int
                                                                     ##             : The maximum number of configurations that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                                                           ## configurationId: string (required)
                                                                                                                                                                                                                           ##                  
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                           ## unique 
                                                                                                                                                                                                                           ## ID 
                                                                                                                                                                                                                           ## that 
                                                                                                                                                                                                                           ## Amazon 
                                                                                                                                                                                                                           ## MQ 
                                                                                                                                                                                                                           ## generates 
                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                           ## configuration.
  ##   
                                                                                                                                                                                                                                            ## nextToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                            ## token 
                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                            ## specifies 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## next 
                                                                                                                                                                                                                                            ## page 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                            ## Amazon 
                                                                                                                                                                                                                                            ## MQ 
                                                                                                                                                                                                                                            ## should 
                                                                                                                                                                                                                                            ## return. 
                                                                                                                                                                                                                                            ## To 
                                                                                                                                                                                                                                            ## request 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## first 
                                                                                                                                                                                                                                            ## page, 
                                                                                                                                                                                                                                            ## leave 
                                                                                                                                                                                                                                            ## nextToken 
                                                                                                                                                                                                                                            ## empty.
  var path_402656779 = newJObject()
  var query_402656780 = newJObject()
  add(query_402656780, "maxResults", newJInt(maxResults))
  add(path_402656779, "configuration-id", newJString(configurationId))
  add(query_402656780, "nextToken", newJString(nextToken))
  result = call_402656778.call(path_402656779, query_402656780, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_402656764(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "mq.amazonaws.com",
    route: "/v1/configurations/{configuration-id}/revisions",
    validator: validate_ListConfigurationRevisions_402656765, base: "/",
    makeUrl: url_ListConfigurationRevisions_402656766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_402656781 = ref object of OpenApiRestCall_402656044
proc url_ListUsers_402656783(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_402656782(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all ActiveMQ users.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
                                 ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `broker-id` field"
  var valid_402656784 = path.getOrDefault("broker-id")
  valid_402656784 = validateParameter(valid_402656784, JString, required = true,
                                      default = nil)
  if valid_402656784 != nil:
    section.add "broker-id", valid_402656784
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of ActiveMQ users that can be returned per page (20 by default). This value must be an integer from 5 to 100.
  ##   
                                                                                                                                                                                   ## nextToken: JString
                                                                                                                                                                                   ##            
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## The 
                                                                                                                                                                                   ## token 
                                                                                                                                                                                   ## that 
                                                                                                                                                                                   ## specifies 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## next 
                                                                                                                                                                                   ## page 
                                                                                                                                                                                   ## of 
                                                                                                                                                                                   ## results 
                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                   ## MQ 
                                                                                                                                                                                   ## should 
                                                                                                                                                                                   ## return. 
                                                                                                                                                                                   ## To 
                                                                                                                                                                                   ## request 
                                                                                                                                                                                   ## the 
                                                                                                                                                                                   ## first 
                                                                                                                                                                                   ## page, 
                                                                                                                                                                                   ## leave 
                                                                                                                                                                                   ## nextToken 
                                                                                                                                                                                   ## empty.
  section = newJObject()
  var valid_402656785 = query.getOrDefault("maxResults")
  valid_402656785 = validateParameter(valid_402656785, JInt, required = false,
                                      default = nil)
  if valid_402656785 != nil:
    section.add "maxResults", valid_402656785
  var valid_402656786 = query.getOrDefault("nextToken")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "nextToken", valid_402656786
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
  var valid_402656787 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Security-Token", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Signature")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Signature", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Algorithm", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Date")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Date", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Credential")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Credential", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656794: Call_ListUsers_402656781; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all ActiveMQ users.
                                                                                         ## 
  let valid = call_402656794.validator(path, query, header, formData, body, _)
  let scheme = call_402656794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656794.makeUrl(scheme.get, call_402656794.host, call_402656794.base,
                                   call_402656794.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656794, uri, valid, _)

proc call*(call_402656795: Call_ListUsers_402656781; brokerId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all ActiveMQ users.
  ##   brokerId: string (required)
                                          ##           : The unique ID that Amazon MQ generates for the broker.
  ##   
                                                                                                               ## maxResults: int
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## maximum 
                                                                                                               ## number 
                                                                                                               ## of 
                                                                                                               ## ActiveMQ 
                                                                                                               ## users 
                                                                                                               ## that 
                                                                                                               ## can 
                                                                                                               ## be 
                                                                                                               ## returned 
                                                                                                               ## per 
                                                                                                               ## page 
                                                                                                               ## (20 
                                                                                                               ## by 
                                                                                                               ## default). 
                                                                                                               ## This 
                                                                                                               ## value 
                                                                                                               ## must 
                                                                                                               ## be 
                                                                                                               ## an 
                                                                                                               ## integer 
                                                                                                               ## from 
                                                                                                               ## 5 
                                                                                                               ## to 
                                                                                                               ## 100.
  ##   
                                                                                                                      ## nextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## token 
                                                                                                                      ## that 
                                                                                                                      ## specifies 
                                                                                                                      ## the 
                                                                                                                      ## next 
                                                                                                                      ## page 
                                                                                                                      ## of 
                                                                                                                      ## results 
                                                                                                                      ## Amazon 
                                                                                                                      ## MQ 
                                                                                                                      ## should 
                                                                                                                      ## return. 
                                                                                                                      ## To 
                                                                                                                      ## request 
                                                                                                                      ## the 
                                                                                                                      ## first 
                                                                                                                      ## page, 
                                                                                                                      ## leave 
                                                                                                                      ## nextToken 
                                                                                                                      ## empty.
  var path_402656796 = newJObject()
  var query_402656797 = newJObject()
  add(path_402656796, "broker-id", newJString(brokerId))
  add(query_402656797, "maxResults", newJInt(maxResults))
  add(query_402656797, "nextToken", newJString(nextToken))
  result = call_402656795.call(path_402656796, query_402656797, nil, nil, nil)

var listUsers* = Call_ListUsers_402656781(name: "listUsers",
    meth: HttpMethod.HttpGet, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/users", validator: validate_ListUsers_402656782,
    base: "/", makeUrl: url_ListUsers_402656783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootBroker_402656798 = ref object of OpenApiRestCall_402656044
proc url_RebootBroker_402656800(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "broker-id" in path, "`broker-id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/brokers/"),
                 (kind: VariableSegment, value: "broker-id"),
                 (kind: ConstantSegment, value: "/reboot")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RebootBroker_402656799(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Reboots a broker. Note: This API is asynchronous.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   broker-id: JString (required)
                                 ##            : The unique ID that Amazon MQ generates for the broker.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `broker-id` field"
  var valid_402656801 = path.getOrDefault("broker-id")
  valid_402656801 = validateParameter(valid_402656801, JString, required = true,
                                      default = nil)
  if valid_402656801 != nil:
    section.add "broker-id", valid_402656801
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
  var valid_402656802 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Security-Token", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Signature")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Signature", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Algorithm", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Date")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Date", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Credential")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Credential", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656809: Call_RebootBroker_402656798; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Reboots a broker. Note: This API is asynchronous.
                                                                                         ## 
  let valid = call_402656809.validator(path, query, header, formData, body, _)
  let scheme = call_402656809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656809.makeUrl(scheme.get, call_402656809.host, call_402656809.base,
                                   call_402656809.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656809, uri, valid, _)

proc call*(call_402656810: Call_RebootBroker_402656798; brokerId: string): Recallable =
  ## rebootBroker
  ## Reboots a broker. Note: This API is asynchronous.
  ##   brokerId: string (required)
                                                      ##           : The unique ID that Amazon MQ generates for the broker.
  var path_402656811 = newJObject()
  add(path_402656811, "broker-id", newJString(brokerId))
  result = call_402656810.call(path_402656811, nil, nil, nil, nil)

var rebootBroker* = Call_RebootBroker_402656798(name: "rebootBroker",
    meth: HttpMethod.HttpPost, host: "mq.amazonaws.com",
    route: "/v1/brokers/{broker-id}/reboot", validator: validate_RebootBroker_402656799,
    base: "/", makeUrl: url_RebootBroker_402656800,
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