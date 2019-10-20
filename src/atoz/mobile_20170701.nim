
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateProject_592944 = ref object of OpenApiRestCall_592348
proc url_CreateProject_592946(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_592945(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592947 = query.getOrDefault("name")
  valid_592947 = validateParameter(valid_592947, JString, required = false,
                                 default = nil)
  if valid_592947 != nil:
    section.add "name", valid_592947
  var valid_592948 = query.getOrDefault("region")
  valid_592948 = validateParameter(valid_592948, JString, required = false,
                                 default = nil)
  if valid_592948 != nil:
    section.add "region", valid_592948
  var valid_592949 = query.getOrDefault("snapshotId")
  valid_592949 = validateParameter(valid_592949, JString, required = false,
                                 default = nil)
  if valid_592949 != nil:
    section.add "snapshotId", valid_592949
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
  var valid_592950 = header.getOrDefault("X-Amz-Signature")
  valid_592950 = validateParameter(valid_592950, JString, required = false,
                                 default = nil)
  if valid_592950 != nil:
    section.add "X-Amz-Signature", valid_592950
  var valid_592951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592951 = validateParameter(valid_592951, JString, required = false,
                                 default = nil)
  if valid_592951 != nil:
    section.add "X-Amz-Content-Sha256", valid_592951
  var valid_592952 = header.getOrDefault("X-Amz-Date")
  valid_592952 = validateParameter(valid_592952, JString, required = false,
                                 default = nil)
  if valid_592952 != nil:
    section.add "X-Amz-Date", valid_592952
  var valid_592953 = header.getOrDefault("X-Amz-Credential")
  valid_592953 = validateParameter(valid_592953, JString, required = false,
                                 default = nil)
  if valid_592953 != nil:
    section.add "X-Amz-Credential", valid_592953
  var valid_592954 = header.getOrDefault("X-Amz-Security-Token")
  valid_592954 = validateParameter(valid_592954, JString, required = false,
                                 default = nil)
  if valid_592954 != nil:
    section.add "X-Amz-Security-Token", valid_592954
  var valid_592955 = header.getOrDefault("X-Amz-Algorithm")
  valid_592955 = validateParameter(valid_592955, JString, required = false,
                                 default = nil)
  if valid_592955 != nil:
    section.add "X-Amz-Algorithm", valid_592955
  var valid_592956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592956 = validateParameter(valid_592956, JString, required = false,
                                 default = nil)
  if valid_592956 != nil:
    section.add "X-Amz-SignedHeaders", valid_592956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592958: Call_CreateProject_592944; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_592958.validator(path, query, header, formData, body)
  let scheme = call_592958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592958.url(scheme.get, call_592958.host, call_592958.base,
                         call_592958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592958, url, valid)

proc call*(call_592959: Call_CreateProject_592944; body: JsonNode; name: string = "";
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
  var query_592960 = newJObject()
  var body_592961 = newJObject()
  add(query_592960, "name", newJString(name))
  add(query_592960, "region", newJString(region))
  add(query_592960, "snapshotId", newJString(snapshotId))
  if body != nil:
    body_592961 = body
  result = call_592959.call(nil, query_592960, nil, nil, body_592961)

var createProject* = Call_CreateProject_592944(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_592945, base: "/", url: url_CreateProject_592946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_592687 = ref object of OpenApiRestCall_592348
proc url_ListProjects_592689(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_592688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592801 = query.getOrDefault("nextToken")
  valid_592801 = validateParameter(valid_592801, JString, required = false,
                                 default = nil)
  if valid_592801 != nil:
    section.add "nextToken", valid_592801
  var valid_592802 = query.getOrDefault("maxResults")
  valid_592802 = validateParameter(valid_592802, JInt, required = false, default = nil)
  if valid_592802 != nil:
    section.add "maxResults", valid_592802
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
  var valid_592803 = header.getOrDefault("X-Amz-Signature")
  valid_592803 = validateParameter(valid_592803, JString, required = false,
                                 default = nil)
  if valid_592803 != nil:
    section.add "X-Amz-Signature", valid_592803
  var valid_592804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592804 = validateParameter(valid_592804, JString, required = false,
                                 default = nil)
  if valid_592804 != nil:
    section.add "X-Amz-Content-Sha256", valid_592804
  var valid_592805 = header.getOrDefault("X-Amz-Date")
  valid_592805 = validateParameter(valid_592805, JString, required = false,
                                 default = nil)
  if valid_592805 != nil:
    section.add "X-Amz-Date", valid_592805
  var valid_592806 = header.getOrDefault("X-Amz-Credential")
  valid_592806 = validateParameter(valid_592806, JString, required = false,
                                 default = nil)
  if valid_592806 != nil:
    section.add "X-Amz-Credential", valid_592806
  var valid_592807 = header.getOrDefault("X-Amz-Security-Token")
  valid_592807 = validateParameter(valid_592807, JString, required = false,
                                 default = nil)
  if valid_592807 != nil:
    section.add "X-Amz-Security-Token", valid_592807
  var valid_592808 = header.getOrDefault("X-Amz-Algorithm")
  valid_592808 = validateParameter(valid_592808, JString, required = false,
                                 default = nil)
  if valid_592808 != nil:
    section.add "X-Amz-Algorithm", valid_592808
  var valid_592809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592809 = validateParameter(valid_592809, JString, required = false,
                                 default = nil)
  if valid_592809 != nil:
    section.add "X-Amz-SignedHeaders", valid_592809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592832: Call_ListProjects_592687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_592832.validator(path, query, header, formData, body)
  let scheme = call_592832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592832.url(scheme.get, call_592832.host, call_592832.base,
                         call_592832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592832, url, valid)

proc call*(call_592903: Call_ListProjects_592687; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_592904 = newJObject()
  add(query_592904, "nextToken", newJString(nextToken))
  add(query_592904, "maxResults", newJInt(maxResults))
  result = call_592903.call(nil, query_592904, nil, nil, nil)

var listProjects* = Call_ListProjects_592687(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_592688, base: "/", url: url_ListProjects_592689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_592962 = ref object of OpenApiRestCall_592348
proc url_DeleteProject_592964(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteProject_592963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592979 = path.getOrDefault("projectId")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = nil)
  if valid_592979 != nil:
    section.add "projectId", valid_592979
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
  var valid_592980 = header.getOrDefault("X-Amz-Signature")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Signature", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Content-Sha256", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Date")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Date", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Credential")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Credential", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Security-Token")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Security-Token", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Algorithm")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Algorithm", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-SignedHeaders", valid_592986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_DeleteProject_592962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_DeleteProject_592962; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_592989 = newJObject()
  add(path_592989, "projectId", newJString(projectId))
  result = call_592988.call(path_592989, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_592962(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_592963,
    base: "/", url: url_DeleteProject_592964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_593004 = ref object of OpenApiRestCall_592348
proc url_ExportBundle_593006(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ExportBundle_593005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593007 = path.getOrDefault("bundleId")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "bundleId", valid_593007
  result.add "path", section
  ## parameters in `query` object:
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: JString
  ##            :  Unique project identifier. 
  section = newJObject()
  var valid_593021 = query.getOrDefault("platform")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = newJString("OSX"))
  if valid_593021 != nil:
    section.add "platform", valid_593021
  var valid_593022 = query.getOrDefault("projectId")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "projectId", valid_593022
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
  var valid_593023 = header.getOrDefault("X-Amz-Signature")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Signature", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Content-Sha256", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Date")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Date", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Credential")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Credential", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Security-Token")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Security-Token", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Algorithm")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Algorithm", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-SignedHeaders", valid_593029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593030: Call_ExportBundle_593004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_593030.validator(path, query, header, formData, body)
  let scheme = call_593030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593030.url(scheme.get, call_593030.host, call_593030.base,
                         call_593030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593030, url, valid)

proc call*(call_593031: Call_ExportBundle_593004; bundleId: string;
          platform: string = "OSX"; projectId: string = ""): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  var path_593032 = newJObject()
  var query_593033 = newJObject()
  add(path_593032, "bundleId", newJString(bundleId))
  add(query_593033, "platform", newJString(platform))
  add(query_593033, "projectId", newJString(projectId))
  result = call_593031.call(path_593032, query_593033, nil, nil, nil)

var exportBundle* = Call_ExportBundle_593004(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_593005,
    base: "/", url: url_ExportBundle_593006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_592990 = ref object of OpenApiRestCall_592348
proc url_DescribeBundle_592992(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeBundle_592991(path: JsonNode; query: JsonNode;
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
  var valid_592993 = path.getOrDefault("bundleId")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "bundleId", valid_592993
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
  var valid_592994 = header.getOrDefault("X-Amz-Signature")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Signature", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Content-Sha256", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Date")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Date", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Credential")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Credential", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Security-Token")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Security-Token", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Algorithm")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Algorithm", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-SignedHeaders", valid_593000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593001: Call_DescribeBundle_592990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_593001.validator(path, query, header, formData, body)
  let scheme = call_593001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593001.url(scheme.get, call_593001.host, call_593001.base,
                         call_593001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593001, url, valid)

proc call*(call_593002: Call_DescribeBundle_592990; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_593003 = newJObject()
  add(path_593003, "bundleId", newJString(bundleId))
  result = call_593002.call(path_593003, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_592990(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_592991,
    base: "/", url: url_DescribeBundle_592992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_593034 = ref object of OpenApiRestCall_592348
proc url_DescribeProject_593036(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProject_593035(path: JsonNode; query: JsonNode;
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
  var valid_593037 = query.getOrDefault("syncFromResources")
  valid_593037 = validateParameter(valid_593037, JBool, required = false, default = nil)
  if valid_593037 != nil:
    section.add "syncFromResources", valid_593037
  assert query != nil,
        "query argument is necessary due to required `projectId` field"
  var valid_593038 = query.getOrDefault("projectId")
  valid_593038 = validateParameter(valid_593038, JString, required = true,
                                 default = nil)
  if valid_593038 != nil:
    section.add "projectId", valid_593038
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
  var valid_593039 = header.getOrDefault("X-Amz-Signature")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Signature", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Content-Sha256", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Date")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Date", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Credential")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Credential", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Security-Token")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Security-Token", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Algorithm")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Algorithm", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-SignedHeaders", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_DescribeProject_593034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_DescribeProject_593034; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_593048 = newJObject()
  add(query_593048, "syncFromResources", newJBool(syncFromResources))
  add(query_593048, "projectId", newJString(projectId))
  result = call_593047.call(nil, query_593048, nil, nil, nil)

var describeProject* = Call_DescribeProject_593034(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_593035,
    base: "/", url: url_DescribeProject_593036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_593049 = ref object of OpenApiRestCall_592348
proc url_ExportProject_593051(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ExportProject_593050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593052 = path.getOrDefault("projectId")
  valid_593052 = validateParameter(valid_593052, JString, required = true,
                                 default = nil)
  if valid_593052 != nil:
    section.add "projectId", valid_593052
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
  var valid_593053 = header.getOrDefault("X-Amz-Signature")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Signature", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Content-Sha256", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Date")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Date", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Credential")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Credential", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Security-Token")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Security-Token", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Algorithm")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Algorithm", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-SignedHeaders", valid_593059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_ExportProject_593049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_ExportProject_593049; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_593062 = newJObject()
  add(path_593062, "projectId", newJString(projectId))
  result = call_593061.call(path_593062, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_593049(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_593050,
    base: "/", url: url_ExportProject_593051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_593063 = ref object of OpenApiRestCall_592348
proc url_ListBundles_593065(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBundles_593064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593066 = query.getOrDefault("nextToken")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "nextToken", valid_593066
  var valid_593067 = query.getOrDefault("maxResults")
  valid_593067 = validateParameter(valid_593067, JInt, required = false, default = nil)
  if valid_593067 != nil:
    section.add "maxResults", valid_593067
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
  var valid_593068 = header.getOrDefault("X-Amz-Signature")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Signature", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Content-Sha256", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Date")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Date", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Credential")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Credential", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Security-Token")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Security-Token", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Algorithm")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Algorithm", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-SignedHeaders", valid_593074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_ListBundles_593063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_ListBundles_593063; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_593077 = newJObject()
  add(query_593077, "nextToken", newJString(nextToken))
  add(query_593077, "maxResults", newJInt(maxResults))
  result = call_593076.call(nil, query_593077, nil, nil, nil)

var listBundles* = Call_ListBundles_593063(name: "listBundles",
                                        meth: HttpMethod.HttpGet,
                                        host: "mobile.amazonaws.com",
                                        route: "/bundles",
                                        validator: validate_ListBundles_593064,
                                        base: "/", url: url_ListBundles_593065,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_593078 = ref object of OpenApiRestCall_592348
proc url_UpdateProject_593080(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_593079(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593081 = query.getOrDefault("projectId")
  valid_593081 = validateParameter(valid_593081, JString, required = true,
                                 default = nil)
  if valid_593081 != nil:
    section.add "projectId", valid_593081
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
  var valid_593082 = header.getOrDefault("X-Amz-Signature")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Signature", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Content-Sha256", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Date")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Date", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Credential")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Credential", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Security-Token")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Security-Token", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Algorithm")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Algorithm", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-SignedHeaders", valid_593088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593090: Call_UpdateProject_593078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_UpdateProject_593078; body: JsonNode; projectId: string): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   body: JObject (required)
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var query_593092 = newJObject()
  var body_593093 = newJObject()
  if body != nil:
    body_593093 = body
  add(query_593092, "projectId", newJString(projectId))
  result = call_593091.call(nil, query_593092, nil, nil, body_593093)

var updateProject* = Call_UpdateProject_593078(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_593079, base: "/",
    url: url_UpdateProject_593080, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
