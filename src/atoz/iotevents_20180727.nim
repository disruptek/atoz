
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Events
## version: 2018-07-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS IoT Events monitors your equipment or device fleets for failures or changes in operation, and triggers actions when such events occur. You can use AWS IoT Events API commands to create, read, update, and delete inputs and detector models, and to list their versions.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iotevents/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "iotevents.ap-northeast-1.amazonaws.com", "ap-southeast-1": "iotevents.ap-southeast-1.amazonaws.com", "us-west-2": "iotevents.us-west-2.amazonaws.com", "eu-west-2": "iotevents.eu-west-2.amazonaws.com", "ap-northeast-3": "iotevents.ap-northeast-3.amazonaws.com", "eu-central-1": "iotevents.eu-central-1.amazonaws.com", "us-east-2": "iotevents.us-east-2.amazonaws.com", "us-east-1": "iotevents.us-east-1.amazonaws.com", "cn-northwest-1": "iotevents.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "iotevents.ap-south-1.amazonaws.com", "eu-north-1": "iotevents.eu-north-1.amazonaws.com", "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com", "us-west-1": "iotevents.us-west-1.amazonaws.com", "us-gov-east-1": "iotevents.us-gov-east-1.amazonaws.com", "eu-west-3": "iotevents.eu-west-3.amazonaws.com", "cn-north-1": "iotevents.cn-north-1.amazonaws.com.cn", "sa-east-1": "iotevents.sa-east-1.amazonaws.com", "eu-west-1": "iotevents.eu-west-1.amazonaws.com", "us-gov-west-1": "iotevents.us-gov-west-1.amazonaws.com", "ap-southeast-2": "iotevents.ap-southeast-2.amazonaws.com", "ca-central-1": "iotevents.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "iotevents.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "iotevents.ap-southeast-1.amazonaws.com",
      "us-west-2": "iotevents.us-west-2.amazonaws.com",
      "eu-west-2": "iotevents.eu-west-2.amazonaws.com",
      "ap-northeast-3": "iotevents.ap-northeast-3.amazonaws.com",
      "eu-central-1": "iotevents.eu-central-1.amazonaws.com",
      "us-east-2": "iotevents.us-east-2.amazonaws.com",
      "us-east-1": "iotevents.us-east-1.amazonaws.com",
      "cn-northwest-1": "iotevents.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "iotevents.ap-south-1.amazonaws.com",
      "eu-north-1": "iotevents.eu-north-1.amazonaws.com",
      "ap-northeast-2": "iotevents.ap-northeast-2.amazonaws.com",
      "us-west-1": "iotevents.us-west-1.amazonaws.com",
      "us-gov-east-1": "iotevents.us-gov-east-1.amazonaws.com",
      "eu-west-3": "iotevents.eu-west-3.amazonaws.com",
      "cn-north-1": "iotevents.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "iotevents.sa-east-1.amazonaws.com",
      "eu-west-1": "iotevents.eu-west-1.amazonaws.com",
      "us-gov-west-1": "iotevents.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "iotevents.ap-southeast-2.amazonaws.com",
      "ca-central-1": "iotevents.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotevents"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateDetectorModel_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateDetectorModel_402656479(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorModel_402656478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a detector model.
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

proc call*(call_402656488: Call_CreateDetectorModel_402656477;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a detector model.
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

proc call*(call_402656489: Call_CreateDetectorModel_402656477; body: JsonNode): Recallable =
  ## createDetectorModel
  ## Creates a detector model.
  ##   body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createDetectorModel* = Call_CreateDetectorModel_402656477(
    name: "createDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_CreateDetectorModel_402656478, base: "/",
    makeUrl: url_CreateDetectorModel_402656479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModels_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListDetectorModels_402656296(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectorModels_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return at one time.
  ##   
                                                                                                       ## nextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## token 
                                                                                                       ## for 
                                                                                                       ## the 
                                                                                                       ## next 
                                                                                                       ## set 
                                                                                                       ## of 
                                                                                                       ## results.
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

proc call*(call_402656397: Call_ListDetectorModels_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
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

proc call*(call_402656446: Call_ListDetectorModels_402656294;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDetectorModels
  ## Lists the detector models you have created. Only the metadata associated with each detector model is returned.
  ##   
                                                                                                                   ## maxResults: int
                                                                                                                   ##             
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## maximum 
                                                                                                                   ## number 
                                                                                                                   ## of 
                                                                                                                   ## results 
                                                                                                                   ## to 
                                                                                                                   ## return 
                                                                                                                   ## at 
                                                                                                                   ## one 
                                                                                                                   ## time.
  ##   
                                                                                                                           ## nextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## token 
                                                                                                                           ## for 
                                                                                                                           ## the 
                                                                                                                           ## next 
                                                                                                                           ## set 
                                                                                                                           ## of 
                                                                                                                           ## results.
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJInt(maxResults))
  add(query_402656447, "nextToken", newJString(nextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listDetectorModels* = Call_ListDetectorModels_402656294(
    name: "listDetectorModels", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/detector-models",
    validator: validate_ListDetectorModels_402656295, base: "/",
    makeUrl: url_ListDetectorModels_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_402656506 = ref object of OpenApiRestCall_402656044
proc url_CreateInput_402656508(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_402656507(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an input.
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

proc call*(call_402656517: Call_CreateInput_402656506; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an input.
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

proc call*(call_402656518: Call_CreateInput_402656506; body: JsonNode): Recallable =
  ## createInput
  ## Creates an input.
  ##   body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var createInput* = Call_CreateInput_402656506(name: "createInput",
    meth: HttpMethod.HttpPost, host: "iotevents.amazonaws.com",
    route: "/inputs", validator: validate_CreateInput_402656507, base: "/",
    makeUrl: url_CreateInput_402656508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListInputs_402656493(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_402656492(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the inputs you have created.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return at one time.
  ##   
                                                                                                       ## nextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## token 
                                                                                                       ## for 
                                                                                                       ## the 
                                                                                                       ## next 
                                                                                                       ## set 
                                                                                                       ## of 
                                                                                                       ## results.
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

proc call*(call_402656503: Call_ListInputs_402656491; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the inputs you have created.
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

proc call*(call_402656504: Call_ListInputs_402656491; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listInputs
  ## Lists the inputs you have created.
  ##   maxResults: int
                                       ##             : The maximum number of results to return at one time.
  ##   
                                                                                                            ## nextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## token 
                                                                                                            ## for 
                                                                                                            ## the 
                                                                                                            ## next 
                                                                                                            ## set 
                                                                                                            ## of 
                                                                                                            ## results.
  var query_402656505 = newJObject()
  add(query_402656505, "maxResults", newJInt(maxResults))
  add(query_402656505, "nextToken", newJString(nextToken))
  result = call_402656504.call(nil, query_402656505, nil, nil, nil)

var listInputs* = Call_ListInputs_402656491(name: "listInputs",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com", route: "/inputs",
    validator: validate_ListInputs_402656492, base: "/",
    makeUrl: url_ListInputs_402656493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorModel_402656547 = ref object of OpenApiRestCall_402656044
proc url_UpdateDetectorModel_402656549(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
         "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
                 (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDetectorModel_402656548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
                                 ##                    : The name of the detector model that is updated.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorModelName` field"
  var valid_402656550 = path.getOrDefault("detectorModelName")
  valid_402656550 = validateParameter(valid_402656550, JString, required = true,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "detectorModelName", valid_402656550
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
  var valid_402656551 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Security-Token", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Signature")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Signature", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Algorithm", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Date")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Date", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Credential")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Credential", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656557
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

proc call*(call_402656559: Call_UpdateDetectorModel_402656547;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
                                                                                         ## 
  let valid = call_402656559.validator(path, query, header, formData, body, _)
  let scheme = call_402656559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656559.makeUrl(scheme.get, call_402656559.host, call_402656559.base,
                                   call_402656559.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656559, uri, valid, _)

proc call*(call_402656560: Call_UpdateDetectorModel_402656547;
           detectorModelName: string; body: JsonNode): Recallable =
  ## updateDetectorModel
  ## Updates a detector model. Detectors (instances) spawned by the previous version are deleted and then re-created as new inputs arrive.
  ##   
                                                                                                                                          ## detectorModelName: string (required)
                                                                                                                                          ##                    
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## name 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## detector 
                                                                                                                                          ## model 
                                                                                                                                          ## that 
                                                                                                                                          ## is 
                                                                                                                                          ## updated.
  ##   
                                                                                                                                                     ## body: JObject (required)
  var path_402656561 = newJObject()
  var body_402656562 = newJObject()
  add(path_402656561, "detectorModelName", newJString(detectorModelName))
  if body != nil:
    body_402656562 = body
  result = call_402656560.call(path_402656561, nil, nil, nil, body_402656562)

var updateDetectorModel* = Call_UpdateDetectorModel_402656547(
    name: "updateDetectorModel", meth: HttpMethod.HttpPost,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_UpdateDetectorModel_402656548, base: "/",
    makeUrl: url_UpdateDetectorModel_402656549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetectorModel_402656520 = ref object of OpenApiRestCall_402656044
proc url_DescribeDetectorModel_402656522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
         "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
                 (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDetectorModel_402656521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
                                 ##                    : The name of the detector model.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorModelName` field"
  var valid_402656534 = path.getOrDefault("detectorModelName")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "detectorModelName", valid_402656534
  result.add "path", section
  ## parameters in `query` object:
  ##   version: JString
                                  ##          : The version of the detector model.
  section = newJObject()
  var valid_402656535 = query.getOrDefault("version")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "version", valid_402656535
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
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656543: Call_DescribeDetectorModel_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_DescribeDetectorModel_402656520;
           detectorModelName: string; version: string = ""): Recallable =
  ## describeDetectorModel
  ## Describes a detector model. If the <code>version</code> parameter is not specified, information about the latest version is returned.
  ##   
                                                                                                                                          ## detectorModelName: string (required)
                                                                                                                                          ##                    
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## name 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## detector 
                                                                                                                                          ## model.
  ##   
                                                                                                                                                   ## version: string
                                                                                                                                                   ##          
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## version 
                                                                                                                                                   ## of 
                                                                                                                                                   ## the 
                                                                                                                                                   ## detector 
                                                                                                                                                   ## model.
  var path_402656545 = newJObject()
  var query_402656546 = newJObject()
  add(path_402656545, "detectorModelName", newJString(detectorModelName))
  add(query_402656546, "version", newJString(version))
  result = call_402656544.call(path_402656545, query_402656546, nil, nil, nil)

var describeDetectorModel* = Call_DescribeDetectorModel_402656520(
    name: "describeDetectorModel", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DescribeDetectorModel_402656521, base: "/",
    makeUrl: url_DescribeDetectorModel_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorModel_402656563 = ref object of OpenApiRestCall_402656044
proc url_DeleteDetectorModel_402656565(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
         "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
                 (kind: VariableSegment, value: "detectorModelName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDetectorModel_402656564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
                                 ##                    : The name of the detector model to be deleted.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorModelName` field"
  var valid_402656566 = path.getOrDefault("detectorModelName")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "detectorModelName", valid_402656566
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
  var valid_402656567 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Security-Token", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Signature")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Signature", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Algorithm", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Date")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Date", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Credential")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Credential", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656574: Call_DeleteDetectorModel_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
                                                                                         ## 
  let valid = call_402656574.validator(path, query, header, formData, body, _)
  let scheme = call_402656574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656574.makeUrl(scheme.get, call_402656574.host, call_402656574.base,
                                   call_402656574.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656574, uri, valid, _)

proc call*(call_402656575: Call_DeleteDetectorModel_402656563;
           detectorModelName: string): Recallable =
  ## deleteDetectorModel
  ## Deletes a detector model. Any active instances of the detector model are also deleted.
  ##   
                                                                                           ## detectorModelName: string (required)
                                                                                           ##                    
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## name 
                                                                                           ## of 
                                                                                           ## the 
                                                                                           ## detector 
                                                                                           ## model 
                                                                                           ## to 
                                                                                           ## be 
                                                                                           ## deleted.
  var path_402656576 = newJObject()
  add(path_402656576, "detectorModelName", newJString(detectorModelName))
  result = call_402656575.call(path_402656576, nil, nil, nil, nil)

var deleteDetectorModel* = Call_DeleteDetectorModel_402656563(
    name: "deleteDetectorModel", meth: HttpMethod.HttpDelete,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}",
    validator: validate_DeleteDetectorModel_402656564, base: "/",
    makeUrl: url_DeleteDetectorModel_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_402656591 = ref object of OpenApiRestCall_402656044
proc url_UpdateInput_402656593(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
                 (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_402656592(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an input.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
                                 ##            : The name of the input you want to update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputName` field"
  var valid_402656594 = path.getOrDefault("inputName")
  valid_402656594 = validateParameter(valid_402656594, JString, required = true,
                                      default = nil)
  if valid_402656594 != nil:
    section.add "inputName", valid_402656594
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
  var valid_402656595 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Security-Token", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Signature")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Signature", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Algorithm", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Date")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Date", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Credential")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Credential", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656601
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

proc call*(call_402656603: Call_UpdateInput_402656591; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an input.
                                                                                         ## 
  let valid = call_402656603.validator(path, query, header, formData, body, _)
  let scheme = call_402656603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656603.makeUrl(scheme.get, call_402656603.host, call_402656603.base,
                                   call_402656603.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656603, uri, valid, _)

proc call*(call_402656604: Call_UpdateInput_402656591; inputName: string;
           body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputName: string (required)
                      ##            : The name of the input you want to update.
  ##   
                                                                               ## body: JObject (required)
  var path_402656605 = newJObject()
  var body_402656606 = newJObject()
  add(path_402656605, "inputName", newJString(inputName))
  if body != nil:
    body_402656606 = body
  result = call_402656604.call(path_402656605, nil, nil, nil, body_402656606)

var updateInput* = Call_UpdateInput_402656591(name: "updateInput",
    meth: HttpMethod.HttpPut, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_UpdateInput_402656592,
    base: "/", makeUrl: url_UpdateInput_402656593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_402656577 = ref object of OpenApiRestCall_402656044
proc url_DescribeInput_402656579(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
                 (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_402656578(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an input.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
                                 ##            : The name of the input.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputName` field"
  var valid_402656580 = path.getOrDefault("inputName")
  valid_402656580 = validateParameter(valid_402656580, JString, required = true,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "inputName", valid_402656580
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
  if body != nil:
    result.add "body", body

proc call*(call_402656588: Call_DescribeInput_402656577; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an input.
                                                                                         ## 
  let valid = call_402656588.validator(path, query, header, formData, body, _)
  let scheme = call_402656588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656588.makeUrl(scheme.get, call_402656588.host, call_402656588.base,
                                   call_402656588.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656588, uri, valid, _)

proc call*(call_402656589: Call_DescribeInput_402656577; inputName: string): Recallable =
  ## describeInput
  ## Describes an input.
  ##   inputName: string (required)
                        ##            : The name of the input.
  var path_402656590 = newJObject()
  add(path_402656590, "inputName", newJString(inputName))
  result = call_402656589.call(path_402656590, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_402656577(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DescribeInput_402656578,
    base: "/", makeUrl: url_DescribeInput_402656579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_402656607 = ref object of OpenApiRestCall_402656044
proc url_DeleteInput_402656609(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputName" in path, "`inputName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/inputs/"),
                 (kind: VariableSegment, value: "inputName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_402656608(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an input.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputName: JString (required)
                                 ##            : The name of the input to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputName` field"
  var valid_402656610 = path.getOrDefault("inputName")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = nil)
  if valid_402656610 != nil:
    section.add "inputName", valid_402656610
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
  var valid_402656611 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Security-Token", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Signature")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Signature", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Algorithm", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Date")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Date", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Credential")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Credential", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656618: Call_DeleteInput_402656607; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an input.
                                                                                         ## 
  let valid = call_402656618.validator(path, query, header, formData, body, _)
  let scheme = call_402656618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656618.makeUrl(scheme.get, call_402656618.host, call_402656618.base,
                                   call_402656618.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656618, uri, valid, _)

proc call*(call_402656619: Call_DeleteInput_402656607; inputName: string): Recallable =
  ## deleteInput
  ## Deletes an input.
  ##   inputName: string (required)
                      ##            : The name of the input to delete.
  var path_402656620 = newJObject()
  add(path_402656620, "inputName", newJString(inputName))
  result = call_402656619.call(path_402656620, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_402656607(name: "deleteInput",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/inputs/{inputName}", validator: validate_DeleteInput_402656608,
    base: "/", makeUrl: url_DeleteInput_402656609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingOptions_402656633 = ref object of OpenApiRestCall_402656044
proc url_PutLoggingOptions_402656635(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingOptions_402656634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
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

proc call*(call_402656644: Call_PutLoggingOptions_402656633;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
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

proc call*(call_402656645: Call_PutLoggingOptions_402656633; body: JsonNode): Recallable =
  ## putLoggingOptions
  ## <p>Sets or updates the AWS IoT Events logging options.</p> <p>If you update the value of any <code>loggingOptions</code> field, it takes up to one minute for the change to take effect. If you change the policy attached to the role you specified in the <code>roleArn</code> field (for example, to correct an invalid policy), it takes up to five minutes for that change to take effect.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656646 = newJObject()
  if body != nil:
    body_402656646 = body
  result = call_402656645.call(nil, nil, nil, nil, body_402656646)

var putLoggingOptions* = Call_PutLoggingOptions_402656633(
    name: "putLoggingOptions", meth: HttpMethod.HttpPut,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_PutLoggingOptions_402656634, base: "/",
    makeUrl: url_PutLoggingOptions_402656635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoggingOptions_402656621 = ref object of OpenApiRestCall_402656044
proc url_DescribeLoggingOptions_402656623(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoggingOptions_402656622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the current settings of the AWS IoT Events logging options.
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
  var valid_402656624 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Security-Token", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Signature")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Signature", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Algorithm", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Date")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Date", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Credential")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Credential", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656631: Call_DescribeLoggingOptions_402656621;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current settings of the AWS IoT Events logging options.
                                                                                         ## 
  let valid = call_402656631.validator(path, query, header, formData, body, _)
  let scheme = call_402656631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656631.makeUrl(scheme.get, call_402656631.host, call_402656631.base,
                                   call_402656631.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656631, uri, valid, _)

proc call*(call_402656632: Call_DescribeLoggingOptions_402656621): Recallable =
  ## describeLoggingOptions
  ## Retrieves the current settings of the AWS IoT Events logging options.
  result = call_402656632.call(nil, nil, nil, nil, nil)

var describeLoggingOptions* = Call_DescribeLoggingOptions_402656621(
    name: "describeLoggingOptions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/logging",
    validator: validate_DescribeLoggingOptions_402656622, base: "/",
    makeUrl: url_DescribeLoggingOptions_402656623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectorModelVersions_402656647 = ref object of OpenApiRestCall_402656044
proc url_ListDetectorModelVersions_402656649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorModelName" in path,
         "`detectorModelName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector-models/"),
                 (kind: VariableSegment, value: "detectorModelName"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDetectorModelVersions_402656648(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorModelName: JString (required)
                                 ##                    : The name of the detector model whose versions are returned.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorModelName` field"
  var valid_402656650 = path.getOrDefault("detectorModelName")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "detectorModelName", valid_402656650
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return at one time.
  ##   
                                                                                                       ## nextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## token 
                                                                                                       ## for 
                                                                                                       ## the 
                                                                                                       ## next 
                                                                                                       ## set 
                                                                                                       ## of 
                                                                                                       ## results.
  section = newJObject()
  var valid_402656651 = query.getOrDefault("maxResults")
  valid_402656651 = validateParameter(valid_402656651, JInt, required = false,
                                      default = nil)
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

proc call*(call_402656660: Call_ListDetectorModelVersions_402656647;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
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

proc call*(call_402656661: Call_ListDetectorModelVersions_402656647;
           detectorModelName: string; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listDetectorModelVersions
  ## Lists all the versions of a detector model. Only the metadata associated with each detector model version is returned.
  ##   
                                                                                                                           ## maxResults: int
                                                                                                                           ##             
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## maximum 
                                                                                                                           ## number 
                                                                                                                           ## of 
                                                                                                                           ## results 
                                                                                                                           ## to 
                                                                                                                           ## return 
                                                                                                                           ## at 
                                                                                                                           ## one 
                                                                                                                           ## time.
  ##   
                                                                                                                                   ## detectorModelName: string (required)
                                                                                                                                   ##                    
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## name 
                                                                                                                                   ## of 
                                                                                                                                   ## the 
                                                                                                                                   ## detector 
                                                                                                                                   ## model 
                                                                                                                                   ## whose 
                                                                                                                                   ## versions 
                                                                                                                                   ## are 
                                                                                                                                   ## returned.
  ##   
                                                                                                                                               ## nextToken: string
                                                                                                                                               ##            
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## token 
                                                                                                                                               ## for 
                                                                                                                                               ## the 
                                                                                                                                               ## next 
                                                                                                                                               ## set 
                                                                                                                                               ## of 
                                                                                                                                               ## results.
  var path_402656662 = newJObject()
  var query_402656663 = newJObject()
  add(query_402656663, "maxResults", newJInt(maxResults))
  add(path_402656662, "detectorModelName", newJString(detectorModelName))
  add(query_402656663, "nextToken", newJString(nextToken))
  result = call_402656661.call(path_402656662, query_402656663, nil, nil, nil)

var listDetectorModelVersions* = Call_ListDetectorModelVersions_402656647(
    name: "listDetectorModelVersions", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com",
    route: "/detector-models/{detectorModelName}/versions",
    validator: validate_ListDetectorModelVersions_402656648, base: "/",
    makeUrl: url_ListDetectorModelVersions_402656649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656678 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656680(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656679(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
                                  ##              : The ARN of the resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `resourceArn` field"
  var valid_402656681 = query.getOrDefault("resourceArn")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "resourceArn", valid_402656681
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
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
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

proc call*(call_402656690: Call_TagResource_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
                                                                                         ## 
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_TagResource_402656678; resourceArn: string;
           body: JsonNode): Recallable =
  ## tagResource
  ## Adds to or modifies the tags of the given resource. Tags are metadata that can be used to manage a resource.
  ##   
                                                                                                                 ## resourceArn: string (required)
                                                                                                                 ##              
                                                                                                                 ## : 
                                                                                                                 ## The 
                                                                                                                 ## ARN 
                                                                                                                 ## of 
                                                                                                                 ## the 
                                                                                                                 ## resource.
  ##   
                                                                                                                             ## body: JObject (required)
  var query_402656692 = newJObject()
  var body_402656693 = newJObject()
  add(query_402656692, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_402656693 = body
  result = call_402656691.call(nil, query_402656692, nil, nil, body_402656693)

var tagResource* = Call_TagResource_402656678(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn", validator: validate_TagResource_402656679,
    base: "/", makeUrl: url_TagResource_402656680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656664 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656666(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags (metadata) you have assigned to the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
                                  ##              : The ARN of the resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `resourceArn` field"
  var valid_402656667 = query.getOrDefault("resourceArn")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "resourceArn", valid_402656667
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
  if body != nil:
    result.add "body", body

proc call*(call_402656675: Call_ListTagsForResource_402656664;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags (metadata) you have assigned to the resource.
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_ListTagsForResource_402656664;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags (metadata) you have assigned to the resource.
  ##   resourceArn: string (required)
                                                                 ##              : The ARN of the resource.
  var query_402656677 = newJObject()
  add(query_402656677, "resourceArn", newJString(resourceArn))
  result = call_402656676.call(nil, query_402656677, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656664(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "iotevents.amazonaws.com", route: "/tags#resourceArn",
    validator: validate_ListTagsForResource_402656665, base: "/",
    makeUrl: url_ListTagsForResource_402656666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656694 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656696(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656695(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the given tags (metadata) from the resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A list of the keys of the tags to be removed from the resource.
  ##   
                                                                                                               ## resourceArn: JString (required)
                                                                                                               ##              
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## ARN 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656697 = query.getOrDefault("tagKeys")
  valid_402656697 = validateParameter(valid_402656697, JArray, required = true,
                                      default = nil)
  if valid_402656697 != nil:
    section.add "tagKeys", valid_402656697
  var valid_402656698 = query.getOrDefault("resourceArn")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true,
                                      default = nil)
  if valid_402656698 != nil:
    section.add "resourceArn", valid_402656698
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
  var valid_402656699 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Security-Token", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Signature")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Signature", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Algorithm", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Date")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Date", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Credential")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Credential", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656706: Call_UntagResource_402656694; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the given tags (metadata) from the resource.
                                                                                         ## 
  let valid = call_402656706.validator(path, query, header, formData, body, _)
  let scheme = call_402656706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656706.makeUrl(scheme.get, call_402656706.host, call_402656706.base,
                                   call_402656706.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656706, uri, valid, _)

proc call*(call_402656707: Call_UntagResource_402656694; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes the given tags (metadata) from the resource.
  ##   tagKeys: JArray (required)
                                                         ##          : A list of the keys of the tags to be removed from the resource.
  ##   
                                                                                                                                      ## resourceArn: string (required)
                                                                                                                                      ##              
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## ARN 
                                                                                                                                      ## of 
                                                                                                                                      ## the 
                                                                                                                                      ## resource.
  var query_402656708 = newJObject()
  if tagKeys != nil:
    query_402656708.add "tagKeys", tagKeys
  add(query_402656708, "resourceArn", newJString(resourceArn))
  result = call_402656707.call(nil, query_402656708, nil, nil, nil)

var untagResource* = Call_UntagResource_402656694(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "iotevents.amazonaws.com",
    route: "/tags#resourceArn&tagKeys", validator: validate_UntagResource_402656695,
    base: "/", makeUrl: url_UntagResource_402656696,
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