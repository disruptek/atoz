
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateProject_613237 = ref object of OpenApiRestCall_612642
proc url_CreateProject_613239(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_613238(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       :  Name of the project. 
  ##   region: JString
  ##         :  Default region to use for AWS resource creation in the AWS Mobile Hub project. 
  ##   snapshotId: JString
  ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  section = newJObject()
  var valid_613240 = query.getOrDefault("name")
  valid_613240 = validateParameter(valid_613240, JString, required = false,
                                 default = nil)
  if valid_613240 != nil:
    section.add "name", valid_613240
  var valid_613241 = query.getOrDefault("region")
  valid_613241 = validateParameter(valid_613241, JString, required = false,
                                 default = nil)
  if valid_613241 != nil:
    section.add "region", valid_613241
  var valid_613242 = query.getOrDefault("snapshotId")
  valid_613242 = validateParameter(valid_613242, JString, required = false,
                                 default = nil)
  if valid_613242 != nil:
    section.add "snapshotId", valid_613242
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
  var valid_613243 = header.getOrDefault("X-Amz-Signature")
  valid_613243 = validateParameter(valid_613243, JString, required = false,
                                 default = nil)
  if valid_613243 != nil:
    section.add "X-Amz-Signature", valid_613243
  var valid_613244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613244 = validateParameter(valid_613244, JString, required = false,
                                 default = nil)
  if valid_613244 != nil:
    section.add "X-Amz-Content-Sha256", valid_613244
  var valid_613245 = header.getOrDefault("X-Amz-Date")
  valid_613245 = validateParameter(valid_613245, JString, required = false,
                                 default = nil)
  if valid_613245 != nil:
    section.add "X-Amz-Date", valid_613245
  var valid_613246 = header.getOrDefault("X-Amz-Credential")
  valid_613246 = validateParameter(valid_613246, JString, required = false,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-Credential", valid_613246
  var valid_613247 = header.getOrDefault("X-Amz-Security-Token")
  valid_613247 = validateParameter(valid_613247, JString, required = false,
                                 default = nil)
  if valid_613247 != nil:
    section.add "X-Amz-Security-Token", valid_613247
  var valid_613248 = header.getOrDefault("X-Amz-Algorithm")
  valid_613248 = validateParameter(valid_613248, JString, required = false,
                                 default = nil)
  if valid_613248 != nil:
    section.add "X-Amz-Algorithm", valid_613248
  var valid_613249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "X-Amz-SignedHeaders", valid_613249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613251: Call_CreateProject_613237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_613251.validator(path, query, header, formData, body)
  let scheme = call_613251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613251.url(scheme.get, call_613251.host, call_613251.base,
                         call_613251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613251, url, valid)

proc call*(call_613252: Call_CreateProject_613237; body: JsonNode; name: string = "";
          region: string = ""; snapshotId: string = ""): Recallable =
  ## createProject
  ##  Creates an AWS Mobile Hub project. 
  ##   name: string
  ##       :  Name of the project. 
  ##   region: string
  ##         :  Default region to use for AWS resource creation in the AWS Mobile Hub project. 
  ##   snapshotId: string
  ##             :  Unique identifier for the exported snapshot of the project configuration. This snapshot identifier is included in the share URL. 
  ##   body: JObject (required)
  var query_613253 = newJObject()
  var body_613254 = newJObject()
  add(query_613253, "name", newJString(name))
  add(query_613253, "region", newJString(region))
  add(query_613253, "snapshotId", newJString(snapshotId))
  if body != nil:
    body_613254 = body
  result = call_613252.call(nil, query_613253, nil, nil, body_613254)

var createProject* = Call_CreateProject_613237(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_613238, base: "/", url: url_CreateProject_613239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_612980 = ref object of OpenApiRestCall_612642
proc url_ListProjects_612982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_612981(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613094 = query.getOrDefault("nextToken")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "nextToken", valid_613094
  var valid_613095 = query.getOrDefault("maxResults")
  valid_613095 = validateParameter(valid_613095, JInt, required = false, default = nil)
  if valid_613095 != nil:
    section.add "maxResults", valid_613095
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
  var valid_613096 = header.getOrDefault("X-Amz-Signature")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Signature", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-Content-Sha256", valid_613097
  var valid_613098 = header.getOrDefault("X-Amz-Date")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "X-Amz-Date", valid_613098
  var valid_613099 = header.getOrDefault("X-Amz-Credential")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Credential", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-Security-Token")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-Security-Token", valid_613100
  var valid_613101 = header.getOrDefault("X-Amz-Algorithm")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Algorithm", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-SignedHeaders", valid_613102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613125: Call_ListProjects_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_613125.validator(path, query, header, formData, body)
  let scheme = call_613125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613125.url(scheme.get, call_613125.host, call_613125.base,
                         call_613125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613125, url, valid)

proc call*(call_613196: Call_ListProjects_612980; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_613197 = newJObject()
  add(query_613197, "nextToken", newJString(nextToken))
  add(query_613197, "maxResults", newJInt(maxResults))
  result = call_613196.call(nil, query_613197, nil, nil, nil)

var listProjects* = Call_ListProjects_612980(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_612981, base: "/", url: url_ListProjects_612982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_613255 = ref object of OpenApiRestCall_612642
proc url_DeleteProject_613257(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProject_613256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
  ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `projectId` field"
  var valid_613272 = path.getOrDefault("projectId")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = nil)
  if valid_613272 != nil:
    section.add "projectId", valid_613272
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
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_DeleteProject_613255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_DeleteProject_613255; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_613282 = newJObject()
  add(path_613282, "projectId", newJString(projectId))
  result = call_613281.call(path_613282, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_613255(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_613256,
    base: "/", url: url_DeleteProject_613257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_613297 = ref object of OpenApiRestCall_612642
proc url_ExportBundle_613299(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportBundle_613298(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   bundleId: JString (required)
  ##           :  Unique bundle identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `bundleId` field"
  var valid_613300 = path.getOrDefault("bundleId")
  valid_613300 = validateParameter(valid_613300, JString, required = true,
                                 default = nil)
  if valid_613300 != nil:
    section.add "bundleId", valid_613300
  result.add "path", section
  ## parameters in `query` object:
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: JString
  ##            :  Unique project identifier. 
  section = newJObject()
  var valid_613314 = query.getOrDefault("platform")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = newJString("OSX"))
  if valid_613314 != nil:
    section.add "platform", valid_613314
  var valid_613315 = query.getOrDefault("projectId")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "projectId", valid_613315
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
  var valid_613316 = header.getOrDefault("X-Amz-Signature")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Signature", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Content-Sha256", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Date")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Date", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Credential")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Credential", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Security-Token")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Security-Token", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Algorithm")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Algorithm", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-SignedHeaders", valid_613322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613323: Call_ExportBundle_613297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_613323.validator(path, query, header, formData, body)
  let scheme = call_613323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613323.url(scheme.get, call_613323.host, call_613323.base,
                         call_613323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613323, url, valid)

proc call*(call_613324: Call_ExportBundle_613297; bundleId: string;
          platform: string = "OSX"; projectId: string = ""): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  var path_613325 = newJObject()
  var query_613326 = newJObject()
  add(path_613325, "bundleId", newJString(bundleId))
  add(query_613326, "platform", newJString(platform))
  add(query_613326, "projectId", newJString(projectId))
  result = call_613324.call(path_613325, query_613326, nil, nil, nil)

var exportBundle* = Call_ExportBundle_613297(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_613298,
    base: "/", url: url_ExportBundle_613299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_613283 = ref object of OpenApiRestCall_612642
proc url_DescribeBundle_613285(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBundle_613284(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   bundleId: JString (required)
  ##           :  Unique bundle identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `bundleId` field"
  var valid_613286 = path.getOrDefault("bundleId")
  valid_613286 = validateParameter(valid_613286, JString, required = true,
                                 default = nil)
  if valid_613286 != nil:
    section.add "bundleId", valid_613286
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
  var valid_613287 = header.getOrDefault("X-Amz-Signature")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Signature", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Content-Sha256", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Date")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Date", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Credential")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Credential", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Security-Token")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Security-Token", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Algorithm")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Algorithm", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-SignedHeaders", valid_613293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613294: Call_DescribeBundle_613283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_613294.validator(path, query, header, formData, body)
  let scheme = call_613294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613294.url(scheme.get, call_613294.host, call_613294.base,
                         call_613294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613294, url, valid)

proc call*(call_613295: Call_DescribeBundle_613283; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_613296 = newJObject()
  add(path_613296, "bundleId", newJString(bundleId))
  result = call_613295.call(path_613296, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_613283(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_613284,
    base: "/", url: url_DescribeBundle_613285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_613327 = ref object of OpenApiRestCall_612642
proc url_DescribeProject_613329(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProject_613328(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   syncFromResources: JBool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  ##   projectId: JString (required)
  ##            :  Unique project identifier. 
  section = newJObject()
  var valid_613330 = query.getOrDefault("syncFromResources")
  valid_613330 = validateParameter(valid_613330, JBool, required = false, default = nil)
  if valid_613330 != nil:
    section.add "syncFromResources", valid_613330
  assert query != nil,
        "query argument is necessary due to required `projectId` field"
  var valid_613331 = query.getOrDefault("projectId")
  valid_613331 = validateParameter(valid_613331, JString, required = true,
                                 default = nil)
  if valid_613331 != nil:
    section.add "projectId", valid_613331
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
  var valid_613332 = header.getOrDefault("X-Amz-Signature")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Signature", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Content-Sha256", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Date")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Date", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Credential")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Credential", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Security-Token")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Security-Token", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Algorithm")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Algorithm", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-SignedHeaders", valid_613338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_DescribeProject_613327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_DescribeProject_613327; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_613341 = newJObject()
  add(query_613341, "syncFromResources", newJBool(syncFromResources))
  add(query_613341, "projectId", newJString(projectId))
  result = call_613340.call(nil, query_613341, nil, nil, nil)

var describeProject* = Call_DescribeProject_613327(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_613328,
    base: "/", url: url_DescribeProject_613329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_613342 = ref object of OpenApiRestCall_612642
proc url_ExportProject_613344(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportProject_613343(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   projectId: JString (required)
  ##            :  Unique project identifier. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `projectId` field"
  var valid_613345 = path.getOrDefault("projectId")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = nil)
  if valid_613345 != nil:
    section.add "projectId", valid_613345
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
  var valid_613346 = header.getOrDefault("X-Amz-Signature")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Signature", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Content-Sha256", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Date")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Date", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Credential")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Credential", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Security-Token")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Security-Token", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Algorithm")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Algorithm", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-SignedHeaders", valid_613352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_ExportProject_613342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_ExportProject_613342; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_613355 = newJObject()
  add(path_613355, "projectId", newJString(projectId))
  result = call_613354.call(path_613355, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_613342(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_613343,
    base: "/", url: url_ExportProject_613344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_613356 = ref object of OpenApiRestCall_612642
proc url_ListBundles_613358(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBundles_613357(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  List all available bundles. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613359 = query.getOrDefault("nextToken")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "nextToken", valid_613359
  var valid_613360 = query.getOrDefault("maxResults")
  valid_613360 = validateParameter(valid_613360, JInt, required = false, default = nil)
  if valid_613360 != nil:
    section.add "maxResults", valid_613360
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
  var valid_613361 = header.getOrDefault("X-Amz-Signature")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Signature", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Content-Sha256", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Date")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Date", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Credential")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Credential", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Security-Token")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Security-Token", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Algorithm")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Algorithm", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-SignedHeaders", valid_613367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613368: Call_ListBundles_613356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_613368.validator(path, query, header, formData, body)
  let scheme = call_613368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613368.url(scheme.get, call_613368.host, call_613368.base,
                         call_613368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613368, url, valid)

proc call*(call_613369: Call_ListBundles_613356; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_613370 = newJObject()
  add(query_613370, "nextToken", newJString(nextToken))
  add(query_613370, "maxResults", newJInt(maxResults))
  result = call_613369.call(nil, query_613370, nil, nil, nil)

var listBundles* = Call_ListBundles_613356(name: "listBundles",
                                        meth: HttpMethod.HttpGet,
                                        host: "mobile.amazonaws.com",
                                        route: "/bundles",
                                        validator: validate_ListBundles_613357,
                                        base: "/", url: url_ListBundles_613358,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_613371 = ref object of OpenApiRestCall_612642
proc url_UpdateProject_613373(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_613372(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613374 = query.getOrDefault("projectId")
  valid_613374 = validateParameter(valid_613374, JString, required = true,
                                 default = nil)
  if valid_613374 != nil:
    section.add "projectId", valid_613374
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
  var valid_613375 = header.getOrDefault("X-Amz-Signature")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Signature", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Content-Sha256", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Date")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Date", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Credential")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Credential", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Security-Token")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Security-Token", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Algorithm")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Algorithm", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-SignedHeaders", valid_613381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613383: Call_UpdateProject_613371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_613383.validator(path, query, header, formData, body)
  let scheme = call_613383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613383.url(scheme.get, call_613383.host, call_613383.base,
                         call_613383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613383, url, valid)

proc call*(call_613384: Call_UpdateProject_613371; body: JsonNode; projectId: string): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   body: JObject (required)
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_613385 = newJObject()
  var body_613386 = newJObject()
  if body != nil:
    body_613386 = body
  add(query_613385, "projectId", newJString(projectId))
  result = call_613384.call(nil, query_613385, nil, nil, body_613386)

var updateProject* = Call_UpdateProject_613371(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_613372, base: "/",
    url: url_UpdateProject_613373, schemes: {Scheme.Https, Scheme.Http})
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
