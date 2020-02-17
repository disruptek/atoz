
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateProject_611237 = ref object of OpenApiRestCall_610642
proc url_CreateProject_611239(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_611238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611240 = query.getOrDefault("name")
  valid_611240 = validateParameter(valid_611240, JString, required = false,
                                 default = nil)
  if valid_611240 != nil:
    section.add "name", valid_611240
  var valid_611241 = query.getOrDefault("region")
  valid_611241 = validateParameter(valid_611241, JString, required = false,
                                 default = nil)
  if valid_611241 != nil:
    section.add "region", valid_611241
  var valid_611242 = query.getOrDefault("snapshotId")
  valid_611242 = validateParameter(valid_611242, JString, required = false,
                                 default = nil)
  if valid_611242 != nil:
    section.add "snapshotId", valid_611242
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
  var valid_611243 = header.getOrDefault("X-Amz-Signature")
  valid_611243 = validateParameter(valid_611243, JString, required = false,
                                 default = nil)
  if valid_611243 != nil:
    section.add "X-Amz-Signature", valid_611243
  var valid_611244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611244 = validateParameter(valid_611244, JString, required = false,
                                 default = nil)
  if valid_611244 != nil:
    section.add "X-Amz-Content-Sha256", valid_611244
  var valid_611245 = header.getOrDefault("X-Amz-Date")
  valid_611245 = validateParameter(valid_611245, JString, required = false,
                                 default = nil)
  if valid_611245 != nil:
    section.add "X-Amz-Date", valid_611245
  var valid_611246 = header.getOrDefault("X-Amz-Credential")
  valid_611246 = validateParameter(valid_611246, JString, required = false,
                                 default = nil)
  if valid_611246 != nil:
    section.add "X-Amz-Credential", valid_611246
  var valid_611247 = header.getOrDefault("X-Amz-Security-Token")
  valid_611247 = validateParameter(valid_611247, JString, required = false,
                                 default = nil)
  if valid_611247 != nil:
    section.add "X-Amz-Security-Token", valid_611247
  var valid_611248 = header.getOrDefault("X-Amz-Algorithm")
  valid_611248 = validateParameter(valid_611248, JString, required = false,
                                 default = nil)
  if valid_611248 != nil:
    section.add "X-Amz-Algorithm", valid_611248
  var valid_611249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611249 = validateParameter(valid_611249, JString, required = false,
                                 default = nil)
  if valid_611249 != nil:
    section.add "X-Amz-SignedHeaders", valid_611249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611251: Call_CreateProject_611237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_611251.validator(path, query, header, formData, body)
  let scheme = call_611251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611251.url(scheme.get, call_611251.host, call_611251.base,
                         call_611251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611251, url, valid)

proc call*(call_611252: Call_CreateProject_611237; body: JsonNode; name: string = "";
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
  var query_611253 = newJObject()
  var body_611254 = newJObject()
  add(query_611253, "name", newJString(name))
  add(query_611253, "region", newJString(region))
  add(query_611253, "snapshotId", newJString(snapshotId))
  if body != nil:
    body_611254 = body
  result = call_611252.call(nil, query_611253, nil, nil, body_611254)

var createProject* = Call_CreateProject_611237(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_611238, base: "/", url: url_CreateProject_611239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_610980 = ref object of OpenApiRestCall_610642
proc url_ListProjects_610982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_610981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611094 = query.getOrDefault("nextToken")
  valid_611094 = validateParameter(valid_611094, JString, required = false,
                                 default = nil)
  if valid_611094 != nil:
    section.add "nextToken", valid_611094
  var valid_611095 = query.getOrDefault("maxResults")
  valid_611095 = validateParameter(valid_611095, JInt, required = false, default = nil)
  if valid_611095 != nil:
    section.add "maxResults", valid_611095
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
  var valid_611096 = header.getOrDefault("X-Amz-Signature")
  valid_611096 = validateParameter(valid_611096, JString, required = false,
                                 default = nil)
  if valid_611096 != nil:
    section.add "X-Amz-Signature", valid_611096
  var valid_611097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611097 = validateParameter(valid_611097, JString, required = false,
                                 default = nil)
  if valid_611097 != nil:
    section.add "X-Amz-Content-Sha256", valid_611097
  var valid_611098 = header.getOrDefault("X-Amz-Date")
  valid_611098 = validateParameter(valid_611098, JString, required = false,
                                 default = nil)
  if valid_611098 != nil:
    section.add "X-Amz-Date", valid_611098
  var valid_611099 = header.getOrDefault("X-Amz-Credential")
  valid_611099 = validateParameter(valid_611099, JString, required = false,
                                 default = nil)
  if valid_611099 != nil:
    section.add "X-Amz-Credential", valid_611099
  var valid_611100 = header.getOrDefault("X-Amz-Security-Token")
  valid_611100 = validateParameter(valid_611100, JString, required = false,
                                 default = nil)
  if valid_611100 != nil:
    section.add "X-Amz-Security-Token", valid_611100
  var valid_611101 = header.getOrDefault("X-Amz-Algorithm")
  valid_611101 = validateParameter(valid_611101, JString, required = false,
                                 default = nil)
  if valid_611101 != nil:
    section.add "X-Amz-Algorithm", valid_611101
  var valid_611102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "X-Amz-SignedHeaders", valid_611102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611125: Call_ListProjects_610980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_611125.validator(path, query, header, formData, body)
  let scheme = call_611125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611125.url(scheme.get, call_611125.host, call_611125.base,
                         call_611125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611125, url, valid)

proc call*(call_611196: Call_ListProjects_610980; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_611197 = newJObject()
  add(query_611197, "nextToken", newJString(nextToken))
  add(query_611197, "maxResults", newJInt(maxResults))
  result = call_611196.call(nil, query_611197, nil, nil, nil)

var listProjects* = Call_ListProjects_610980(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_610981, base: "/", url: url_ListProjects_610982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_611255 = ref object of OpenApiRestCall_610642
proc url_DeleteProject_611257(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_611256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611272 = path.getOrDefault("projectId")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = nil)
  if valid_611272 != nil:
    section.add "projectId", valid_611272
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
  var valid_611273 = header.getOrDefault("X-Amz-Signature")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Signature", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Content-Sha256", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Date")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Date", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Credential")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Credential", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Security-Token")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Security-Token", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Algorithm")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Algorithm", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-SignedHeaders", valid_611279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_DeleteProject_611255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_DeleteProject_611255; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_611282 = newJObject()
  add(path_611282, "projectId", newJString(projectId))
  result = call_611281.call(path_611282, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_611255(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_611256,
    base: "/", url: url_DeleteProject_611257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_611297 = ref object of OpenApiRestCall_610642
proc url_ExportBundle_611299(protocol: Scheme; host: string; base: string;
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

proc validate_ExportBundle_611298(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611300 = path.getOrDefault("bundleId")
  valid_611300 = validateParameter(valid_611300, JString, required = true,
                                 default = nil)
  if valid_611300 != nil:
    section.add "bundleId", valid_611300
  result.add "path", section
  ## parameters in `query` object:
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: JString
  ##            :  Unique project identifier. 
  section = newJObject()
  var valid_611314 = query.getOrDefault("platform")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = newJString("OSX"))
  if valid_611314 != nil:
    section.add "platform", valid_611314
  var valid_611315 = query.getOrDefault("projectId")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "projectId", valid_611315
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
  var valid_611316 = header.getOrDefault("X-Amz-Signature")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Signature", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Content-Sha256", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Date")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Date", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Credential")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Credential", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Security-Token")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Security-Token", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611323: Call_ExportBundle_611297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_611323.validator(path, query, header, formData, body)
  let scheme = call_611323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611323.url(scheme.get, call_611323.host, call_611323.base,
                         call_611323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611323, url, valid)

proc call*(call_611324: Call_ExportBundle_611297; bundleId: string;
          platform: string = "OSX"; projectId: string = ""): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  var path_611325 = newJObject()
  var query_611326 = newJObject()
  add(path_611325, "bundleId", newJString(bundleId))
  add(query_611326, "platform", newJString(platform))
  add(query_611326, "projectId", newJString(projectId))
  result = call_611324.call(path_611325, query_611326, nil, nil, nil)

var exportBundle* = Call_ExportBundle_611297(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_611298,
    base: "/", url: url_ExportBundle_611299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_611283 = ref object of OpenApiRestCall_610642
proc url_DescribeBundle_611285(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBundle_611284(path: JsonNode; query: JsonNode;
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
  var valid_611286 = path.getOrDefault("bundleId")
  valid_611286 = validateParameter(valid_611286, JString, required = true,
                                 default = nil)
  if valid_611286 != nil:
    section.add "bundleId", valid_611286
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
  var valid_611287 = header.getOrDefault("X-Amz-Signature")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Signature", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Content-Sha256", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Date")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Date", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Credential")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Credential", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Security-Token")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Security-Token", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Algorithm")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Algorithm", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-SignedHeaders", valid_611293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611294: Call_DescribeBundle_611283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_611294.validator(path, query, header, formData, body)
  let scheme = call_611294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611294.url(scheme.get, call_611294.host, call_611294.base,
                         call_611294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611294, url, valid)

proc call*(call_611295: Call_DescribeBundle_611283; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_611296 = newJObject()
  add(path_611296, "bundleId", newJString(bundleId))
  result = call_611295.call(path_611296, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_611283(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_611284,
    base: "/", url: url_DescribeBundle_611285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_611327 = ref object of OpenApiRestCall_610642
proc url_DescribeProject_611329(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProject_611328(path: JsonNode; query: JsonNode;
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
  var valid_611330 = query.getOrDefault("syncFromResources")
  valid_611330 = validateParameter(valid_611330, JBool, required = false, default = nil)
  if valid_611330 != nil:
    section.add "syncFromResources", valid_611330
  assert query != nil,
        "query argument is necessary due to required `projectId` field"
  var valid_611331 = query.getOrDefault("projectId")
  valid_611331 = validateParameter(valid_611331, JString, required = true,
                                 default = nil)
  if valid_611331 != nil:
    section.add "projectId", valid_611331
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
  var valid_611332 = header.getOrDefault("X-Amz-Signature")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Signature", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Content-Sha256", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Date")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Date", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Credential")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Credential", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Security-Token")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Security-Token", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Algorithm")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Algorithm", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-SignedHeaders", valid_611338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611339: Call_DescribeProject_611327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_611339.validator(path, query, header, formData, body)
  let scheme = call_611339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611339.url(scheme.get, call_611339.host, call_611339.base,
                         call_611339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611339, url, valid)

proc call*(call_611340: Call_DescribeProject_611327; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_611341 = newJObject()
  add(query_611341, "syncFromResources", newJBool(syncFromResources))
  add(query_611341, "projectId", newJString(projectId))
  result = call_611340.call(nil, query_611341, nil, nil, nil)

var describeProject* = Call_DescribeProject_611327(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_611328,
    base: "/", url: url_DescribeProject_611329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_611342 = ref object of OpenApiRestCall_610642
proc url_ExportProject_611344(protocol: Scheme; host: string; base: string;
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

proc validate_ExportProject_611343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611345 = path.getOrDefault("projectId")
  valid_611345 = validateParameter(valid_611345, JString, required = true,
                                 default = nil)
  if valid_611345 != nil:
    section.add "projectId", valid_611345
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
  var valid_611346 = header.getOrDefault("X-Amz-Signature")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Signature", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Content-Sha256", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Date")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Date", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Credential")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Credential", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Security-Token")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Security-Token", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Algorithm")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Algorithm", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-SignedHeaders", valid_611352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611353: Call_ExportProject_611342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_611353.validator(path, query, header, formData, body)
  let scheme = call_611353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611353.url(scheme.get, call_611353.host, call_611353.base,
                         call_611353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611353, url, valid)

proc call*(call_611354: Call_ExportProject_611342; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_611355 = newJObject()
  add(path_611355, "projectId", newJString(projectId))
  result = call_611354.call(path_611355, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_611342(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_611343,
    base: "/", url: url_ExportProject_611344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_611356 = ref object of OpenApiRestCall_610642
proc url_ListBundles_611358(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBundles_611357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611359 = query.getOrDefault("nextToken")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "nextToken", valid_611359
  var valid_611360 = query.getOrDefault("maxResults")
  valid_611360 = validateParameter(valid_611360, JInt, required = false, default = nil)
  if valid_611360 != nil:
    section.add "maxResults", valid_611360
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
  var valid_611361 = header.getOrDefault("X-Amz-Signature")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Signature", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Content-Sha256", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Date")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Date", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Credential")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Credential", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Security-Token")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Security-Token", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Algorithm")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Algorithm", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-SignedHeaders", valid_611367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611368: Call_ListBundles_611356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_611368.validator(path, query, header, formData, body)
  let scheme = call_611368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611368.url(scheme.get, call_611368.host, call_611368.base,
                         call_611368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611368, url, valid)

proc call*(call_611369: Call_ListBundles_611356; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_611370 = newJObject()
  add(query_611370, "nextToken", newJString(nextToken))
  add(query_611370, "maxResults", newJInt(maxResults))
  result = call_611369.call(nil, query_611370, nil, nil, nil)

var listBundles* = Call_ListBundles_611356(name: "listBundles",
                                        meth: HttpMethod.HttpGet,
                                        host: "mobile.amazonaws.com",
                                        route: "/bundles",
                                        validator: validate_ListBundles_611357,
                                        base: "/", url: url_ListBundles_611358,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_611371 = ref object of OpenApiRestCall_610642
proc url_UpdateProject_611373(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_611372(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611374 = query.getOrDefault("projectId")
  valid_611374 = validateParameter(valid_611374, JString, required = true,
                                 default = nil)
  if valid_611374 != nil:
    section.add "projectId", valid_611374
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
  var valid_611375 = header.getOrDefault("X-Amz-Signature")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Signature", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Content-Sha256", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Date")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Date", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Credential")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Credential", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Security-Token")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Security-Token", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Algorithm")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Algorithm", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-SignedHeaders", valid_611381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611383: Call_UpdateProject_611371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_611383.validator(path, query, header, formData, body)
  let scheme = call_611383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611383.url(scheme.get, call_611383.host, call_611383.base,
                         call_611383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611383, url, valid)

proc call*(call_611384: Call_UpdateProject_611371; body: JsonNode; projectId: string): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   body: JObject (required)
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_611385 = newJObject()
  var body_611386 = newJObject()
  if body != nil:
    body_611386 = body
  add(query_611385, "projectId", newJString(projectId))
  result = call_611384.call(nil, query_611385, nil, nil, body_611386)

var updateProject* = Call_UpdateProject_611371(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_611372, base: "/",
    url: url_UpdateProject_611373, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
