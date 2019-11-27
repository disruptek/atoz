
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_CreateProject_599946 = ref object of OpenApiRestCall_599352
proc url_CreateProject_599948(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_599947(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599949 = query.getOrDefault("snapshotId")
  valid_599949 = validateParameter(valid_599949, JString, required = false,
                                 default = nil)
  if valid_599949 != nil:
    section.add "snapshotId", valid_599949
  var valid_599950 = query.getOrDefault("name")
  valid_599950 = validateParameter(valid_599950, JString, required = false,
                                 default = nil)
  if valid_599950 != nil:
    section.add "name", valid_599950
  var valid_599951 = query.getOrDefault("region")
  valid_599951 = validateParameter(valid_599951, JString, required = false,
                                 default = nil)
  if valid_599951 != nil:
    section.add "region", valid_599951
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
  var valid_599952 = header.getOrDefault("X-Amz-Date")
  valid_599952 = validateParameter(valid_599952, JString, required = false,
                                 default = nil)
  if valid_599952 != nil:
    section.add "X-Amz-Date", valid_599952
  var valid_599953 = header.getOrDefault("X-Amz-Security-Token")
  valid_599953 = validateParameter(valid_599953, JString, required = false,
                                 default = nil)
  if valid_599953 != nil:
    section.add "X-Amz-Security-Token", valid_599953
  var valid_599954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599954 = validateParameter(valid_599954, JString, required = false,
                                 default = nil)
  if valid_599954 != nil:
    section.add "X-Amz-Content-Sha256", valid_599954
  var valid_599955 = header.getOrDefault("X-Amz-Algorithm")
  valid_599955 = validateParameter(valid_599955, JString, required = false,
                                 default = nil)
  if valid_599955 != nil:
    section.add "X-Amz-Algorithm", valid_599955
  var valid_599956 = header.getOrDefault("X-Amz-Signature")
  valid_599956 = validateParameter(valid_599956, JString, required = false,
                                 default = nil)
  if valid_599956 != nil:
    section.add "X-Amz-Signature", valid_599956
  var valid_599957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599957 = validateParameter(valid_599957, JString, required = false,
                                 default = nil)
  if valid_599957 != nil:
    section.add "X-Amz-SignedHeaders", valid_599957
  var valid_599958 = header.getOrDefault("X-Amz-Credential")
  valid_599958 = validateParameter(valid_599958, JString, required = false,
                                 default = nil)
  if valid_599958 != nil:
    section.add "X-Amz-Credential", valid_599958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599960: Call_CreateProject_599946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_599960.validator(path, query, header, formData, body)
  let scheme = call_599960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599960.url(scheme.get, call_599960.host, call_599960.base,
                         call_599960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599960, url, valid)

proc call*(call_599961: Call_CreateProject_599946; body: JsonNode;
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
  var query_599962 = newJObject()
  var body_599963 = newJObject()
  add(query_599962, "snapshotId", newJString(snapshotId))
  add(query_599962, "name", newJString(name))
  add(query_599962, "region", newJString(region))
  if body != nil:
    body_599963 = body
  result = call_599961.call(nil, query_599962, nil, nil, body_599963)

var createProject* = Call_CreateProject_599946(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_599947, base: "/", url: url_CreateProject_599948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_599689 = ref object of OpenApiRestCall_599352
proc url_ListProjects_599691(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_599690(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599803 = query.getOrDefault("maxResults")
  valid_599803 = validateParameter(valid_599803, JInt, required = false, default = nil)
  if valid_599803 != nil:
    section.add "maxResults", valid_599803
  var valid_599804 = query.getOrDefault("nextToken")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "nextToken", valid_599804
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
  var valid_599805 = header.getOrDefault("X-Amz-Date")
  valid_599805 = validateParameter(valid_599805, JString, required = false,
                                 default = nil)
  if valid_599805 != nil:
    section.add "X-Amz-Date", valid_599805
  var valid_599806 = header.getOrDefault("X-Amz-Security-Token")
  valid_599806 = validateParameter(valid_599806, JString, required = false,
                                 default = nil)
  if valid_599806 != nil:
    section.add "X-Amz-Security-Token", valid_599806
  var valid_599807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599807 = validateParameter(valid_599807, JString, required = false,
                                 default = nil)
  if valid_599807 != nil:
    section.add "X-Amz-Content-Sha256", valid_599807
  var valid_599808 = header.getOrDefault("X-Amz-Algorithm")
  valid_599808 = validateParameter(valid_599808, JString, required = false,
                                 default = nil)
  if valid_599808 != nil:
    section.add "X-Amz-Algorithm", valid_599808
  var valid_599809 = header.getOrDefault("X-Amz-Signature")
  valid_599809 = validateParameter(valid_599809, JString, required = false,
                                 default = nil)
  if valid_599809 != nil:
    section.add "X-Amz-Signature", valid_599809
  var valid_599810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-SignedHeaders", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Credential")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Credential", valid_599811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599834: Call_ListProjects_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_599834.validator(path, query, header, formData, body)
  let scheme = call_599834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599834.url(scheme.get, call_599834.host, call_599834.base,
                         call_599834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599834, url, valid)

proc call*(call_599905: Call_ListProjects_599689; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_599906 = newJObject()
  add(query_599906, "maxResults", newJInt(maxResults))
  add(query_599906, "nextToken", newJString(nextToken))
  result = call_599905.call(nil, query_599906, nil, nil, nil)

var listProjects* = Call_ListProjects_599689(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_599690, base: "/", url: url_ListProjects_599691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_599964 = ref object of OpenApiRestCall_599352
proc url_DeleteProject_599966(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_599965(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599981 = path.getOrDefault("projectId")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = nil)
  if valid_599981 != nil:
    section.add "projectId", valid_599981
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
  var valid_599982 = header.getOrDefault("X-Amz-Date")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Date", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Security-Token")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Security-Token", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Content-Sha256", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Algorithm")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Algorithm", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Signature")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Signature", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-SignedHeaders", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Credential")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Credential", valid_599988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599989: Call_DeleteProject_599964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_599989.validator(path, query, header, formData, body)
  let scheme = call_599989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599989.url(scheme.get, call_599989.host, call_599989.base,
                         call_599989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599989, url, valid)

proc call*(call_599990: Call_DeleteProject_599964; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_599991 = newJObject()
  add(path_599991, "projectId", newJString(projectId))
  result = call_599990.call(path_599991, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_599964(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_599965,
    base: "/", url: url_DeleteProject_599966, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_600006 = ref object of OpenApiRestCall_599352
proc url_ExportBundle_600008(protocol: Scheme; host: string; base: string;
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

proc validate_ExportBundle_600007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600009 = path.getOrDefault("bundleId")
  valid_600009 = validateParameter(valid_600009, JString, required = true,
                                 default = nil)
  if valid_600009 != nil:
    section.add "bundleId", valid_600009
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString
  ##            :  Unique project identifier. 
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  section = newJObject()
  var valid_600010 = query.getOrDefault("projectId")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "projectId", valid_600010
  var valid_600024 = query.getOrDefault("platform")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = newJString("OSX"))
  if valid_600024 != nil:
    section.add "platform", valid_600024
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
  var valid_600025 = header.getOrDefault("X-Amz-Date")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Date", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Security-Token")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Security-Token", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Content-Sha256", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Algorithm")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Algorithm", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Signature")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Signature", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-SignedHeaders", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Credential")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Credential", valid_600031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_ExportBundle_600006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_ExportBundle_600006; bundleId: string;
          projectId: string = ""; platform: string = "OSX"): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  var path_600034 = newJObject()
  var query_600035 = newJObject()
  add(path_600034, "bundleId", newJString(bundleId))
  add(query_600035, "projectId", newJString(projectId))
  add(query_600035, "platform", newJString(platform))
  result = call_600033.call(path_600034, query_600035, nil, nil, nil)

var exportBundle* = Call_ExportBundle_600006(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_600007,
    base: "/", url: url_ExportBundle_600008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_599992 = ref object of OpenApiRestCall_599352
proc url_DescribeBundle_599994(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBundle_599993(path: JsonNode; query: JsonNode;
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
  var valid_599995 = path.getOrDefault("bundleId")
  valid_599995 = validateParameter(valid_599995, JString, required = true,
                                 default = nil)
  if valid_599995 != nil:
    section.add "bundleId", valid_599995
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
  var valid_599996 = header.getOrDefault("X-Amz-Date")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Date", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Security-Token")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Security-Token", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Content-Sha256", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Algorithm")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Algorithm", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Signature")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Signature", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-SignedHeaders", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Credential")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Credential", valid_600002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600003: Call_DescribeBundle_599992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_600003.validator(path, query, header, formData, body)
  let scheme = call_600003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600003.url(scheme.get, call_600003.host, call_600003.base,
                         call_600003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600003, url, valid)

proc call*(call_600004: Call_DescribeBundle_599992; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_600005 = newJObject()
  add(path_600005, "bundleId", newJString(bundleId))
  result = call_600004.call(path_600005, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_599992(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_599993,
    base: "/", url: url_DescribeBundle_599994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_600036 = ref object of OpenApiRestCall_599352
proc url_DescribeProject_600038(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProject_600037(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600039 = query.getOrDefault("projectId")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = nil)
  if valid_600039 != nil:
    section.add "projectId", valid_600039
  var valid_600040 = query.getOrDefault("syncFromResources")
  valid_600040 = validateParameter(valid_600040, JBool, required = false, default = nil)
  if valid_600040 != nil:
    section.add "syncFromResources", valid_600040
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
  var valid_600041 = header.getOrDefault("X-Amz-Date")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Date", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Security-Token")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Security-Token", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Content-Sha256", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Algorithm")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Algorithm", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Signature")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Signature", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-SignedHeaders", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Credential")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Credential", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600048: Call_DescribeProject_600036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_600048.validator(path, query, header, formData, body)
  let scheme = call_600048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600048.url(scheme.get, call_600048.host, call_600048.base,
                         call_600048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600048, url, valid)

proc call*(call_600049: Call_DescribeProject_600036; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  var query_600050 = newJObject()
  add(query_600050, "projectId", newJString(projectId))
  add(query_600050, "syncFromResources", newJBool(syncFromResources))
  result = call_600049.call(nil, query_600050, nil, nil, nil)

var describeProject* = Call_DescribeProject_600036(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_600037,
    base: "/", url: url_DescribeProject_600038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_600051 = ref object of OpenApiRestCall_599352
proc url_ExportProject_600053(protocol: Scheme; host: string; base: string;
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

proc validate_ExportProject_600052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600054 = path.getOrDefault("projectId")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = nil)
  if valid_600054 != nil:
    section.add "projectId", valid_600054
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
  var valid_600055 = header.getOrDefault("X-Amz-Date")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Date", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Security-Token")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Security-Token", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Content-Sha256", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Algorithm")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Algorithm", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Signature")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Signature", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-SignedHeaders", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Credential")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Credential", valid_600061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_ExportProject_600051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_ExportProject_600051; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_600064 = newJObject()
  add(path_600064, "projectId", newJString(projectId))
  result = call_600063.call(path_600064, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_600051(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_600052,
    base: "/", url: url_ExportProject_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_600065 = ref object of OpenApiRestCall_599352
proc url_ListBundles_600067(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBundles_600066(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600068 = query.getOrDefault("maxResults")
  valid_600068 = validateParameter(valid_600068, JInt, required = false, default = nil)
  if valid_600068 != nil:
    section.add "maxResults", valid_600068
  var valid_600069 = query.getOrDefault("nextToken")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "nextToken", valid_600069
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
  var valid_600070 = header.getOrDefault("X-Amz-Date")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Date", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Security-Token")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Security-Token", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Content-Sha256", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Algorithm")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Algorithm", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Signature")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Signature", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-SignedHeaders", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Credential")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Credential", valid_600076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_ListBundles_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_ListBundles_600065; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_600079 = newJObject()
  add(query_600079, "maxResults", newJInt(maxResults))
  add(query_600079, "nextToken", newJString(nextToken))
  result = call_600078.call(nil, query_600079, nil, nil, nil)

var listBundles* = Call_ListBundles_600065(name: "listBundles",
                                        meth: HttpMethod.HttpGet,
                                        host: "mobile.amazonaws.com",
                                        route: "/bundles",
                                        validator: validate_ListBundles_600066,
                                        base: "/", url: url_ListBundles_600067,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_600080 = ref object of OpenApiRestCall_599352
proc url_UpdateProject_600082(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_600081(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600083 = query.getOrDefault("projectId")
  valid_600083 = validateParameter(valid_600083, JString, required = true,
                                 default = nil)
  if valid_600083 != nil:
    section.add "projectId", valid_600083
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
  var valid_600084 = header.getOrDefault("X-Amz-Date")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Date", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Security-Token")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Security-Token", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Content-Sha256", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Algorithm")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Algorithm", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Signature")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Signature", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-SignedHeaders", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Credential")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Credential", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_UpdateProject_600080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_UpdateProject_600080; projectId: string; body: JsonNode): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   body: JObject (required)
  var query_600094 = newJObject()
  var body_600095 = newJObject()
  add(query_600094, "projectId", newJString(projectId))
  if body != nil:
    body_600095 = body
  result = call_600093.call(nil, query_600094, nil, nil, body_600095)

var updateProject* = Call_UpdateProject_600080(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_600081, base: "/",
    url: url_UpdateProject_600082, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
