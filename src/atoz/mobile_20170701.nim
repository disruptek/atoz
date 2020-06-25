
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mobile.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mobile.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mobile.us-west-2.amazonaws.com",
                           "eu-west-2": "mobile.eu-west-2.amazonaws.com", "ap-northeast-3": "mobile.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "mobile.eu-central-1.amazonaws.com",
                           "us-east-2": "mobile.us-east-2.amazonaws.com",
                           "us-east-1": "mobile.us-east-1.amazonaws.com", "cn-northwest-1": "mobile.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "mobile.ap-south-1.amazonaws.com",
                           "eu-north-1": "mobile.eu-north-1.amazonaws.com", "ap-northeast-2": "mobile.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mobile.us-west-1.amazonaws.com", "us-gov-east-1": "mobile.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mobile.eu-west-3.amazonaws.com",
                           "cn-north-1": "mobile.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mobile.sa-east-1.amazonaws.com",
                           "eu-west-1": "mobile.eu-west-1.amazonaws.com", "us-gov-west-1": "mobile.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mobile.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "mobile.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateProject_21626002 = ref object of OpenApiRestCall_21625418
proc url_CreateProject_21626004(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_21626003(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   snapshotId: JString
  ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  ##   name: JString
  ##       :  Name of the project. 
  ##   region: JString
  ##         :  Default region to use for AWS resource creation in the AWS Mobile Hub project. 
  section = newJObject()
  var valid_21626005 = query.getOrDefault("snapshotId")
  valid_21626005 = validateParameter(valid_21626005, JString, required = false,
                                   default = nil)
  if valid_21626005 != nil:
    section.add "snapshotId", valid_21626005
  var valid_21626006 = query.getOrDefault("name")
  valid_21626006 = validateParameter(valid_21626006, JString, required = false,
                                   default = nil)
  if valid_21626006 != nil:
    section.add "name", valid_21626006
  var valid_21626007 = query.getOrDefault("region")
  valid_21626007 = validateParameter(valid_21626007, JString, required = false,
                                   default = nil)
  if valid_21626007 != nil:
    section.add "region", valid_21626007
  result.add "query", section
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

proc call*(call_21626016: Call_CreateProject_21626002; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_21626016.validator(path, query, header, formData, body, _)
  let scheme = call_21626016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626016.makeUrl(scheme.get, call_21626016.host, call_21626016.base,
                               call_21626016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626016, uri, valid, _)

proc call*(call_21626017: Call_CreateProject_21626002; body: JsonNode;
          snapshotId: string = ""; name: string = ""; region: string = ""): Recallable =
  ## createProject
  ##  Creates an AWS Mobile Hub project. 
  ##   snapshotId: string
  ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  ##   name: string
  ##       :  Name of the project. 
  ##   region: string
  ##         :  Default region to use for AWS resource creation in the AWS Mobile Hub project. 
  ##   body: JObject (required)
  var query_21626018 = newJObject()
  var body_21626019 = newJObject()
  add(query_21626018, "snapshotId", newJString(snapshotId))
  add(query_21626018, "name", newJString(name))
  add(query_21626018, "region", newJString(region))
  if body != nil:
    body_21626019 = body
  result = call_21626017.call(nil, query_21626018, nil, nil, body_21626019)

var createProject* = Call_CreateProject_21626002(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_21626003, base: "/",
    makeUrl: url_CreateProject_21626004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_21625762 = ref object of OpenApiRestCall_21625418
proc url_ListProjects_21625764(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_21625763(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  section = newJObject()
  var valid_21625865 = query.getOrDefault("maxResults")
  valid_21625865 = validateParameter(valid_21625865, JInt, required = false,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "maxResults", valid_21625865
  var valid_21625866 = query.getOrDefault("nextToken")
  valid_21625866 = validateParameter(valid_21625866, JString, required = false,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "nextToken", valid_21625866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625867 = header.getOrDefault("X-Amz-Date")
  valid_21625867 = validateParameter(valid_21625867, JString, required = false,
                                   default = nil)
  if valid_21625867 != nil:
    section.add "X-Amz-Date", valid_21625867
  var valid_21625868 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625868 = validateParameter(valid_21625868, JString, required = false,
                                   default = nil)
  if valid_21625868 != nil:
    section.add "X-Amz-Security-Token", valid_21625868
  var valid_21625869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625869 = validateParameter(valid_21625869, JString, required = false,
                                   default = nil)
  if valid_21625869 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625869
  var valid_21625870 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625870 = validateParameter(valid_21625870, JString, required = false,
                                   default = nil)
  if valid_21625870 != nil:
    section.add "X-Amz-Algorithm", valid_21625870
  var valid_21625871 = header.getOrDefault("X-Amz-Signature")
  valid_21625871 = validateParameter(valid_21625871, JString, required = false,
                                   default = nil)
  if valid_21625871 != nil:
    section.add "X-Amz-Signature", valid_21625871
  var valid_21625872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625872 = validateParameter(valid_21625872, JString, required = false,
                                   default = nil)
  if valid_21625872 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625872
  var valid_21625873 = header.getOrDefault("X-Amz-Credential")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Credential", valid_21625873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625898: Call_ListProjects_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_21625898.validator(path, query, header, formData, body, _)
  let scheme = call_21625898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625898.makeUrl(scheme.get, call_21625898.host, call_21625898.base,
                               call_21625898.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625898, uri, valid, _)

proc call*(call_21625961: Call_ListProjects_21625762; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_21625963 = newJObject()
  add(query_21625963, "maxResults", newJInt(maxResults))
  add(query_21625963, "nextToken", newJString(nextToken))
  result = call_21625961.call(nil, query_21625963, nil, nil, nil)

var listProjects* = Call_ListProjects_21625762(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_21625763, base: "/", makeUrl: url_ListProjects_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_21626020 = ref object of OpenApiRestCall_21625418
proc url_DeleteProject_21626022(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_21626021(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
  ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `projectId` field"
  var valid_21626036 = path.getOrDefault("projectId")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "projectId", valid_21626036
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626037 = header.getOrDefault("X-Amz-Date")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Date", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Security-Token", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Algorithm", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Signature")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Signature", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Credential")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Credential", valid_21626043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626044: Call_DeleteProject_21626020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

proc call*(call_21626045: Call_DeleteProject_21626020; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_21626046 = newJObject()
  add(path_21626046, "projectId", newJString(projectId))
  result = call_21626045.call(path_21626046, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_21626020(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_21626021,
    base: "/", makeUrl: url_DeleteProject_21626022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_21626061 = ref object of OpenApiRestCall_21625418
proc url_ExportBundle_21626063(protocol: Scheme; host: string; base: string;
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

proc validate_ExportBundle_21626062(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   bundleId: JString (required)
  ##           :  Unique bundle identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `bundleId` field"
  var valid_21626064 = path.getOrDefault("bundleId")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "bundleId", valid_21626064
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString
  ##            :  Unique project identifier. 
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  section = newJObject()
  var valid_21626065 = query.getOrDefault("projectId")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "projectId", valid_21626065
  var valid_21626080 = query.getOrDefault("platform")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = newJString("OSX"))
  if valid_21626080 != nil:
    section.add "platform", valid_21626080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626081 = header.getOrDefault("X-Amz-Date")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Date", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Security-Token", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Algorithm", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Signature")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Signature", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Credential")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Credential", valid_21626087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_ExportBundle_21626061; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_ExportBundle_21626061; bundleId: string;
          projectId: string = ""; platform: string = "OSX"): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  var path_21626090 = newJObject()
  var query_21626091 = newJObject()
  add(path_21626090, "bundleId", newJString(bundleId))
  add(query_21626091, "projectId", newJString(projectId))
  add(query_21626091, "platform", newJString(platform))
  result = call_21626089.call(path_21626090, query_21626091, nil, nil, nil)

var exportBundle* = Call_ExportBundle_21626061(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_21626062,
    base: "/", makeUrl: url_ExportBundle_21626063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_21626047 = ref object of OpenApiRestCall_21625418
proc url_DescribeBundle_21626049(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBundle_21626048(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `bundleId` field"
  var valid_21626050 = path.getOrDefault("bundleId")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "bundleId", valid_21626050
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626051 = header.getOrDefault("X-Amz-Date")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Date", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Security-Token", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Algorithm", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Signature")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Signature", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Credential")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Credential", valid_21626057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626058: Call_DescribeBundle_21626047; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_DescribeBundle_21626047; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_21626060 = newJObject()
  add(path_21626060, "bundleId", newJString(bundleId))
  result = call_21626059.call(path_21626060, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_21626047(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_21626048,
    base: "/", makeUrl: url_DescribeBundle_21626049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_21626093 = ref object of OpenApiRestCall_21625418
proc url_DescribeProject_21626095(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProject_21626094(path: JsonNode; query: JsonNode;
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
  ##   syncFromResources: JBool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `projectId` field"
  var valid_21626096 = query.getOrDefault("projectId")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "projectId", valid_21626096
  var valid_21626097 = query.getOrDefault("syncFromResources")
  valid_21626097 = validateParameter(valid_21626097, JBool, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "syncFromResources", valid_21626097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626098 = header.getOrDefault("X-Amz-Date")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Date", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Security-Token", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Algorithm", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Signature")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Signature", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Credential")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Credential", valid_21626104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626105: Call_DescribeProject_21626093; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_21626105.validator(path, query, header, formData, body, _)
  let scheme = call_21626105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626105.makeUrl(scheme.get, call_21626105.host, call_21626105.base,
                               call_21626105.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626105, uri, valid, _)

proc call*(call_21626106: Call_DescribeProject_21626093; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  var query_21626107 = newJObject()
  add(query_21626107, "projectId", newJString(projectId))
  add(query_21626107, "syncFromResources", newJBool(syncFromResources))
  result = call_21626106.call(nil, query_21626107, nil, nil, nil)

var describeProject* = Call_DescribeProject_21626093(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_21626094,
    base: "/", makeUrl: url_DescribeProject_21626095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_21626108 = ref object of OpenApiRestCall_21625418
proc url_ExportProject_21626110(protocol: Scheme; host: string; base: string;
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

proc validate_ExportProject_21626109(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
  ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `projectId` field"
  var valid_21626111 = path.getOrDefault("projectId")
  valid_21626111 = validateParameter(valid_21626111, JString, required = true,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "projectId", valid_21626111
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626112 = header.getOrDefault("X-Amz-Date")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Date", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Security-Token", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Algorithm", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Signature")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Signature", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Credential")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Credential", valid_21626118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626119: Call_ExportProject_21626108; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_21626119.validator(path, query, header, formData, body, _)
  let scheme = call_21626119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626119.makeUrl(scheme.get, call_21626119.host, call_21626119.base,
                               call_21626119.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626119, uri, valid, _)

proc call*(call_21626120: Call_ExportProject_21626108; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_21626121 = newJObject()
  add(path_21626121, "projectId", newJString(projectId))
  result = call_21626120.call(path_21626121, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_21626108(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_21626109,
    base: "/", makeUrl: url_ExportProject_21626110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_21626122 = ref object of OpenApiRestCall_21625418
proc url_ListBundles_21626124(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBundles_21626123(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  section = newJObject()
  var valid_21626125 = query.getOrDefault("maxResults")
  valid_21626125 = validateParameter(valid_21626125, JInt, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "maxResults", valid_21626125
  var valid_21626126 = query.getOrDefault("nextToken")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "nextToken", valid_21626126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626127 = header.getOrDefault("X-Amz-Date")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Date", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Security-Token", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Algorithm", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Signature")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Signature", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Credential")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Credential", valid_21626133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626134: Call_ListBundles_21626122; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_21626134.validator(path, query, header, formData, body, _)
  let scheme = call_21626134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626134.makeUrl(scheme.get, call_21626134.host, call_21626134.base,
                               call_21626134.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626134, uri, valid, _)

proc call*(call_21626135: Call_ListBundles_21626122; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_21626136 = newJObject()
  add(query_21626136, "maxResults", newJInt(maxResults))
  add(query_21626136, "nextToken", newJString(nextToken))
  result = call_21626135.call(nil, query_21626136, nil, nil, nil)

var listBundles* = Call_ListBundles_21626122(name: "listBundles",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/bundles",
    validator: validate_ListBundles_21626123, base: "/", makeUrl: url_ListBundles_21626124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_21626137 = ref object of OpenApiRestCall_21625418
proc url_UpdateProject_21626139(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_21626138(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626140 = query.getOrDefault("projectId")
  valid_21626140 = validateParameter(valid_21626140, JString, required = true,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "projectId", valid_21626140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626141 = header.getOrDefault("X-Amz-Date")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Date", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Security-Token", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Algorithm", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Signature")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Signature", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Credential")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Credential", valid_21626147
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

proc call*(call_21626149: Call_UpdateProject_21626137; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_21626149.validator(path, query, header, formData, body, _)
  let scheme = call_21626149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626149.makeUrl(scheme.get, call_21626149.host, call_21626149.base,
                               call_21626149.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626149, uri, valid, _)

proc call*(call_21626150: Call_UpdateProject_21626137; projectId: string;
          body: JsonNode): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   body: JObject (required)
  var query_21626151 = newJObject()
  var body_21626152 = newJObject()
  add(query_21626151, "projectId", newJString(projectId))
  if body != nil:
    body_21626152 = body
  result = call_21626150.call(nil, query_21626151, nil, nil, body_21626152)

var updateProject* = Call_UpdateProject_21626137(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_21626138,
    base: "/", makeUrl: url_UpdateProject_21626139,
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