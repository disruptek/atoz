
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Mobile
## version: 2017-07-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS Mobile Service provides mobile app and website developers with capabilities required to configure AWS resources and bootstrap their developer desktop projects with the necessary SDKs, constants, tools and samples to make use of those resources. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mobile/
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

  OpenApiRestCall_402656029 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656029](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656029): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mobile.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mobile.ap-southeast-1.amazonaws.com",
                               "us-west-2": "mobile.us-west-2.amazonaws.com",
                               "eu-west-2": "mobile.eu-west-2.amazonaws.com", "ap-northeast-3": "mobile.ap-northeast-3.amazonaws.com", "eu-central-1": "mobile.eu-central-1.amazonaws.com",
                               "us-east-2": "mobile.us-east-2.amazonaws.com",
                               "us-east-1": "mobile.us-east-1.amazonaws.com", "cn-northwest-1": "mobile.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "mobile.ap-south-1.amazonaws.com",
                               "eu-north-1": "mobile.eu-north-1.amazonaws.com", "ap-northeast-2": "mobile.ap-northeast-2.amazonaws.com",
                               "us-west-1": "mobile.us-west-1.amazonaws.com", "us-gov-east-1": "mobile.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "mobile.eu-west-3.amazonaws.com", "cn-north-1": "mobile.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "mobile.sa-east-1.amazonaws.com",
                               "eu-west-1": "mobile.eu-west-1.amazonaws.com", "us-gov-west-1": "mobile.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mobile.ap-southeast-2.amazonaws.com", "ca-central-1": "mobile.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mobile.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mobile.ap-southeast-1.amazonaws.com",
      "us-west-2": "mobile.us-west-2.amazonaws.com",
      "eu-west-2": "mobile.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mobile.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mobile.eu-central-1.amazonaws.com",
      "us-east-2": "mobile.us-east-2.amazonaws.com",
      "us-east-1": "mobile.us-east-1.amazonaws.com",
      "cn-northwest-1": "mobile.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mobile.ap-south-1.amazonaws.com",
      "eu-north-1": "mobile.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mobile.ap-northeast-2.amazonaws.com",
      "us-west-1": "mobile.us-west-1.amazonaws.com",
      "us-gov-east-1": "mobile.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mobile.eu-west-3.amazonaws.com",
      "cn-north-1": "mobile.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mobile.sa-east-1.amazonaws.com",
      "eu-west-1": "mobile.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mobile.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mobile.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mobile.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mobile"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateProject_402656462 = ref object of OpenApiRestCall_402656029
proc url_CreateProject_402656464(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_402656463(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates an AWS Mobile Hub project. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
                                  ##       :  Name of the project. 
  ##   snapshotId: JString
                                                                   ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  ##   
                                                                                                                                                                                                                      ## region: JString
                                                                                                                                                                                                                      ##         
                                                                                                                                                                                                                      ## :  
                                                                                                                                                                                                                      ## Default 
                                                                                                                                                                                                                      ## region 
                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                      ## AWS 
                                                                                                                                                                                                                      ## resource 
                                                                                                                                                                                                                      ## creation 
                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                      ## AWS 
                                                                                                                                                                                                                      ## Mobile 
                                                                                                                                                                                                                      ## Hub 
                                                                                                                                                                                                                      ## project. 
  section = newJObject()
  var valid_402656465 = query.getOrDefault("name")
  valid_402656465 = validateParameter(valid_402656465, JString,
                                      required = false, default = nil)
  if valid_402656465 != nil:
    section.add "name", valid_402656465
  var valid_402656466 = query.getOrDefault("snapshotId")
  valid_402656466 = validateParameter(valid_402656466, JString,
                                      required = false, default = nil)
  if valid_402656466 != nil:
    section.add "snapshotId", valid_402656466
  var valid_402656467 = query.getOrDefault("region")
  valid_402656467 = validateParameter(valid_402656467, JString,
                                      required = false, default = nil)
  if valid_402656467 != nil:
    section.add "region", valid_402656467
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
  var valid_402656468 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656468 = validateParameter(valid_402656468, JString,
                                      required = false, default = nil)
  if valid_402656468 != nil:
    section.add "X-Amz-Security-Token", valid_402656468
  var valid_402656469 = header.getOrDefault("X-Amz-Signature")
  valid_402656469 = validateParameter(valid_402656469, JString,
                                      required = false, default = nil)
  if valid_402656469 != nil:
    section.add "X-Amz-Signature", valid_402656469
  var valid_402656470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656470 = validateParameter(valid_402656470, JString,
                                      required = false, default = nil)
  if valid_402656470 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656470
  var valid_402656471 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656471 = validateParameter(valid_402656471, JString,
                                      required = false, default = nil)
  if valid_402656471 != nil:
    section.add "X-Amz-Algorithm", valid_402656471
  var valid_402656472 = header.getOrDefault("X-Amz-Date")
  valid_402656472 = validateParameter(valid_402656472, JString,
                                      required = false, default = nil)
  if valid_402656472 != nil:
    section.add "X-Amz-Date", valid_402656472
  var valid_402656473 = header.getOrDefault("X-Amz-Credential")
  valid_402656473 = validateParameter(valid_402656473, JString,
                                      required = false, default = nil)
  if valid_402656473 != nil:
    section.add "X-Amz-Credential", valid_402656473
  var valid_402656474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656474
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

proc call*(call_402656476: Call_CreateProject_402656462; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates an AWS Mobile Hub project. 
                                                                                         ## 
  let valid = call_402656476.validator(path, query, header, formData, body, _)
  let scheme = call_402656476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656476.makeUrl(scheme.get, call_402656476.host, call_402656476.base,
                                   call_402656476.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656476, uri, valid, _)

proc call*(call_402656477: Call_CreateProject_402656462; body: JsonNode;
           name: string = ""; snapshotId: string = ""; region: string = ""): Recallable =
  ## createProject
  ##  Creates an AWS Mobile Hub project. 
  ##   body: JObject (required)
  ##   name: string
                               ##       :  Name of the project. 
  ##   snapshotId: string
                                                                ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  ##   
                                                                                                                                                                                                                   ## region: string
                                                                                                                                                                                                                   ##         
                                                                                                                                                                                                                   ## :  
                                                                                                                                                                                                                   ## Default 
                                                                                                                                                                                                                   ## region 
                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                   ## use 
                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                   ## AWS 
                                                                                                                                                                                                                   ## resource 
                                                                                                                                                                                                                   ## creation 
                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                   ## AWS 
                                                                                                                                                                                                                   ## Mobile 
                                                                                                                                                                                                                   ## Hub 
                                                                                                                                                                                                                   ## project. 
  var query_402656478 = newJObject()
  var body_402656479 = newJObject()
  if body != nil:
    body_402656479 = body
  add(query_402656478, "name", newJString(name))
  add(query_402656478, "snapshotId", newJString(snapshotId))
  add(query_402656478, "region", newJString(region))
  result = call_402656477.call(nil, query_402656478, nil, nil, body_402656479)

var createProject* = Call_CreateProject_402656462(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_402656463, base: "/",
    makeUrl: url_CreateProject_402656464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_402656279 = ref object of OpenApiRestCall_402656029
proc url_ListProjects_402656281(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_402656280(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Lists projects in AWS Mobile Hub. 
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
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## records 
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
                                                                                                            ## in 
                                                                                                            ## another 
                                                                                                            ## request 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## entries. 
  section = newJObject()
  var valid_402656360 = query.getOrDefault("maxResults")
  valid_402656360 = validateParameter(valid_402656360, JInt, required = false,
                                      default = nil)
  if valid_402656360 != nil:
    section.add "maxResults", valid_402656360
  var valid_402656361 = query.getOrDefault("nextToken")
  valid_402656361 = validateParameter(valid_402656361, JString,
                                      required = false, default = nil)
  if valid_402656361 != nil:
    section.add "nextToken", valid_402656361
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
  var valid_402656362 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656362 = validateParameter(valid_402656362, JString,
                                      required = false, default = nil)
  if valid_402656362 != nil:
    section.add "X-Amz-Security-Token", valid_402656362
  var valid_402656363 = header.getOrDefault("X-Amz-Signature")
  valid_402656363 = validateParameter(valid_402656363, JString,
                                      required = false, default = nil)
  if valid_402656363 != nil:
    section.add "X-Amz-Signature", valid_402656363
  var valid_402656364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656364 = validateParameter(valid_402656364, JString,
                                      required = false, default = nil)
  if valid_402656364 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656364
  var valid_402656365 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656365 = validateParameter(valid_402656365, JString,
                                      required = false, default = nil)
  if valid_402656365 != nil:
    section.add "X-Amz-Algorithm", valid_402656365
  var valid_402656366 = header.getOrDefault("X-Amz-Date")
  valid_402656366 = validateParameter(valid_402656366, JString,
                                      required = false, default = nil)
  if valid_402656366 != nil:
    section.add "X-Amz-Date", valid_402656366
  var valid_402656367 = header.getOrDefault("X-Amz-Credential")
  valid_402656367 = validateParameter(valid_402656367, JString,
                                      required = false, default = nil)
  if valid_402656367 != nil:
    section.add "X-Amz-Credential", valid_402656367
  var valid_402656368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656368 = validateParameter(valid_402656368, JString,
                                      required = false, default = nil)
  if valid_402656368 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656382: Call_ListProjects_402656279; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
                                                                                         ## 
  let valid = call_402656382.validator(path, query, header, formData, body, _)
  let scheme = call_402656382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656382.makeUrl(scheme.get, call_402656382.host, call_402656382.base,
                                   call_402656382.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656382, uri, valid, _)

proc call*(call_402656431: Call_ListProjects_402656279; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
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
                                                                                                                  ## records 
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
                                                                                                                  ## in 
                                                                                                                  ## another 
                                                                                                                  ## request 
                                                                                                                  ## to 
                                                                                                                  ## list 
                                                                                                                  ## more 
                                                                                                                  ## entries. 
  var query_402656432 = newJObject()
  add(query_402656432, "maxResults", newJInt(maxResults))
  add(query_402656432, "nextToken", newJString(nextToken))
  result = call_402656431.call(nil, query_402656432, nil, nil, nil)

var listProjects* = Call_ListProjects_402656279(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_402656280, base: "/",
    makeUrl: url_ListProjects_402656281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_402656480 = ref object of OpenApiRestCall_402656029
proc url_DeleteProject_402656482(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectId" in path, "`projectId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
                 (kind: VariableSegment, value: "projectId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProject_402656481(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Delets a project in AWS Mobile Hub. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
                                 ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectId` field"
  var valid_402656494 = path.getOrDefault("projectId")
  valid_402656494 = validateParameter(valid_402656494, JString, required = true,
                                      default = nil)
  if valid_402656494 != nil:
    section.add "projectId", valid_402656494
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
  var valid_402656495 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Security-Token", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Signature")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Signature", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Algorithm", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Date")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Date", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Credential")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Credential", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656502: Call_DeleteProject_402656480; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
                                                                                         ## 
  let valid = call_402656502.validator(path, query, header, formData, body, _)
  let scheme = call_402656502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656502.makeUrl(scheme.get, call_402656502.host, call_402656502.base,
                                   call_402656502.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656502, uri, valid, _)

proc call*(call_402656503: Call_DeleteProject_402656480; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
                                          ##            :  Unique project identifier. 
  var path_402656504 = newJObject()
  add(path_402656504, "projectId", newJString(projectId))
  result = call_402656503.call(path_402656504, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_402656480(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_402656481,
    base: "/", makeUrl: url_DeleteProject_402656482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_402656519 = ref object of OpenApiRestCall_402656029
proc url_ExportBundle_402656521(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "bundleId" in path, "`bundleId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bundles/"),
                 (kind: VariableSegment, value: "bundleId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportBundle_402656520(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   bundleId: JString (required)
                                 ##           :  Unique bundle identifier. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `bundleId` field"
  var valid_402656522 = path.getOrDefault("bundleId")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true,
                                      default = nil)
  if valid_402656522 != nil:
    section.add "bundleId", valid_402656522
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString
                                  ##            :  Unique project identifier. 
  ##   
                                                                              ## platform: JString
                                                                              ##           
                                                                              ## :  
                                                                              ## Developer 
                                                                              ## desktop 
                                                                              ## or 
                                                                              ## target 
                                                                              ## mobile 
                                                                              ## app 
                                                                              ## or 
                                                                              ## website 
                                                                              ## platform. 
  section = newJObject()
  var valid_402656523 = query.getOrDefault("projectId")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "projectId", valid_402656523
  var valid_402656536 = query.getOrDefault("platform")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false,
                                      default = newJString("OSX"))
  if valid_402656536 != nil:
    section.add "platform", valid_402656536
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
  var valid_402656537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Security-Token", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Signature")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Signature", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Algorithm", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Date")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Date", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Credential")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Credential", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656544: Call_ExportBundle_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_ExportBundle_402656519; bundleId: string;
           projectId: string = ""; platform: string = "OSX"): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   
                                                                                                                                                              ## projectId: string
                                                                                                                                                              ##            
                                                                                                                                                              ## :  
                                                                                                                                                              ## Unique 
                                                                                                                                                              ## project 
                                                                                                                                                              ## identifier. 
  ##   
                                                                                                                                                                             ## platform: string
                                                                                                                                                                             ##           
                                                                                                                                                                             ## :  
                                                                                                                                                                             ## Developer 
                                                                                                                                                                             ## desktop 
                                                                                                                                                                             ## or 
                                                                                                                                                                             ## target 
                                                                                                                                                                             ## mobile 
                                                                                                                                                                             ## app 
                                                                                                                                                                             ## or 
                                                                                                                                                                             ## website 
                                                                                                                                                                             ## platform. 
  ##   
                                                                                                                                                                                          ## bundleId: string (required)
                                                                                                                                                                                          ##           
                                                                                                                                                                                          ## :  
                                                                                                                                                                                          ## Unique 
                                                                                                                                                                                          ## bundle 
                                                                                                                                                                                          ## identifier. 
  var path_402656546 = newJObject()
  var query_402656547 = newJObject()
  add(query_402656547, "projectId", newJString(projectId))
  add(query_402656547, "platform", newJString(platform))
  add(path_402656546, "bundleId", newJString(bundleId))
  result = call_402656545.call(path_402656546, query_402656547, nil, nil, nil)

var exportBundle* = Call_ExportBundle_402656519(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_402656520,
    base: "/", makeUrl: url_ExportBundle_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_402656505 = ref object of OpenApiRestCall_402656029
proc url_DescribeBundle_402656507(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "bundleId" in path, "`bundleId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bundles/"),
                 (kind: VariableSegment, value: "bundleId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBundle_402656506(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Get the bundle details for the requested bundle id. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   bundleId: JString (required)
                                 ##           :  Unique bundle identifier. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `bundleId` field"
  var valid_402656508 = path.getOrDefault("bundleId")
  valid_402656508 = validateParameter(valid_402656508, JString, required = true,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "bundleId", valid_402656508
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
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_DescribeBundle_402656505; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Get the bundle details for the requested bundle id. 
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

proc call*(call_402656517: Call_DescribeBundle_402656505; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
                                                          ##           :  Unique bundle identifier. 
  var path_402656518 = newJObject()
  add(path_402656518, "bundleId", newJString(bundleId))
  result = call_402656517.call(path_402656518, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_402656505(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_402656506,
    base: "/", makeUrl: url_DescribeBundle_402656507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_402656548 = ref object of OpenApiRestCall_402656029
proc url_DescribeProject_402656550(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProject_402656549(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets details about a project in AWS Mobile Hub. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString (required)
                                  ##            :  Unique project identifier. 
  ##   
                                                                              ## syncFromResources: JBool
                                                                              ##                    
                                                                              ## :  
                                                                              ## If 
                                                                              ## set 
                                                                              ## to 
                                                                              ## true, 
                                                                              ## causes 
                                                                              ## AWS 
                                                                              ## Mobile 
                                                                              ## Hub 
                                                                              ## to 
                                                                              ## synchronize 
                                                                              ## information 
                                                                              ## from 
                                                                              ## other 
                                                                              ## services, 
                                                                              ## e.g., 
                                                                              ## update 
                                                                              ## state 
                                                                              ## of 
                                                                              ## AWS 
                                                                              ## CloudFormation 
                                                                              ## stacks 
                                                                              ## in 
                                                                              ## the 
                                                                              ## AWS 
                                                                              ## Mobile 
                                                                              ## Hub 
                                                                              ## project. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `projectId` field"
  var valid_402656551 = query.getOrDefault("projectId")
  valid_402656551 = validateParameter(valid_402656551, JString, required = true,
                                      default = nil)
  if valid_402656551 != nil:
    section.add "projectId", valid_402656551
  var valid_402656552 = query.getOrDefault("syncFromResources")
  valid_402656552 = validateParameter(valid_402656552, JBool, required = false,
                                      default = nil)
  if valid_402656552 != nil:
    section.add "syncFromResources", valid_402656552
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
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656560: Call_DescribeProject_402656548; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
                                                                                         ## 
  let valid = call_402656560.validator(path, query, header, formData, body, _)
  let scheme = call_402656560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656560.makeUrl(scheme.get, call_402656560.host, call_402656560.base,
                                   call_402656560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656560, uri, valid, _)

proc call*(call_402656561: Call_DescribeProject_402656548; projectId: string;
           syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   projectId: string (required)
                                                      ##            :  Unique project identifier. 
  ##   
                                                                                                  ## syncFromResources: bool
                                                                                                  ##                    
                                                                                                  ## :  
                                                                                                  ## If 
                                                                                                  ## set 
                                                                                                  ## to 
                                                                                                  ## true, 
                                                                                                  ## causes 
                                                                                                  ## AWS 
                                                                                                  ## Mobile 
                                                                                                  ## Hub 
                                                                                                  ## to 
                                                                                                  ## synchronize 
                                                                                                  ## information 
                                                                                                  ## from 
                                                                                                  ## other 
                                                                                                  ## services, 
                                                                                                  ## e.g., 
                                                                                                  ## update 
                                                                                                  ## state 
                                                                                                  ## of 
                                                                                                  ## AWS 
                                                                                                  ## CloudFormation 
                                                                                                  ## stacks 
                                                                                                  ## in 
                                                                                                  ## the 
                                                                                                  ## AWS 
                                                                                                  ## Mobile 
                                                                                                  ## Hub 
                                                                                                  ## project. 
  var query_402656562 = newJObject()
  add(query_402656562, "projectId", newJString(projectId))
  add(query_402656562, "syncFromResources", newJBool(syncFromResources))
  result = call_402656561.call(nil, query_402656562, nil, nil, nil)

var describeProject* = Call_DescribeProject_402656548(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_402656549,
    base: "/", makeUrl: url_DescribeProject_402656550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_402656563 = ref object of OpenApiRestCall_402656029
proc url_ExportProject_402656565(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "projectId" in path, "`projectId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/exports/"),
                 (kind: VariableSegment, value: "projectId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportProject_402656564(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
                                 ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `projectId` field"
  var valid_402656566 = path.getOrDefault("projectId")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "projectId", valid_402656566
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

proc call*(call_402656574: Call_ExportProject_402656563; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
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

proc call*(call_402656575: Call_ExportProject_402656563; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   
                                                                                                                                                                                                                                     ## projectId: string (required)
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## :  
                                                                                                                                                                                                                                     ## Unique 
                                                                                                                                                                                                                                     ## project 
                                                                                                                                                                                                                                     ## identifier. 
  var path_402656576 = newJObject()
  add(path_402656576, "projectId", newJString(projectId))
  result = call_402656575.call(path_402656576, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_402656563(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_402656564,
    base: "/", makeUrl: url_ExportProject_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_402656577 = ref object of OpenApiRestCall_402656029
proc url_ListBundles_402656579(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBundles_402656578(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  List all available bundles. 
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
                                                                                                            ## Set 
                                                                                                            ## to 
                                                                                                            ## null 
                                                                                                            ## to 
                                                                                                            ## start 
                                                                                                            ## listing 
                                                                                                            ## records 
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
                                                                                                            ## in 
                                                                                                            ## another 
                                                                                                            ## request 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## entries. 
  section = newJObject()
  var valid_402656580 = query.getOrDefault("maxResults")
  valid_402656580 = validateParameter(valid_402656580, JInt, required = false,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "maxResults", valid_402656580
  var valid_402656581 = query.getOrDefault("nextToken")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "nextToken", valid_402656581
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
  var valid_402656582 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Security-Token", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Signature")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Signature", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Algorithm", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Date")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Date", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Credential")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Credential", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656589: Call_ListBundles_402656577; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  List all available bundles. 
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

proc call*(call_402656590: Call_ListBundles_402656577; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listBundles
  ##  List all available bundles. 
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
                                                                                                            ## records 
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
                                                                                                            ## in 
                                                                                                            ## another 
                                                                                                            ## request 
                                                                                                            ## to 
                                                                                                            ## list 
                                                                                                            ## more 
                                                                                                            ## entries. 
  var query_402656591 = newJObject()
  add(query_402656591, "maxResults", newJInt(maxResults))
  add(query_402656591, "nextToken", newJString(nextToken))
  result = call_402656590.call(nil, query_402656591, nil, nil, nil)

var listBundles* = Call_ListBundles_402656577(name: "listBundles",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/bundles",
    validator: validate_ListBundles_402656578, base: "/",
    makeUrl: url_ListBundles_402656579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_402656592 = ref object of OpenApiRestCall_402656029
proc url_UpdateProject_402656594(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_402656593(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Update an existing project. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString (required)
                                  ##            :  Unique project identifier. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `projectId` field"
  var valid_402656595 = query.getOrDefault("projectId")
  valid_402656595 = validateParameter(valid_402656595, JString, required = true,
                                      default = nil)
  if valid_402656595 != nil:
    section.add "projectId", valid_402656595
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
  var valid_402656596 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Security-Token", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Signature")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Signature", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Algorithm", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Date")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Date", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Credential")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Credential", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656602
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

proc call*(call_402656604: Call_UpdateProject_402656592; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Update an existing project. 
                                                                                         ## 
  let valid = call_402656604.validator(path, query, header, formData, body, _)
  let scheme = call_402656604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656604.makeUrl(scheme.get, call_402656604.host, call_402656604.base,
                                   call_402656604.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656604, uri, valid, _)

proc call*(call_402656605: Call_UpdateProject_402656592; projectId: string;
           body: JsonNode): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   projectId: string (required)
                                  ##            :  Unique project identifier. 
  ##   
                                                                              ## body: JObject (required)
  var query_402656606 = newJObject()
  var body_402656607 = newJObject()
  add(query_402656606, "projectId", newJString(projectId))
  if body != nil:
    body_402656607 = body
  result = call_402656605.call(nil, query_402656606, nil, nil, body_402656607)

var updateProject* = Call_UpdateProject_402656592(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_402656593,
    base: "/", makeUrl: url_UpdateProject_402656594,
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