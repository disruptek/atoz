
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Amplify
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  Amplify is a fully managed continuous deployment and hosting service for modern web apps. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/amplify/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com", "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
                               "us-west-2": "amplify.us-west-2.amazonaws.com",
                               "eu-west-2": "amplify.eu-west-2.amazonaws.com", "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com", "eu-central-1": "amplify.eu-central-1.amazonaws.com",
                               "us-east-2": "amplify.us-east-2.amazonaws.com",
                               "us-east-1": "amplify.us-east-1.amazonaws.com", "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "amplify.ap-south-1.amazonaws.com", "eu-north-1": "amplify.eu-north-1.amazonaws.com", "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
                               "us-west-1": "amplify.us-west-1.amazonaws.com", "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "amplify.eu-west-3.amazonaws.com", "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "amplify.sa-east-1.amazonaws.com",
                               "eu-west-1": "amplify.eu-west-1.amazonaws.com", "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com", "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com", "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
      "us-west-2": "amplify.us-west-2.amazonaws.com",
      "eu-west-2": "amplify.eu-west-2.amazonaws.com",
      "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com",
      "eu-central-1": "amplify.eu-central-1.amazonaws.com",
      "us-east-2": "amplify.us-east-2.amazonaws.com",
      "us-east-1": "amplify.us-east-1.amazonaws.com",
      "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "amplify.ap-south-1.amazonaws.com",
      "eu-north-1": "amplify.eu-north-1.amazonaws.com",
      "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
      "us-west-1": "amplify.us-west-1.amazonaws.com",
      "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
      "eu-west-3": "amplify.eu-west-3.amazonaws.com",
      "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "amplify.sa-east-1.amazonaws.com",
      "eu-west-1": "amplify.eu-west-1.amazonaws.com",
      "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com",
      "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "amplify"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateApp_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateApp_402656479(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_402656478(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a new Amplify App. 
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

proc call*(call_402656488: Call_CreateApp_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new Amplify App. 
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

proc call*(call_402656489: Call_CreateApp_402656477; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createApp* = Call_CreateApp_402656477(name: "createApp",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com", route: "/apps",
    validator: validate_CreateApp_402656478, base: "/", makeUrl: url_CreateApp_402656479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListApps_402656296(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_402656295(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Lists existing Amplify Apps. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## If 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## another 
                                                                                                            ## request 
                                                                                                            ## to 
                                                                                                            ## fetch 
                                                                                                            ## more 
                                                                                                            ## entries. 
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

proc call*(call_402656397: Call_ListApps_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Lists existing Amplify Apps. 
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

proc call*(call_402656446: Call_ListApps_402656294; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   maxResults: int
                                   ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                             ## nextToken: string
                                                                                                             ##            
                                                                                                             ## :  
                                                                                                             ## Pagination 
                                                                                                             ## token. 
                                                                                                             ## If 
                                                                                                             ## non-null 
                                                                                                             ## pagination 
                                                                                                             ## token 
                                                                                                             ## is 
                                                                                                             ## returned 
                                                                                                             ## in 
                                                                                                             ## a 
                                                                                                             ## result, 
                                                                                                             ## then 
                                                                                                             ## pass 
                                                                                                             ## its 
                                                                                                             ## value 
                                                                                                             ## in 
                                                                                                             ## another 
                                                                                                             ## request 
                                                                                                             ## to 
                                                                                                             ## fetch 
                                                                                                             ## more 
                                                                                                             ## entries. 
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJInt(maxResults))
  add(query_402656447, "nextToken", newJString(nextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listApps* = Call_ListApps_402656294(name: "listApps",
                                        meth: HttpMethod.HttpGet,
                                        host: "amplify.amazonaws.com",
                                        route: "/apps",
                                        validator: validate_ListApps_402656295,
                                        base: "/", makeUrl: url_ListApps_402656296,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackendEnvironment_402656521 = ref object of OpenApiRestCall_402656044
proc url_CreateBackendEnvironment_402656523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackendEnvironment_402656522(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Creates a new backend environment for an Amplify App. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656524 = path.getOrDefault("appId")
  valid_402656524 = validateParameter(valid_402656524, JString, required = true,
                                      default = nil)
  if valid_402656524 != nil:
    section.add "appId", valid_402656524
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656533: Call_CreateBackendEnvironment_402656521;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new backend environment for an Amplify App. 
                                                                                         ## 
  let valid = call_402656533.validator(path, query, header, formData, body, _)
  let scheme = call_402656533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656533.makeUrl(scheme.get, call_402656533.host, call_402656533.base,
                                   call_402656533.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656533, uri, valid, _)

proc call*(call_402656534: Call_CreateBackendEnvironment_402656521;
           body: JsonNode; appId: string): Recallable =
  ## createBackendEnvironment
  ##  Creates a new backend environment for an Amplify App. 
  ##   body: JObject (required)
  ##   appId: string (required)
                               ##        :  Unique Id for an Amplify App. 
  var path_402656535 = newJObject()
  var body_402656536 = newJObject()
  if body != nil:
    body_402656536 = body
  add(path_402656535, "appId", newJString(appId))
  result = call_402656534.call(path_402656535, nil, nil, nil, body_402656536)

var createBackendEnvironment* = Call_CreateBackendEnvironment_402656521(
    name: "createBackendEnvironment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_CreateBackendEnvironment_402656522, base: "/",
    makeUrl: url_CreateBackendEnvironment_402656523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackendEnvironments_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListBackendEnvironments_402656493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackendEnvironments_402656492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Lists backend environments for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656505 = path.getOrDefault("appId")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "appId", valid_402656505
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## backen 
                                                                                                            ## environments 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## a 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## backend 
                                                                                                            ## environments. 
  section = newJObject()
  var valid_402656506 = query.getOrDefault("maxResults")
  valid_402656506 = validateParameter(valid_402656506, JInt, required = false,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "maxResults", valid_402656506
  var valid_402656507 = query.getOrDefault("nextToken")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "nextToken", valid_402656507
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
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_ListBackendEnvironments_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Lists backend environments for an Amplify App. 
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_ListBackendEnvironments_402656491;
           body: JsonNode; appId: string; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listBackendEnvironments
  ##  Lists backend environments for an Amplify App. 
  ##   maxResults: int
                                                     ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                                               ## nextToken: string
                                                                                                                               ##            
                                                                                                                               ## :  
                                                                                                                               ## Pagination 
                                                                                                                               ## token. 
                                                                                                                               ## Set 
                                                                                                                               ## to 
                                                                                                                               ## null 
                                                                                                                               ## to 
                                                                                                                               ## start 
                                                                                                                               ## listing 
                                                                                                                               ## backen 
                                                                                                                               ## environments 
                                                                                                                               ## from 
                                                                                                                               ## start. 
                                                                                                                               ## If 
                                                                                                                               ## a 
                                                                                                                               ## non-null 
                                                                                                                               ## pagination 
                                                                                                                               ## token 
                                                                                                                               ## is 
                                                                                                                               ## returned 
                                                                                                                               ## in 
                                                                                                                               ## a 
                                                                                                                               ## result, 
                                                                                                                               ## then 
                                                                                                                               ## pass 
                                                                                                                               ## its 
                                                                                                                               ## value 
                                                                                                                               ## in 
                                                                                                                               ## here 
                                                                                                                               ## to 
                                                                                                                               ## list 
                                                                                                                               ## more 
                                                                                                                               ## backend 
                                                                                                                               ## environments. 
  ##   
                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                           ## appId: string (required)
                                                                                                                                                                           ##        
                                                                                                                                                                           ## :  
                                                                                                                                                                           ## Unique 
                                                                                                                                                                           ## Id 
                                                                                                                                                                           ## for 
                                                                                                                                                                           ## an 
                                                                                                                                                                           ## amplify 
                                                                                                                                                                           ## App. 
  var path_402656518 = newJObject()
  var query_402656519 = newJObject()
  var body_402656520 = newJObject()
  add(query_402656519, "maxResults", newJInt(maxResults))
  add(query_402656519, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656520 = body
  add(path_402656518, "appId", newJString(appId))
  result = call_402656517.call(path_402656518, query_402656519, nil, nil, body_402656520)

var listBackendEnvironments* = Call_ListBackendEnvironments_402656491(
    name: "listBackendEnvironments", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_ListBackendEnvironments_402656492, base: "/",
    makeUrl: url_ListBackendEnvironments_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_402656554 = ref object of OpenApiRestCall_402656044
proc url_CreateBranch_402656556(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBranch_402656555(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a new Branch for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656557 = path.getOrDefault("appId")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "appId", valid_402656557
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_CreateBranch_402656554; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new Branch for an Amplify App. 
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_CreateBranch_402656554; body: JsonNode;
           appId: string): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   body: JObject (required)
  ##   appId: string (required)
                               ##        :  Unique Id for an Amplify App. 
  var path_402656568 = newJObject()
  var body_402656569 = newJObject()
  if body != nil:
    body_402656569 = body
  add(path_402656568, "appId", newJString(appId))
  result = call_402656567.call(path_402656568, nil, nil, nil, body_402656569)

var createBranch* = Call_CreateBranch_402656554(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_402656555,
    base: "/", makeUrl: url_CreateBranch_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_402656537 = ref object of OpenApiRestCall_402656044
proc url_ListBranches_402656539(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBranches_402656538(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Lists branches for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656540 = path.getOrDefault("appId")
  valid_402656540 = validateParameter(valid_402656540, JString, required = true,
                                      default = nil)
  if valid_402656540 != nil:
    section.add "appId", valid_402656540
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## branches 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## a 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## branches. 
  section = newJObject()
  var valid_402656541 = query.getOrDefault("maxResults")
  valid_402656541 = validateParameter(valid_402656541, JInt, required = false,
                                      default = nil)
  if valid_402656541 != nil:
    section.add "maxResults", valid_402656541
  var valid_402656542 = query.getOrDefault("nextToken")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "nextToken", valid_402656542
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
  var valid_402656543 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Security-Token", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Signature")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Signature", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Algorithm", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Date")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Date", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Credential")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Credential", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656550: Call_ListBranches_402656537; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Lists branches for an Amplify App. 
                                                                                         ## 
  let valid = call_402656550.validator(path, query, header, formData, body, _)
  let scheme = call_402656550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656550.makeUrl(scheme.get, call_402656550.host, call_402656550.base,
                                   call_402656550.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656550, uri, valid, _)

proc call*(call_402656551: Call_ListBranches_402656537; appId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   maxResults: int
                                         ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                                   ## nextToken: string
                                                                                                                   ##            
                                                                                                                   ## :  
                                                                                                                   ## Pagination 
                                                                                                                   ## token. 
                                                                                                                   ## Set 
                                                                                                                   ## to 
                                                                                                                   ## null 
                                                                                                                   ## to 
                                                                                                                   ## start 
                                                                                                                   ## listing 
                                                                                                                   ## branches 
                                                                                                                   ## from 
                                                                                                                   ## start. 
                                                                                                                   ## If 
                                                                                                                   ## a 
                                                                                                                   ## non-null 
                                                                                                                   ## pagination 
                                                                                                                   ## token 
                                                                                                                   ## is 
                                                                                                                   ## returned 
                                                                                                                   ## in 
                                                                                                                   ## a 
                                                                                                                   ## result, 
                                                                                                                   ## then 
                                                                                                                   ## pass 
                                                                                                                   ## its 
                                                                                                                   ## value 
                                                                                                                   ## in 
                                                                                                                   ## here 
                                                                                                                   ## to 
                                                                                                                   ## list 
                                                                                                                   ## more 
                                                                                                                   ## branches. 
  ##   
                                                                                                                                ## appId: string (required)
                                                                                                                                ##        
                                                                                                                                ## :  
                                                                                                                                ## Unique 
                                                                                                                                ## Id 
                                                                                                                                ## for 
                                                                                                                                ## an 
                                                                                                                                ## Amplify 
                                                                                                                                ## App. 
  var path_402656552 = newJObject()
  var query_402656553 = newJObject()
  add(query_402656553, "maxResults", newJInt(maxResults))
  add(query_402656553, "nextToken", newJString(nextToken))
  add(path_402656552, "appId", newJString(appId))
  result = call_402656551.call(path_402656552, query_402656553, nil, nil, nil)

var listBranches* = Call_ListBranches_402656537(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_402656538,
    base: "/", makeUrl: url_ListBranches_402656539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_402656570 = ref object of OpenApiRestCall_402656044
proc url_CreateDeployment_402656572(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch, for the Job. 
  ##   
                                                                                     ## appId: JString (required)
                                                                                     ##        
                                                                                     ## :  
                                                                                     ## Unique 
                                                                                     ## Id 
                                                                                     ## for 
                                                                                     ## an 
                                                                                     ## Amplify 
                                                                                     ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656573 = path.getOrDefault("branchName")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true,
                                      default = nil)
  if valid_402656573 != nil:
    section.add "branchName", valid_402656573
  var valid_402656574 = path.getOrDefault("appId")
  valid_402656574 = validateParameter(valid_402656574, JString, required = true,
                                      default = nil)
  if valid_402656574 != nil:
    section.add "appId", valid_402656574
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
  var valid_402656575 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Security-Token", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Signature")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Signature", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Algorithm", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Date")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Date", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Credential")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Credential", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656581
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

proc call*(call_402656583: Call_CreateDeployment_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
                                                                                         ## 
  let valid = call_402656583.validator(path, query, header, formData, body, _)
  let scheme = call_402656583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656583.makeUrl(scheme.get, call_402656583.host, call_402656583.base,
                                   call_402656583.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656583, uri, valid, _)

proc call*(call_402656584: Call_CreateDeployment_402656570; branchName: string;
           body: JsonNode; appId: string): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   
                                                                                         ## branchName: string (required)
                                                                                         ##             
                                                                                         ## :  
                                                                                         ## Name 
                                                                                         ## for 
                                                                                         ## the 
                                                                                         ## branch, 
                                                                                         ## for 
                                                                                         ## the 
                                                                                         ## Job. 
  ##   
                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                            ## appId: string (required)
                                                                                                                            ##        
                                                                                                                            ## :  
                                                                                                                            ## Unique 
                                                                                                                            ## Id 
                                                                                                                            ## for 
                                                                                                                            ## an 
                                                                                                                            ## Amplify 
                                                                                                                            ## App. 
  var path_402656585 = newJObject()
  var body_402656586 = newJObject()
  add(path_402656585, "branchName", newJString(branchName))
  if body != nil:
    body_402656586 = body
  add(path_402656585, "appId", newJString(appId))
  result = call_402656584.call(path_402656585, nil, nil, nil, body_402656586)

var createDeployment* = Call_CreateDeployment_402656570(
    name: "createDeployment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_402656571, base: "/",
    makeUrl: url_CreateDeployment_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_402656604 = ref object of OpenApiRestCall_402656044
proc url_CreateDomainAssociation_402656606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDomainAssociation_402656605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Create a new DomainAssociation on an App 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656607 = path.getOrDefault("appId")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "appId", valid_402656607
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
  var valid_402656608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Security-Token", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Signature")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Signature", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Algorithm", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Date")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Date", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Credential")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Credential", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656614
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

proc call*(call_402656616: Call_CreateDomainAssociation_402656604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Create a new DomainAssociation on an App 
                                                                                         ## 
  let valid = call_402656616.validator(path, query, header, formData, body, _)
  let scheme = call_402656616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656616.makeUrl(scheme.get, call_402656616.host, call_402656616.base,
                                   call_402656616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656616, uri, valid, _)

proc call*(call_402656617: Call_CreateDomainAssociation_402656604;
           body: JsonNode; appId: string): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   body: JObject (required)
  ##   appId: string (required)
                               ##        :  Unique Id for an Amplify App. 
  var path_402656618 = newJObject()
  var body_402656619 = newJObject()
  if body != nil:
    body_402656619 = body
  add(path_402656618, "appId", newJString(appId))
  result = call_402656617.call(path_402656618, nil, nil, nil, body_402656619)

var createDomainAssociation* = Call_CreateDomainAssociation_402656604(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_402656605, base: "/",
    makeUrl: url_CreateDomainAssociation_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_402656587 = ref object of OpenApiRestCall_402656044
proc url_ListDomainAssociations_402656589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainAssociations_402656588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List domains with an app 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656590 = path.getOrDefault("appId")
  valid_402656590 = validateParameter(valid_402656590, JString, required = true,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "appId", valid_402656590
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## Apps 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## projects. 
  section = newJObject()
  var valid_402656591 = query.getOrDefault("maxResults")
  valid_402656591 = validateParameter(valid_402656591, JInt, required = false,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "maxResults", valid_402656591
  var valid_402656592 = query.getOrDefault("nextToken")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "nextToken", valid_402656592
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
  var valid_402656593 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Security-Token", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Signature")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Signature", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Algorithm", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Date")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Date", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Credential")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Credential", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656600: Call_ListDomainAssociations_402656587;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List domains with an app 
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_ListDomainAssociations_402656587; appId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   maxResults: int
                               ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                         ## nextToken: string
                                                                                                         ##            
                                                                                                         ## :  
                                                                                                         ## Pagination 
                                                                                                         ## token. 
                                                                                                         ## Set 
                                                                                                         ## to 
                                                                                                         ## null 
                                                                                                         ## to 
                                                                                                         ## start 
                                                                                                         ## listing 
                                                                                                         ## Apps 
                                                                                                         ## from 
                                                                                                         ## start. 
                                                                                                         ## If 
                                                                                                         ## non-null 
                                                                                                         ## pagination 
                                                                                                         ## token 
                                                                                                         ## is 
                                                                                                         ## returned 
                                                                                                         ## in 
                                                                                                         ## a 
                                                                                                         ## result, 
                                                                                                         ## then 
                                                                                                         ## pass 
                                                                                                         ## its 
                                                                                                         ## value 
                                                                                                         ## in 
                                                                                                         ## here 
                                                                                                         ## to 
                                                                                                         ## list 
                                                                                                         ## more 
                                                                                                         ## projects. 
  ##   
                                                                                                                      ## appId: string (required)
                                                                                                                      ##        
                                                                                                                      ## :  
                                                                                                                      ## Unique 
                                                                                                                      ## Id 
                                                                                                                      ## for 
                                                                                                                      ## an 
                                                                                                                      ## Amplify 
                                                                                                                      ## App. 
  var path_402656602 = newJObject()
  var query_402656603 = newJObject()
  add(query_402656603, "maxResults", newJInt(maxResults))
  add(query_402656603, "nextToken", newJString(nextToken))
  add(path_402656602, "appId", newJString(appId))
  result = call_402656601.call(path_402656602, query_402656603, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_402656587(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_402656588, base: "/",
    makeUrl: url_ListDomainAssociations_402656589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_402656637 = ref object of OpenApiRestCall_402656044
proc url_CreateWebhook_402656639(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateWebhook_402656638(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Create a new webhook on an App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656640 = path.getOrDefault("appId")
  valid_402656640 = validateParameter(valid_402656640, JString, required = true,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "appId", valid_402656640
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
  var valid_402656641 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Security-Token", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Signature")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Signature", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Algorithm", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Date")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Date", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Credential")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Credential", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656647
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

proc call*(call_402656649: Call_CreateWebhook_402656637; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Create a new webhook on an App. 
                                                                                         ## 
  let valid = call_402656649.validator(path, query, header, formData, body, _)
  let scheme = call_402656649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656649.makeUrl(scheme.get, call_402656649.host, call_402656649.base,
                                   call_402656649.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656649, uri, valid, _)

proc call*(call_402656650: Call_CreateWebhook_402656637; body: JsonNode;
           appId: string): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   body: JObject (required)
  ##   appId: string (required)
                               ##        :  Unique Id for an Amplify App. 
  var path_402656651 = newJObject()
  var body_402656652 = newJObject()
  if body != nil:
    body_402656652 = body
  add(path_402656651, "appId", newJString(appId))
  result = call_402656650.call(path_402656651, nil, nil, nil, body_402656652)

var createWebhook* = Call_CreateWebhook_402656637(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_402656638,
    base: "/", makeUrl: url_CreateWebhook_402656639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_402656620 = ref object of OpenApiRestCall_402656044
proc url_ListWebhooks_402656622(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListWebhooks_402656621(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List webhooks with an app. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656623 = path.getOrDefault("appId")
  valid_402656623 = validateParameter(valid_402656623, JString, required = true,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "appId", valid_402656623
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## webhooks 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## webhooks. 
  section = newJObject()
  var valid_402656624 = query.getOrDefault("maxResults")
  valid_402656624 = validateParameter(valid_402656624, JInt, required = false,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "maxResults", valid_402656624
  var valid_402656625 = query.getOrDefault("nextToken")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "nextToken", valid_402656625
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
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656633: Call_ListWebhooks_402656620; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List webhooks with an app. 
                                                                                         ## 
  let valid = call_402656633.validator(path, query, header, formData, body, _)
  let scheme = call_402656633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656633.makeUrl(scheme.get, call_402656633.host, call_402656633.base,
                                   call_402656633.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656633, uri, valid, _)

proc call*(call_402656634: Call_ListWebhooks_402656620; appId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   maxResults: int
                                 ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                           ## nextToken: string
                                                                                                           ##            
                                                                                                           ## :  
                                                                                                           ## Pagination 
                                                                                                           ## token. 
                                                                                                           ## Set 
                                                                                                           ## to 
                                                                                                           ## null 
                                                                                                           ## to 
                                                                                                           ## start 
                                                                                                           ## listing 
                                                                                                           ## webhooks 
                                                                                                           ## from 
                                                                                                           ## start. 
                                                                                                           ## If 
                                                                                                           ## non-null 
                                                                                                           ## pagination 
                                                                                                           ## token 
                                                                                                           ## is 
                                                                                                           ## returned 
                                                                                                           ## in 
                                                                                                           ## a 
                                                                                                           ## result, 
                                                                                                           ## then 
                                                                                                           ## pass 
                                                                                                           ## its 
                                                                                                           ## value 
                                                                                                           ## in 
                                                                                                           ## here 
                                                                                                           ## to 
                                                                                                           ## list 
                                                                                                           ## more 
                                                                                                           ## webhooks. 
  ##   
                                                                                                                        ## appId: string (required)
                                                                                                                        ##        
                                                                                                                        ## :  
                                                                                                                        ## Unique 
                                                                                                                        ## Id 
                                                                                                                        ## for 
                                                                                                                        ## an 
                                                                                                                        ## Amplify 
                                                                                                                        ## App. 
  var path_402656635 = newJObject()
  var query_402656636 = newJObject()
  add(query_402656636, "maxResults", newJInt(maxResults))
  add(query_402656636, "nextToken", newJString(nextToken))
  add(path_402656635, "appId", newJString(appId))
  result = call_402656634.call(path_402656635, query_402656636, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_402656620(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_402656621,
    base: "/", makeUrl: url_ListWebhooks_402656622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_402656667 = ref object of OpenApiRestCall_402656044
proc url_UpdateApp_402656669(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApp_402656668(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Updates an existing Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656670 = path.getOrDefault("appId")
  valid_402656670 = validateParameter(valid_402656670, JString, required = true,
                                      default = nil)
  if valid_402656670 != nil:
    section.add "appId", valid_402656670
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
  var valid_402656671 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Security-Token", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Signature")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Signature", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Algorithm", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Date")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Date", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Credential")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Credential", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656677
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

proc call*(call_402656679: Call_UpdateApp_402656667; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates an existing Amplify App. 
                                                                                         ## 
  let valid = call_402656679.validator(path, query, header, formData, body, _)
  let scheme = call_402656679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656679.makeUrl(scheme.get, call_402656679.host, call_402656679.base,
                                   call_402656679.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656679, uri, valid, _)

proc call*(call_402656680: Call_UpdateApp_402656667; body: JsonNode;
           appId: string): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   body: JObject (required)
  ##   appId: string (required)
                               ##        :  Unique Id for an Amplify App. 
  var path_402656681 = newJObject()
  var body_402656682 = newJObject()
  if body != nil:
    body_402656682 = body
  add(path_402656681, "appId", newJString(appId))
  result = call_402656680.call(path_402656681, nil, nil, nil, body_402656682)

var updateApp* = Call_UpdateApp_402656667(name: "updateApp",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}", validator: validate_UpdateApp_402656668, base: "/",
    makeUrl: url_UpdateApp_402656669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_402656653 = ref object of OpenApiRestCall_402656044
proc url_GetApp_402656655(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApp_402656654(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves an existing Amplify App by appId. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656656 = path.getOrDefault("appId")
  valid_402656656 = validateParameter(valid_402656656, JString, required = true,
                                      default = nil)
  if valid_402656656 != nil:
    section.add "appId", valid_402656656
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
  var valid_402656657 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Security-Token", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Signature")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Signature", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Algorithm", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Date")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Date", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Credential")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Credential", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656664: Call_GetApp_402656653; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
                                                                                         ## 
  let valid = call_402656664.validator(path, query, header, formData, body, _)
  let scheme = call_402656664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656664.makeUrl(scheme.get, call_402656664.host, call_402656664.base,
                                   call_402656664.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656664, uri, valid, _)

proc call*(call_402656665: Call_GetApp_402656653; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
                                                  ##        :  Unique Id for an Amplify App. 
  var path_402656666 = newJObject()
  add(path_402656666, "appId", newJString(appId))
  result = call_402656665.call(path_402656666, nil, nil, nil, nil)

var getApp* = Call_GetApp_402656653(name: "getApp", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_GetApp_402656654,
                                    base: "/", makeUrl: url_GetApp_402656655,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_402656683 = ref object of OpenApiRestCall_402656044
proc url_DeleteApp_402656685(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApp_402656684(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Delete an existing Amplify App by appId. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656686 = path.getOrDefault("appId")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "appId", valid_402656686
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

proc call*(call_402656694: Call_DeleteApp_402656683; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Delete an existing Amplify App by appId. 
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

proc call*(call_402656695: Call_DeleteApp_402656683; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
                                               ##        :  Unique Id for an Amplify App. 
  var path_402656696 = newJObject()
  add(path_402656696, "appId", newJString(appId))
  result = call_402656695.call(path_402656696, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_402656683(name: "deleteApp",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}", validator: validate_DeleteApp_402656684, base: "/",
    makeUrl: url_DeleteApp_402656685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackendEnvironment_402656697 = ref object of OpenApiRestCall_402656044
proc url_GetBackendEnvironment_402656699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path,
         "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/backendenvironments/"),
                 (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackendEnvironment_402656698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves a backend environment for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
                                 ##                  :  Name for the backend environment. 
  ##   
                                                                                          ## appId: JString (required)
                                                                                          ##        
                                                                                          ## :  
                                                                                          ## Unique 
                                                                                          ## Id 
                                                                                          ## for 
                                                                                          ## an 
                                                                                          ## Amplify 
                                                                                          ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `environmentName` field"
  var valid_402656700 = path.getOrDefault("environmentName")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "environmentName", valid_402656700
  var valid_402656701 = path.getOrDefault("appId")
  valid_402656701 = validateParameter(valid_402656701, JString, required = true,
                                      default = nil)
  if valid_402656701 != nil:
    section.add "appId", valid_402656701
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
  var valid_402656702 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Security-Token", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Signature")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Signature", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Algorithm", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Date")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Date", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Credential")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Credential", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656709: Call_GetBackendEnvironment_402656697;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves a backend environment for an Amplify App. 
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_GetBackendEnvironment_402656697;
           environmentName: string; appId: string): Recallable =
  ## getBackendEnvironment
  ##  Retrieves a backend environment for an Amplify App. 
  ##   environmentName: string (required)
                                                          ##                  :  Name for the backend environment. 
  ##   
                                                                                                                   ## appId: string (required)
                                                                                                                   ##        
                                                                                                                   ## :  
                                                                                                                   ## Unique 
                                                                                                                   ## Id 
                                                                                                                   ## for 
                                                                                                                   ## an 
                                                                                                                   ## Amplify 
                                                                                                                   ## App. 
  var path_402656711 = newJObject()
  add(path_402656711, "environmentName", newJString(environmentName))
  add(path_402656711, "appId", newJString(appId))
  result = call_402656710.call(path_402656711, nil, nil, nil, nil)

var getBackendEnvironment* = Call_GetBackendEnvironment_402656697(
    name: "getBackendEnvironment", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_GetBackendEnvironment_402656698, base: "/",
    makeUrl: url_GetBackendEnvironment_402656699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackendEnvironment_402656712 = ref object of OpenApiRestCall_402656044
proc url_DeleteBackendEnvironment_402656714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path,
         "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/backendenvironments/"),
                 (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackendEnvironment_402656713(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Delete backend environment for an Amplify App. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
                                 ##                  :  Name of a backend environment of an Amplify App. 
  ##   
                                                                                                         ## appId: JString (required)
                                                                                                         ##        
                                                                                                         ## :  
                                                                                                         ## Unique 
                                                                                                         ## Id 
                                                                                                         ## of 
                                                                                                         ## an 
                                                                                                         ## Amplify 
                                                                                                         ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `environmentName` field"
  var valid_402656715 = path.getOrDefault("environmentName")
  valid_402656715 = validateParameter(valid_402656715, JString, required = true,
                                      default = nil)
  if valid_402656715 != nil:
    section.add "environmentName", valid_402656715
  var valid_402656716 = path.getOrDefault("appId")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "appId", valid_402656716
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
  var valid_402656717 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Security-Token", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Signature")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Signature", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Algorithm", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Date")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Date", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Credential")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Credential", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656724: Call_DeleteBackendEnvironment_402656712;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Delete backend environment for an Amplify App. 
                                                                                         ## 
  let valid = call_402656724.validator(path, query, header, formData, body, _)
  let scheme = call_402656724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656724.makeUrl(scheme.get, call_402656724.host, call_402656724.base,
                                   call_402656724.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656724, uri, valid, _)

proc call*(call_402656725: Call_DeleteBackendEnvironment_402656712;
           environmentName: string; appId: string): Recallable =
  ## deleteBackendEnvironment
  ##  Delete backend environment for an Amplify App. 
  ##   environmentName: string (required)
                                                     ##                  :  Name of a backend environment of an Amplify App. 
  ##   
                                                                                                                             ## appId: string (required)
                                                                                                                             ##        
                                                                                                                             ## :  
                                                                                                                             ## Unique 
                                                                                                                             ## Id 
                                                                                                                             ## of 
                                                                                                                             ## an 
                                                                                                                             ## Amplify 
                                                                                                                             ## App. 
  var path_402656726 = newJObject()
  add(path_402656726, "environmentName", newJString(environmentName))
  add(path_402656726, "appId", newJString(appId))
  result = call_402656725.call(path_402656726, nil, nil, nil, nil)

var deleteBackendEnvironment* = Call_DeleteBackendEnvironment_402656712(
    name: "deleteBackendEnvironment", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_DeleteBackendEnvironment_402656713, base: "/",
    makeUrl: url_DeleteBackendEnvironment_402656714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_402656742 = ref object of OpenApiRestCall_402656044
proc url_UpdateBranch_402656744(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBranch_402656743(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Updates a branch for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch. 
  ##   appId: JString 
                                                                        ## (required)
                                                                        ##        
                                                                        ## :  
                                                                        ## Unique Id 
                                                                        ## for 
                                                                        ## an 
                                                                        ## Amplify 
                                                                        ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656745 = path.getOrDefault("branchName")
  valid_402656745 = validateParameter(valid_402656745, JString, required = true,
                                      default = nil)
  if valid_402656745 != nil:
    section.add "branchName", valid_402656745
  var valid_402656746 = path.getOrDefault("appId")
  valid_402656746 = validateParameter(valid_402656746, JString, required = true,
                                      default = nil)
  if valid_402656746 != nil:
    section.add "appId", valid_402656746
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
  var valid_402656747 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Security-Token", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Signature")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Signature", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Algorithm", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Date")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Date", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Credential")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Credential", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656753
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

proc call*(call_402656755: Call_UpdateBranch_402656742; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a branch for an Amplify App. 
                                                                                         ## 
  let valid = call_402656755.validator(path, query, header, formData, body, _)
  let scheme = call_402656755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656755.makeUrl(scheme.get, call_402656755.host, call_402656755.base,
                                   call_402656755.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656755, uri, valid, _)

proc call*(call_402656756: Call_UpdateBranch_402656742; branchName: string;
           body: JsonNode; appId: string): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
                                           ##             :  Name for the branch. 
  ##   
                                                                                  ## body: JObject (required)
  ##   
                                                                                                             ## appId: string (required)
                                                                                                             ##        
                                                                                                             ## :  
                                                                                                             ## Unique 
                                                                                                             ## Id 
                                                                                                             ## for 
                                                                                                             ## an 
                                                                                                             ## Amplify 
                                                                                                             ## App. 
  var path_402656757 = newJObject()
  var body_402656758 = newJObject()
  add(path_402656757, "branchName", newJString(branchName))
  if body != nil:
    body_402656758 = body
  add(path_402656757, "appId", newJString(appId))
  result = call_402656756.call(path_402656757, nil, nil, nil, body_402656758)

var updateBranch* = Call_UpdateBranch_402656742(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_402656743, base: "/",
    makeUrl: url_UpdateBranch_402656744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_402656727 = ref object of OpenApiRestCall_402656044
proc url_GetBranch_402656729(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBranch_402656728(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves a branch for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch. 
  ##   appId: JString 
                                                                        ## (required)
                                                                        ##        
                                                                        ## :  
                                                                        ## Unique Id 
                                                                        ## for 
                                                                        ## an 
                                                                        ## Amplify 
                                                                        ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656730 = path.getOrDefault("branchName")
  valid_402656730 = validateParameter(valid_402656730, JString, required = true,
                                      default = nil)
  if valid_402656730 != nil:
    section.add "branchName", valid_402656730
  var valid_402656731 = path.getOrDefault("appId")
  valid_402656731 = validateParameter(valid_402656731, JString, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "appId", valid_402656731
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
  var valid_402656732 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Security-Token", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Signature")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Signature", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Algorithm", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Date")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Date", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Credential")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Credential", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656739: Call_GetBranch_402656727; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves a branch for an Amplify App. 
                                                                                         ## 
  let valid = call_402656739.validator(path, query, header, formData, body, _)
  let scheme = call_402656739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656739.makeUrl(scheme.get, call_402656739.host, call_402656739.base,
                                   call_402656739.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656739, uri, valid, _)

proc call*(call_402656740: Call_GetBranch_402656727; branchName: string;
           appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
                                             ##             :  Name for the branch. 
  ##   
                                                                                    ## appId: string (required)
                                                                                    ##        
                                                                                    ## :  
                                                                                    ## Unique 
                                                                                    ## Id 
                                                                                    ## for 
                                                                                    ## an 
                                                                                    ## Amplify 
                                                                                    ## App. 
  var path_402656741 = newJObject()
  add(path_402656741, "branchName", newJString(branchName))
  add(path_402656741, "appId", newJString(appId))
  result = call_402656740.call(path_402656741, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_402656727(name: "getBranch",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}", validator: validate_GetBranch_402656728,
    base: "/", makeUrl: url_GetBranch_402656729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_402656759 = ref object of OpenApiRestCall_402656044
proc url_DeleteBranch_402656761(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBranch_402656760(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a branch for an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch. 
  ##   appId: JString 
                                                                        ## (required)
                                                                        ##        
                                                                        ## :  
                                                                        ## Unique Id 
                                                                        ## for 
                                                                        ## an 
                                                                        ## Amplify 
                                                                        ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656762 = path.getOrDefault("branchName")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true,
                                      default = nil)
  if valid_402656762 != nil:
    section.add "branchName", valid_402656762
  var valid_402656763 = path.getOrDefault("appId")
  valid_402656763 = validateParameter(valid_402656763, JString, required = true,
                                      default = nil)
  if valid_402656763 != nil:
    section.add "appId", valid_402656763
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
  var valid_402656764 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Security-Token", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Signature")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Signature", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Algorithm", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Date")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Date", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Credential")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Credential", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_DeleteBranch_402656759; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a branch for an Amplify App. 
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_DeleteBranch_402656759; branchName: string;
           appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
                                           ##             :  Name for the branch. 
  ##   
                                                                                  ## appId: string (required)
                                                                                  ##        
                                                                                  ## :  
                                                                                  ## Unique 
                                                                                  ## Id 
                                                                                  ## for 
                                                                                  ## an 
                                                                                  ## Amplify 
                                                                                  ## App. 
  var path_402656773 = newJObject()
  add(path_402656773, "branchName", newJString(branchName))
  add(path_402656773, "appId", newJString(appId))
  result = call_402656772.call(path_402656773, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_402656759(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_402656760, base: "/",
    makeUrl: url_DeleteBranch_402656761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_402656789 = ref object of OpenApiRestCall_402656044
proc url_UpdateDomainAssociation_402656791(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/domains/"),
                 (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainAssociation_402656790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Create a new DomainAssociation on an App 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
                                 ##             :  Name of the domain. 
  ##   appId: JString 
                                                                       ## (required)
                                                                       ##        
                                                                       ## :  
                                                                       ## Unique Id for an 
                                                                       ## Amplify 
                                                                       ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `domainName` field"
  var valid_402656792 = path.getOrDefault("domainName")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true,
                                      default = nil)
  if valid_402656792 != nil:
    section.add "domainName", valid_402656792
  var valid_402656793 = path.getOrDefault("appId")
  valid_402656793 = validateParameter(valid_402656793, JString, required = true,
                                      default = nil)
  if valid_402656793 != nil:
    section.add "appId", valid_402656793
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
  var valid_402656794 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Security-Token", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Signature")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Signature", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Algorithm", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Date")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Date", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Credential")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Credential", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656800
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

proc call*(call_402656802: Call_UpdateDomainAssociation_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Create a new DomainAssociation on an App 
                                                                                         ## 
  let valid = call_402656802.validator(path, query, header, formData, body, _)
  let scheme = call_402656802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656802.makeUrl(scheme.get, call_402656802.host, call_402656802.base,
                                   call_402656802.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656802, uri, valid, _)

proc call*(call_402656803: Call_UpdateDomainAssociation_402656789;
           domainName: string; body: JsonNode; appId: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   domainName: string (required)
                                               ##             :  Name of the domain. 
  ##   
                                                                                     ## body: JObject (required)
  ##   
                                                                                                                ## appId: string (required)
                                                                                                                ##        
                                                                                                                ## :  
                                                                                                                ## Unique 
                                                                                                                ## Id 
                                                                                                                ## for 
                                                                                                                ## an 
                                                                                                                ## Amplify 
                                                                                                                ## App. 
  var path_402656804 = newJObject()
  var body_402656805 = newJObject()
  add(path_402656804, "domainName", newJString(domainName))
  if body != nil:
    body_402656805 = body
  add(path_402656804, "appId", newJString(appId))
  result = call_402656803.call(path_402656804, nil, nil, nil, body_402656805)

var updateDomainAssociation* = Call_UpdateDomainAssociation_402656789(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_402656790, base: "/",
    makeUrl: url_UpdateDomainAssociation_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_402656774 = ref object of OpenApiRestCall_402656044
proc url_GetDomainAssociation_402656776(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/domains/"),
                 (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainAssociation_402656775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
                                 ##             :  Name of the domain. 
  ##   appId: JString 
                                                                       ## (required)
                                                                       ##        
                                                                       ## :  
                                                                       ## Unique Id for an 
                                                                       ## Amplify 
                                                                       ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `domainName` field"
  var valid_402656777 = path.getOrDefault("domainName")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true,
                                      default = nil)
  if valid_402656777 != nil:
    section.add "domainName", valid_402656777
  var valid_402656778 = path.getOrDefault("appId")
  valid_402656778 = validateParameter(valid_402656778, JString, required = true,
                                      default = nil)
  if valid_402656778 != nil:
    section.add "appId", valid_402656778
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
  var valid_402656779 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Security-Token", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Signature")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Signature", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Algorithm", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Date")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Date", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Credential")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Credential", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_GetDomainAssociation_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_GetDomainAssociation_402656774;
           domainName: string; appId: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   
                                                                         ## domainName: string (required)
                                                                         ##             
                                                                         ## :  
                                                                         ## Name 
                                                                         ## of 
                                                                         ## the 
                                                                         ## domain. 
  ##   
                                                                                    ## appId: string (required)
                                                                                    ##        
                                                                                    ## :  
                                                                                    ## Unique 
                                                                                    ## Id 
                                                                                    ## for 
                                                                                    ## an 
                                                                                    ## Amplify 
                                                                                    ## App. 
  var path_402656788 = newJObject()
  add(path_402656788, "domainName", newJString(domainName))
  add(path_402656788, "appId", newJString(appId))
  result = call_402656787.call(path_402656788, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_402656774(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_402656775, base: "/",
    makeUrl: url_GetDomainAssociation_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_402656806 = ref object of OpenApiRestCall_402656044
proc url_DeleteDomainAssociation_402656808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/domains/"),
                 (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainAssociation_402656807(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a DomainAssociation. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
                                 ##             :  Name of the domain. 
  ##   appId: JString 
                                                                       ## (required)
                                                                       ##        
                                                                       ## :  
                                                                       ## Unique Id for an 
                                                                       ## Amplify 
                                                                       ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `domainName` field"
  var valid_402656809 = path.getOrDefault("domainName")
  valid_402656809 = validateParameter(valid_402656809, JString, required = true,
                                      default = nil)
  if valid_402656809 != nil:
    section.add "domainName", valid_402656809
  var valid_402656810 = path.getOrDefault("appId")
  valid_402656810 = validateParameter(valid_402656810, JString, required = true,
                                      default = nil)
  if valid_402656810 != nil:
    section.add "appId", valid_402656810
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
  var valid_402656811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Security-Token", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Signature")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Signature", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Algorithm", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Date")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Date", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Credential")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Credential", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656818: Call_DeleteDomainAssociation_402656806;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a DomainAssociation. 
                                                                                         ## 
  let valid = call_402656818.validator(path, query, header, formData, body, _)
  let scheme = call_402656818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656818.makeUrl(scheme.get, call_402656818.host, call_402656818.base,
                                   call_402656818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656818, uri, valid, _)

proc call*(call_402656819: Call_DeleteDomainAssociation_402656806;
           domainName: string; appId: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   domainName: string (required)
                                   ##             :  Name of the domain. 
  ##   appId: string 
                                                                         ## (required)
                                                                         ##        
                                                                         ## :  
                                                                         ## Unique 
                                                                         ## Id 
                                                                         ## for 
                                                                         ## an 
                                                                         ## Amplify 
                                                                         ## App. 
  var path_402656820 = newJObject()
  add(path_402656820, "domainName", newJString(domainName))
  add(path_402656820, "appId", newJString(appId))
  result = call_402656819.call(path_402656820, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_402656806(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_402656807, base: "/",
    makeUrl: url_DeleteDomainAssociation_402656808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_402656821 = ref object of OpenApiRestCall_402656044
proc url_GetJob_402656823(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_402656822(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Get a job for a branch, part of an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
                                                                     ##             :  Name for the branch, for the Job. 
  ##   
                                                                                                                         ## appId: JString (required)
                                                                                                                         ##        
                                                                                                                         ## :  
                                                                                                                         ## Unique 
                                                                                                                         ## Id 
                                                                                                                         ## for 
                                                                                                                         ## an 
                                                                                                                         ## Amplify 
                                                                                                                         ## App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402656824 = path.getOrDefault("jobId")
  valid_402656824 = validateParameter(valid_402656824, JString, required = true,
                                      default = nil)
  if valid_402656824 != nil:
    section.add "jobId", valid_402656824
  var valid_402656825 = path.getOrDefault("branchName")
  valid_402656825 = validateParameter(valid_402656825, JString, required = true,
                                      default = nil)
  if valid_402656825 != nil:
    section.add "branchName", valid_402656825
  var valid_402656826 = path.getOrDefault("appId")
  valid_402656826 = validateParameter(valid_402656826, JString, required = true,
                                      default = nil)
  if valid_402656826 != nil:
    section.add "appId", valid_402656826
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
  var valid_402656827 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Security-Token", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Signature")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Signature", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Algorithm", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Date")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Date", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Credential")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Credential", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656834: Call_GetJob_402656821; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
                                                                                         ## 
  let valid = call_402656834.validator(path, query, header, formData, body, _)
  let scheme = call_402656834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656834.makeUrl(scheme.get, call_402656834.host, call_402656834.base,
                                   call_402656834.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656834, uri, valid, _)

proc call*(call_402656835: Call_GetJob_402656821; jobId: string;
           branchName: string; appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
                                                      ##        :  Unique Id for the Job. 
  ##   
                                                                                          ## branchName: string (required)
                                                                                          ##             
                                                                                          ## :  
                                                                                          ## Name 
                                                                                          ## for 
                                                                                          ## the 
                                                                                          ## branch, 
                                                                                          ## for 
                                                                                          ## the 
                                                                                          ## Job. 
  ##   
                                                                                                  ## appId: string (required)
                                                                                                  ##        
                                                                                                  ## :  
                                                                                                  ## Unique 
                                                                                                  ## Id 
                                                                                                  ## for 
                                                                                                  ## an 
                                                                                                  ## Amplify 
                                                                                                  ## App. 
  var path_402656836 = newJObject()
  add(path_402656836, "jobId", newJString(jobId))
  add(path_402656836, "branchName", newJString(branchName))
  add(path_402656836, "appId", newJString(appId))
  result = call_402656835.call(path_402656836, nil, nil, nil, nil)

var getJob* = Call_GetJob_402656821(name: "getJob", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_GetJob_402656822,
                                    base: "/", makeUrl: url_GetJob_402656823,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_402656837 = ref object of OpenApiRestCall_402656044
proc url_DeleteJob_402656839(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJob_402656838(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
                                                                     ##             :  Name for the branch, for the Job. 
  ##   
                                                                                                                         ## appId: JString (required)
                                                                                                                         ##        
                                                                                                                         ## :  
                                                                                                                         ## Unique 
                                                                                                                         ## Id 
                                                                                                                         ## for 
                                                                                                                         ## an 
                                                                                                                         ## Amplify 
                                                                                                                         ## App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402656840 = path.getOrDefault("jobId")
  valid_402656840 = validateParameter(valid_402656840, JString, required = true,
                                      default = nil)
  if valid_402656840 != nil:
    section.add "jobId", valid_402656840
  var valid_402656841 = path.getOrDefault("branchName")
  valid_402656841 = validateParameter(valid_402656841, JString, required = true,
                                      default = nil)
  if valid_402656841 != nil:
    section.add "branchName", valid_402656841
  var valid_402656842 = path.getOrDefault("appId")
  valid_402656842 = validateParameter(valid_402656842, JString, required = true,
                                      default = nil)
  if valid_402656842 != nil:
    section.add "appId", valid_402656842
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
  var valid_402656843 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Security-Token", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Signature")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Signature", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Algorithm", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Date")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Date", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Credential")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Credential", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656850: Call_DeleteJob_402656837; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
                                                                                         ## 
  let valid = call_402656850.validator(path, query, header, formData, body, _)
  let scheme = call_402656850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656850.makeUrl(scheme.get, call_402656850.host, call_402656850.base,
                                   call_402656850.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656850, uri, valid, _)

proc call*(call_402656851: Call_DeleteJob_402656837; jobId: string;
           branchName: string; appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
                                                                ##        :  Unique Id for the Job. 
  ##   
                                                                                                    ## branchName: string (required)
                                                                                                    ##             
                                                                                                    ## :  
                                                                                                    ## Name 
                                                                                                    ## for 
                                                                                                    ## the 
                                                                                                    ## branch, 
                                                                                                    ## for 
                                                                                                    ## the 
                                                                                                    ## Job. 
  ##   
                                                                                                            ## appId: string (required)
                                                                                                            ##        
                                                                                                            ## :  
                                                                                                            ## Unique 
                                                                                                            ## Id 
                                                                                                            ## for 
                                                                                                            ## an 
                                                                                                            ## Amplify 
                                                                                                            ## App. 
  var path_402656852 = newJObject()
  add(path_402656852, "jobId", newJString(jobId))
  add(path_402656852, "branchName", newJString(branchName))
  add(path_402656852, "appId", newJString(appId))
  result = call_402656851.call(path_402656852, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_402656837(name: "deleteJob",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
    validator: validate_DeleteJob_402656838, base: "/", makeUrl: url_DeleteJob_402656839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_402656867 = ref object of OpenApiRestCall_402656044
proc url_UpdateWebhook_402656869(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
                 (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateWebhook_402656868(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Update a webhook. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
                                 ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `webhookId` field"
  var valid_402656870 = path.getOrDefault("webhookId")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true,
                                      default = nil)
  if valid_402656870 != nil:
    section.add "webhookId", valid_402656870
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
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
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

proc call*(call_402656879: Call_UpdateWebhook_402656867; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Update a webhook. 
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_UpdateWebhook_402656867; webhookId: string;
           body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
                        ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_402656881 = newJObject()
  var body_402656882 = newJObject()
  add(path_402656881, "webhookId", newJString(webhookId))
  if body != nil:
    body_402656882 = body
  result = call_402656880.call(path_402656881, nil, nil, nil, body_402656882)

var updateWebhook* = Call_UpdateWebhook_402656867(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_402656868,
    base: "/", makeUrl: url_UpdateWebhook_402656869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_402656853 = ref object of OpenApiRestCall_402656044
proc url_GetWebhook_402656855(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
                 (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetWebhook_402656854(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves webhook info that corresponds to a webhookId. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
                                 ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `webhookId` field"
  var valid_402656856 = path.getOrDefault("webhookId")
  valid_402656856 = validateParameter(valid_402656856, JString, required = true,
                                      default = nil)
  if valid_402656856 != nil:
    section.add "webhookId", valid_402656856
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
  var valid_402656857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Security-Token", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Signature")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Signature", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Algorithm", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Date")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Date", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Credential")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Credential", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656864: Call_GetWebhook_402656853; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
                                                                                         ## 
  let valid = call_402656864.validator(path, query, header, formData, body, _)
  let scheme = call_402656864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656864.makeUrl(scheme.get, call_402656864.host, call_402656864.base,
                                   call_402656864.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656864, uri, valid, _)

proc call*(call_402656865: Call_GetWebhook_402656853; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
                                                              ##            :  Unique Id for a webhook. 
  var path_402656866 = newJObject()
  add(path_402656866, "webhookId", newJString(webhookId))
  result = call_402656865.call(path_402656866, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_402656853(name: "getWebhook",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_GetWebhook_402656854,
    base: "/", makeUrl: url_GetWebhook_402656855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_402656883 = ref object of OpenApiRestCall_402656044
proc url_DeleteWebhook_402656885(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
                 (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteWebhook_402656884(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a webhook. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
                                 ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `webhookId` field"
  var valid_402656886 = path.getOrDefault("webhookId")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "webhookId", valid_402656886
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
  var valid_402656887 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Security-Token", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Signature")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Signature", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Algorithm", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Date")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Date", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Credential")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Credential", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656894: Call_DeleteWebhook_402656883; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a webhook. 
                                                                                         ## 
  let valid = call_402656894.validator(path, query, header, formData, body, _)
  let scheme = call_402656894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656894.makeUrl(scheme.get, call_402656894.host, call_402656894.base,
                                   call_402656894.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656894, uri, valid, _)

proc call*(call_402656895: Call_DeleteWebhook_402656883; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
                         ##            :  Unique Id for a webhook. 
  var path_402656896 = newJObject()
  add(path_402656896, "webhookId", newJString(webhookId))
  result = call_402656895.call(path_402656896, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_402656883(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_402656884,
    base: "/", makeUrl: url_DeleteWebhook_402656885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_402656897 = ref object of OpenApiRestCall_402656044
proc url_GenerateAccessLogs_402656899(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/accesslogs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GenerateAccessLogs_402656898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
                                 ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_402656900 = path.getOrDefault("appId")
  valid_402656900 = validateParameter(valid_402656900, JString, required = true,
                                      default = nil)
  if valid_402656900 != nil:
    section.add "appId", valid_402656900
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
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656907
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

proc call*(call_402656909: Call_GenerateAccessLogs_402656897;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
                                                                                         ## 
  let valid = call_402656909.validator(path, query, header, formData, body, _)
  let scheme = call_402656909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656909.makeUrl(scheme.get, call_402656909.host, call_402656909.base,
                                   call_402656909.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656909, uri, valid, _)

proc call*(call_402656910: Call_GenerateAccessLogs_402656897; body: JsonNode;
           appId: string): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   
                                                                                   ## body: JObject (required)
  ##   
                                                                                                              ## appId: string (required)
                                                                                                              ##        
                                                                                                              ## :  
                                                                                                              ## Unique 
                                                                                                              ## Id 
                                                                                                              ## for 
                                                                                                              ## an 
                                                                                                              ## Amplify 
                                                                                                              ## App. 
  var path_402656911 = newJObject()
  var body_402656912 = newJObject()
  if body != nil:
    body_402656912 = body
  add(path_402656911, "appId", newJString(appId))
  result = call_402656910.call(path_402656911, nil, nil, nil, body_402656912)

var generateAccessLogs* = Call_GenerateAccessLogs_402656897(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_402656898, base: "/",
    makeUrl: url_GenerateAccessLogs_402656899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_402656913 = ref object of OpenApiRestCall_402656044
proc url_GetArtifactUrl_402656915(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "artifactId" in path, "`artifactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/artifacts/"),
                 (kind: VariableSegment, value: "artifactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetArtifactUrl_402656914(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Retrieves artifact info that corresponds to a artifactId. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   artifactId: JString (required)
                                 ##             :  Unique Id for a artifact. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `artifactId` field"
  var valid_402656916 = path.getOrDefault("artifactId")
  valid_402656916 = validateParameter(valid_402656916, JString, required = true,
                                      default = nil)
  if valid_402656916 != nil:
    section.add "artifactId", valid_402656916
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

proc call*(call_402656924: Call_GetArtifactUrl_402656913; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
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

proc call*(call_402656925: Call_GetArtifactUrl_402656913; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
                                                                ##             :  Unique Id for a artifact. 
  var path_402656926 = newJObject()
  add(path_402656926, "artifactId", newJString(artifactId))
  result = call_402656925.call(path_402656926, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_402656913(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_402656914,
    base: "/", makeUrl: url_GetArtifactUrl_402656915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_402656927 = ref object of OpenApiRestCall_402656044
proc url_ListArtifacts_402656929(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId"),
                 (kind: ConstantSegment, value: "/artifacts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListArtifacts_402656928(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        :  Unique Id for an Job. 
  ##   branchName: JString (required)
                                                                    ##             :  Name for a branch, part of an Amplify App. 
  ##   
                                                                                                                                 ## appId: JString (required)
                                                                                                                                 ##        
                                                                                                                                 ## :  
                                                                                                                                 ## Unique 
                                                                                                                                 ## Id 
                                                                                                                                 ## for 
                                                                                                                                 ## an 
                                                                                                                                 ## Amplify 
                                                                                                                                 ## App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402656930 = path.getOrDefault("jobId")
  valid_402656930 = validateParameter(valid_402656930, JString, required = true,
                                      default = nil)
  if valid_402656930 != nil:
    section.add "jobId", valid_402656930
  var valid_402656931 = path.getOrDefault("branchName")
  valid_402656931 = validateParameter(valid_402656931, JString, required = true,
                                      default = nil)
  if valid_402656931 != nil:
    section.add "branchName", valid_402656931
  var valid_402656932 = path.getOrDefault("appId")
  valid_402656932 = validateParameter(valid_402656932, JString, required = true,
                                      default = nil)
  if valid_402656932 != nil:
    section.add "appId", valid_402656932
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## artifacts 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## artifacts. 
  section = newJObject()
  var valid_402656933 = query.getOrDefault("maxResults")
  valid_402656933 = validateParameter(valid_402656933, JInt, required = false,
                                      default = nil)
  if valid_402656933 != nil:
    section.add "maxResults", valid_402656933
  var valid_402656934 = query.getOrDefault("nextToken")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "nextToken", valid_402656934
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
  var valid_402656935 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Security-Token", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Signature")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Signature", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Algorithm", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Date")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Date", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Credential")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Credential", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656942: Call_ListArtifacts_402656927; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
                                                                                         ## 
  let valid = call_402656942.validator(path, query, header, formData, body, _)
  let scheme = call_402656942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656942.makeUrl(scheme.get, call_402656942.host, call_402656942.base,
                                   call_402656942.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656942, uri, valid, _)

proc call*(call_402656943: Call_ListArtifacts_402656927; jobId: string;
           branchName: string; appId: string; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listArtifacts
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ##   jobId: string 
                                                                        ## (required)
                                                                        ##        
                                                                        ## :  
                                                                        ## Unique Id 
                                                                        ## for 
                                                                        ## an 
                                                                        ## Job. 
  ##   
                                                                                ## maxResults: int
                                                                                ##             
                                                                                ## :  
                                                                                ## Maximum 
                                                                                ## number 
                                                                                ## of 
                                                                                ## records 
                                                                                ## to 
                                                                                ## list 
                                                                                ## in 
                                                                                ## a 
                                                                                ## single 
                                                                                ## response. 
  ##   
                                                                                             ## branchName: string (required)
                                                                                             ##             
                                                                                             ## :  
                                                                                             ## Name 
                                                                                             ## for 
                                                                                             ## a 
                                                                                             ## branch, 
                                                                                             ## part 
                                                                                             ## of 
                                                                                             ## an 
                                                                                             ## Amplify 
                                                                                             ## App. 
  ##   
                                                                                                     ## nextToken: string
                                                                                                     ##            
                                                                                                     ## :  
                                                                                                     ## Pagination 
                                                                                                     ## token. 
                                                                                                     ## Set 
                                                                                                     ## to 
                                                                                                     ## null 
                                                                                                     ## to 
                                                                                                     ## start 
                                                                                                     ## listing 
                                                                                                     ## artifacts 
                                                                                                     ## from 
                                                                                                     ## start. 
                                                                                                     ## If 
                                                                                                     ## non-null 
                                                                                                     ## pagination 
                                                                                                     ## token 
                                                                                                     ## is 
                                                                                                     ## returned 
                                                                                                     ## in 
                                                                                                     ## a 
                                                                                                     ## result, 
                                                                                                     ## then 
                                                                                                     ## pass 
                                                                                                     ## its 
                                                                                                     ## value 
                                                                                                     ## in 
                                                                                                     ## here 
                                                                                                     ## to 
                                                                                                     ## list 
                                                                                                     ## more 
                                                                                                     ## artifacts. 
  ##   
                                                                                                                   ## appId: string (required)
                                                                                                                   ##        
                                                                                                                   ## :  
                                                                                                                   ## Unique 
                                                                                                                   ## Id 
                                                                                                                   ## for 
                                                                                                                   ## an 
                                                                                                                   ## Amplify 
                                                                                                                   ## App. 
  var path_402656944 = newJObject()
  var query_402656945 = newJObject()
  add(path_402656944, "jobId", newJString(jobId))
  add(query_402656945, "maxResults", newJInt(maxResults))
  add(path_402656944, "branchName", newJString(branchName))
  add(query_402656945, "nextToken", newJString(nextToken))
  add(path_402656944, "appId", newJString(appId))
  result = call_402656943.call(path_402656944, query_402656945, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_402656927(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_402656928, base: "/",
    makeUrl: url_ListArtifacts_402656929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_402656964 = ref object of OpenApiRestCall_402656044
proc url_StartJob_402656966(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_402656965(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Starts a new job for a branch, part of an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch, for the Job. 
  ##   
                                                                                     ## appId: JString (required)
                                                                                     ##        
                                                                                     ## :  
                                                                                     ## Unique 
                                                                                     ## Id 
                                                                                     ## for 
                                                                                     ## an 
                                                                                     ## Amplify 
                                                                                     ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656967 = path.getOrDefault("branchName")
  valid_402656967 = validateParameter(valid_402656967, JString, required = true,
                                      default = nil)
  if valid_402656967 != nil:
    section.add "branchName", valid_402656967
  var valid_402656968 = path.getOrDefault("appId")
  valid_402656968 = validateParameter(valid_402656968, JString, required = true,
                                      default = nil)
  if valid_402656968 != nil:
    section.add "appId", valid_402656968
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
  var valid_402656969 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Security-Token", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Signature")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Signature", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Algorithm", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Date")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Date", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Credential")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Credential", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656975
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

proc call*(call_402656977: Call_StartJob_402656964; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
                                                                                         ## 
  let valid = call_402656977.validator(path, query, header, formData, body, _)
  let scheme = call_402656977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656977.makeUrl(scheme.get, call_402656977.host, call_402656977.base,
                                   call_402656977.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656977, uri, valid, _)

proc call*(call_402656978: Call_StartJob_402656964; branchName: string;
           body: JsonNode; appId: string): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
                                                             ##             :  Name for the branch, for the Job. 
  ##   
                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                            ## appId: string (required)
                                                                                                                                            ##        
                                                                                                                                            ## :  
                                                                                                                                            ## Unique 
                                                                                                                                            ## Id 
                                                                                                                                            ## for 
                                                                                                                                            ## an 
                                                                                                                                            ## Amplify 
                                                                                                                                            ## App. 
  var path_402656979 = newJObject()
  var body_402656980 = newJObject()
  add(path_402656979, "branchName", newJString(branchName))
  if body != nil:
    body_402656980 = body
  add(path_402656979, "appId", newJString(appId))
  result = call_402656978.call(path_402656979, nil, nil, nil, body_402656980)

var startJob* = Call_StartJob_402656964(name: "startJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                        validator: validate_StartJob_402656965,
                                        base: "/", makeUrl: url_StartJob_402656966,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_402656946 = ref object of OpenApiRestCall_402656044
proc url_ListJobs_402656948(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobs_402656947(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List Jobs for a branch, part of an Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for a branch. 
  ##   appId: JString (required)
                                                                      ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402656949 = path.getOrDefault("branchName")
  valid_402656949 = validateParameter(valid_402656949, JString, required = true,
                                      default = nil)
  if valid_402656949 != nil:
    section.add "branchName", valid_402656949
  var valid_402656950 = path.getOrDefault("appId")
  valid_402656950 = validateParameter(valid_402656950, JString, required = true,
                                      default = nil)
  if valid_402656950 != nil:
    section.add "appId", valid_402656950
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Pagination 
                                                                                                            ## token. 
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## steps 
                                                                                                            ## from 
                                                                                                            ## start. 
                                                                                                            ## If 
                                                                                                            ## a 
                                                                                                            ## non-null 
                                                                                                            ## pagination 
                                                                                                            ## token 
                                                                                                            ## is 
                                                                                                            ## returned 
                                                                                                            ## in 
                                                                                                            ## a 
                                                                                                            ## result, 
                                                                                                            ## then 
                                                                                                            ## pass 
                                                                                                            ## its 
                                                                                                            ## value 
                                                                                                            ## in 
                                                                                                            ## here 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## steps. 
  section = newJObject()
  var valid_402656951 = query.getOrDefault("maxResults")
  valid_402656951 = validateParameter(valid_402656951, JInt, required = false,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "maxResults", valid_402656951
  var valid_402656952 = query.getOrDefault("nextToken")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "nextToken", valid_402656952
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
  var valid_402656953 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Security-Token", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Signature")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Signature", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Algorithm", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Date")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Date", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Credential")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Credential", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656960: Call_ListJobs_402656946; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
                                                                                         ## 
  let valid = call_402656960.validator(path, query, header, formData, body, _)
  let scheme = call_402656960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656960.makeUrl(scheme.get, call_402656960.host, call_402656960.base,
                                   call_402656960.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656960, uri, valid, _)

proc call*(call_402656961: Call_ListJobs_402656946; branchName: string;
           appId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listJobs
  ##  List Jobs for a branch, part of an Amplify App. 
  ##   maxResults: int
                                                      ##             :  Maximum number of records to list in a single response. 
  ##   
                                                                                                                                ## branchName: string (required)
                                                                                                                                ##             
                                                                                                                                ## :  
                                                                                                                                ## Name 
                                                                                                                                ## for 
                                                                                                                                ## a 
                                                                                                                                ## branch. 
  ##   
                                                                                                                                           ## nextToken: string
                                                                                                                                           ##            
                                                                                                                                           ## :  
                                                                                                                                           ## Pagination 
                                                                                                                                           ## token. 
                                                                                                                                           ## Set 
                                                                                                                                           ## to 
                                                                                                                                           ## null 
                                                                                                                                           ## to 
                                                                                                                                           ## start 
                                                                                                                                           ## listing 
                                                                                                                                           ## steps 
                                                                                                                                           ## from 
                                                                                                                                           ## start. 
                                                                                                                                           ## If 
                                                                                                                                           ## a 
                                                                                                                                           ## non-null 
                                                                                                                                           ## pagination 
                                                                                                                                           ## token 
                                                                                                                                           ## is 
                                                                                                                                           ## returned 
                                                                                                                                           ## in 
                                                                                                                                           ## a 
                                                                                                                                           ## result, 
                                                                                                                                           ## then 
                                                                                                                                           ## pass 
                                                                                                                                           ## its 
                                                                                                                                           ## value 
                                                                                                                                           ## in 
                                                                                                                                           ## here 
                                                                                                                                           ## to 
                                                                                                                                           ## list 
                                                                                                                                           ## more 
                                                                                                                                           ## steps. 
  ##   
                                                                                                                                                     ## appId: string (required)
                                                                                                                                                     ##        
                                                                                                                                                     ## :  
                                                                                                                                                     ## Unique 
                                                                                                                                                     ## Id 
                                                                                                                                                     ## for 
                                                                                                                                                     ## an 
                                                                                                                                                     ## Amplify 
                                                                                                                                                     ## App. 
  var path_402656962 = newJObject()
  var query_402656963 = newJObject()
  add(query_402656963, "maxResults", newJInt(maxResults))
  add(path_402656962, "branchName", newJString(branchName))
  add(query_402656963, "nextToken", newJString(nextToken))
  add(path_402656962, "appId", newJString(appId))
  result = call_402656961.call(path_402656962, query_402656963, nil, nil, nil)

var listJobs* = Call_ListJobs_402656946(name: "listJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                        validator: validate_ListJobs_402656947,
                                        base: "/", makeUrl: url_ListJobs_402656948,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656995 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656997(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656996(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Tag resource with tag key and value. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  Resource arn used to tag resource. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656998 = path.getOrDefault("resourceArn")
  valid_402656998 = validateParameter(valid_402656998, JString, required = true,
                                      default = nil)
  if valid_402656998 != nil:
    section.add "resourceArn", valid_402656998
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
  var valid_402656999 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Security-Token", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Signature")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Signature", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Algorithm", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Date")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Date", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Credential")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Credential", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657005
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

proc call*(call_402657007: Call_TagResource_402656995; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Tag resource with tag key and value. 
                                                                                         ## 
  let valid = call_402657007.validator(path, query, header, formData, body, _)
  let scheme = call_402657007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657007.makeUrl(scheme.get, call_402657007.host, call_402657007.base,
                                   call_402657007.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657007, uri, valid, _)

proc call*(call_402657008: Call_TagResource_402656995; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              :  Resource arn used to tag resource. 
  var path_402657009 = newJObject()
  var body_402657010 = newJObject()
  if body != nil:
    body_402657010 = body
  add(path_402657009, "resourceArn", newJString(resourceArn))
  result = call_402657008.call(path_402657009, nil, nil, nil, body_402657010)

var tagResource* = Call_TagResource_402656995(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656996,
    base: "/", makeUrl: url_TagResource_402656997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656981 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656983(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List tags for resource. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  Resource arn used to list tags. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656984 = path.getOrDefault("resourceArn")
  valid_402656984 = validateParameter(valid_402656984, JString, required = true,
                                      default = nil)
  if valid_402656984 != nil:
    section.add "resourceArn", valid_402656984
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
  var valid_402656985 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Security-Token", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Signature")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Signature", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Algorithm", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Date")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Date", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Credential")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Credential", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656992: Call_ListTagsForResource_402656981;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List tags for resource. 
                                                                                         ## 
  let valid = call_402656992.validator(path, query, header, formData, body, _)
  let scheme = call_402656992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656992.makeUrl(scheme.get, call_402656992.host, call_402656992.base,
                                   call_402656992.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656992, uri, valid, _)

proc call*(call_402656993: Call_ListTagsForResource_402656981;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
                              ##              :  Resource arn used to list tags. 
  var path_402656994 = newJObject()
  add(path_402656994, "resourceArn", newJString(resourceArn))
  result = call_402656993.call(path_402656994, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656981(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656982, base: "/",
    makeUrl: url_ListTagsForResource_402656983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_402657011 = ref object of OpenApiRestCall_402656044
proc url_StartDeployment_402657013(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/deployments/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_402657012(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
                                 ##             :  Name for the branch, for the Job. 
  ##   
                                                                                     ## appId: JString (required)
                                                                                     ##        
                                                                                     ## :  
                                                                                     ## Unique 
                                                                                     ## Id 
                                                                                     ## for 
                                                                                     ## an 
                                                                                     ## Amplify 
                                                                                     ## App. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `branchName` field"
  var valid_402657014 = path.getOrDefault("branchName")
  valid_402657014 = validateParameter(valid_402657014, JString, required = true,
                                      default = nil)
  if valid_402657014 != nil:
    section.add "branchName", valid_402657014
  var valid_402657015 = path.getOrDefault("appId")
  valid_402657015 = validateParameter(valid_402657015, JString, required = true,
                                      default = nil)
  if valid_402657015 != nil:
    section.add "appId", valid_402657015
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
  var valid_402657016 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Security-Token", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Signature")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Signature", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Algorithm", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Date")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Date", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Credential")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Credential", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657022
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

proc call*(call_402657024: Call_StartDeployment_402657011; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
                                                                                         ## 
  let valid = call_402657024.validator(path, query, header, formData, body, _)
  let scheme = call_402657024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657024.makeUrl(scheme.get, call_402657024.host, call_402657024.base,
                                   call_402657024.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657024, uri, valid, _)

proc call*(call_402657025: Call_StartDeployment_402657011; branchName: string;
           body: JsonNode; appId: string): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   
                                                                                        ## branchName: string (required)
                                                                                        ##             
                                                                                        ## :  
                                                                                        ## Name 
                                                                                        ## for 
                                                                                        ## the 
                                                                                        ## branch, 
                                                                                        ## for 
                                                                                        ## the 
                                                                                        ## Job. 
  ##   
                                                                                                ## body: JObject (required)
  ##   
                                                                                                                           ## appId: string (required)
                                                                                                                           ##        
                                                                                                                           ## :  
                                                                                                                           ## Unique 
                                                                                                                           ## Id 
                                                                                                                           ## for 
                                                                                                                           ## an 
                                                                                                                           ## Amplify 
                                                                                                                           ## App. 
  var path_402657026 = newJObject()
  var body_402657027 = newJObject()
  add(path_402657026, "branchName", newJString(branchName))
  if body != nil:
    body_402657027 = body
  add(path_402657026, "appId", newJString(appId))
  result = call_402657025.call(path_402657026, nil, nil, nil, body_402657027)

var startDeployment* = Call_StartDeployment_402657011(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_402657012, base: "/",
    makeUrl: url_StartDeployment_402657013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_402657028 = ref object of OpenApiRestCall_402656044
proc url_StopJob_402657030(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
                 (kind: VariableSegment, value: "appId"),
                 (kind: ConstantSegment, value: "/branches/"),
                 (kind: VariableSegment, value: "branchName"),
                 (kind: ConstantSegment, value: "/jobs/"),
                 (kind: VariableSegment, value: "jobId"),
                 (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopJob_402657029(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
                                 ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
                                                                     ##             :  Name for the branch, for the Job. 
  ##   
                                                                                                                         ## appId: JString (required)
                                                                                                                         ##        
                                                                                                                         ## :  
                                                                                                                         ## Unique 
                                                                                                                         ## Id 
                                                                                                                         ## for 
                                                                                                                         ## an 
                                                                                                                         ## Amplify 
                                                                                                                         ## App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_402657031 = path.getOrDefault("jobId")
  valid_402657031 = validateParameter(valid_402657031, JString, required = true,
                                      default = nil)
  if valid_402657031 != nil:
    section.add "jobId", valid_402657031
  var valid_402657032 = path.getOrDefault("branchName")
  valid_402657032 = validateParameter(valid_402657032, JString, required = true,
                                      default = nil)
  if valid_402657032 != nil:
    section.add "branchName", valid_402657032
  var valid_402657033 = path.getOrDefault("appId")
  valid_402657033 = validateParameter(valid_402657033, JString, required = true,
                                      default = nil)
  if valid_402657033 != nil:
    section.add "appId", valid_402657033
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
  var valid_402657034 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Security-Token", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Signature")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Signature", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Algorithm", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Date")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Date", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Credential")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Credential", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657041: Call_StopJob_402657028; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_StopJob_402657028; jobId: string;
           branchName: string; appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   
                                                                                  ## jobId: string (required)
                                                                                  ##        
                                                                                  ## :  
                                                                                  ## Unique 
                                                                                  ## Id 
                                                                                  ## for 
                                                                                  ## the 
                                                                                  ## Job. 
  ##   
                                                                                          ## branchName: string (required)
                                                                                          ##             
                                                                                          ## :  
                                                                                          ## Name 
                                                                                          ## for 
                                                                                          ## the 
                                                                                          ## branch, 
                                                                                          ## for 
                                                                                          ## the 
                                                                                          ## Job. 
  ##   
                                                                                                  ## appId: string (required)
                                                                                                  ##        
                                                                                                  ## :  
                                                                                                  ## Unique 
                                                                                                  ## Id 
                                                                                                  ## for 
                                                                                                  ## an 
                                                                                                  ## Amplify 
                                                                                                  ## App. 
  var path_402657043 = newJObject()
  add(path_402657043, "jobId", newJString(jobId))
  add(path_402657043, "branchName", newJString(branchName))
  add(path_402657043, "appId", newJString(appId))
  result = call_402657042.call(path_402657043, nil, nil, nil, nil)

var stopJob* = Call_StopJob_402657028(name: "stopJob",
                                      meth: HttpMethod.HttpDelete,
                                      host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                      validator: validate_StopJob_402657029,
                                      base: "/", makeUrl: url_StopJob_402657030,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657044 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657046(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402657045(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Untag resource with resourceArn. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  Resource arn used to untag resource. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657047 = path.getOrDefault("resourceArn")
  valid_402657047 = validateParameter(valid_402657047, JString, required = true,
                                      default = nil)
  if valid_402657047 != nil:
    section.add "resourceArn", valid_402657047
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657048 = query.getOrDefault("tagKeys")
  valid_402657048 = validateParameter(valid_402657048, JArray, required = true,
                                      default = nil)
  if valid_402657048 != nil:
    section.add "tagKeys", valid_402657048
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
  var valid_402657049 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Security-Token", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Signature")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Signature", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Algorithm", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Date")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Date", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Credential")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Credential", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657056: Call_UntagResource_402657044; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Untag resource with resourceArn. 
                                                                                         ## 
  let valid = call_402657056.validator(path, query, header, formData, body, _)
  let scheme = call_402657056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657056.makeUrl(scheme.get, call_402657056.host, call_402657056.base,
                                   call_402657056.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657056, uri, valid, _)

proc call*(call_402657057: Call_UntagResource_402657044; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   tagKeys: JArray (required)
                                       ##          :  Tag keys used to untag resource. 
  ##   
                                                                                       ## resourceArn: string (required)
                                                                                       ##              
                                                                                       ## :  
                                                                                       ## Resource 
                                                                                       ## arn 
                                                                                       ## used 
                                                                                       ## to 
                                                                                       ## untag 
                                                                                       ## resource. 
  var path_402657058 = newJObject()
  var query_402657059 = newJObject()
  if tagKeys != nil:
    query_402657059.add "tagKeys", tagKeys
  add(path_402657058, "resourceArn", newJString(resourceArn))
  result = call_402657057.call(path_402657058, query_402657059, nil, nil, nil)

var untagResource* = Call_UntagResource_402657044(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402657045,
    base: "/", makeUrl: url_UntagResource_402657046,
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