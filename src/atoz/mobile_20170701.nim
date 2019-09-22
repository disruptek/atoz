
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602417 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602417](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602417): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateProject_603011 = ref object of OpenApiRestCall_602417
proc url_CreateProject_603013(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProject_603012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603014 = query.getOrDefault("snapshotId")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "snapshotId", valid_603014
  var valid_603015 = query.getOrDefault("name")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "name", valid_603015
  var valid_603016 = query.getOrDefault("region")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "region", valid_603016
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
  var valid_603017 = header.getOrDefault("X-Amz-Date")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Date", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Security-Token")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Security-Token", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Content-Sha256", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Algorithm")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Algorithm", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Signature")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Signature", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-SignedHeaders", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Credential")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Credential", valid_603023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603025: Call_CreateProject_603011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an AWS Mobile Hub project. 
  ## 
  let valid = call_603025.validator(path, query, header, formData, body)
  let scheme = call_603025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603025.url(scheme.get, call_603025.host, call_603025.base,
                         call_603025.route, valid.getOrDefault("path"))
  result = hook(call_603025, url, valid)

proc call*(call_603026: Call_CreateProject_603011; body: JsonNode;
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
  var query_603027 = newJObject()
  var body_603028 = newJObject()
  add(query_603027, "snapshotId", newJString(snapshotId))
  add(query_603027, "name", newJString(name))
  add(query_603027, "region", newJString(region))
  if body != nil:
    body_603028 = body
  result = call_603026.call(nil, query_603027, nil, nil, body_603028)

var createProject* = Call_CreateProject_603011(name: "createProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_CreateProject_603012, base: "/", url: url_CreateProject_603013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_602754 = ref object of OpenApiRestCall_602417
proc url_ListProjects_602756(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProjects_602755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602868 = query.getOrDefault("maxResults")
  valid_602868 = validateParameter(valid_602868, JInt, required = false, default = nil)
  if valid_602868 != nil:
    section.add "maxResults", valid_602868
  var valid_602869 = query.getOrDefault("nextToken")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "nextToken", valid_602869
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
  var valid_602870 = header.getOrDefault("X-Amz-Date")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Date", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Security-Token")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Security-Token", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Content-Sha256", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Algorithm")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Algorithm", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Signature")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Signature", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-SignedHeaders", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Credential")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Credential", valid_602876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602899: Call_ListProjects_602754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists projects in AWS Mobile Hub. 
  ## 
  let valid = call_602899.validator(path, query, header, formData, body)
  let scheme = call_602899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602899.url(scheme.get, call_602899.host, call_602899.base,
                         call_602899.route, valid.getOrDefault("path"))
  result = hook(call_602899, url, valid)

proc call*(call_602970: Call_ListProjects_602754; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listProjects
  ##  Lists projects in AWS Mobile Hub. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_602971 = newJObject()
  add(query_602971, "maxResults", newJInt(maxResults))
  add(query_602971, "nextToken", newJString(nextToken))
  result = call_602970.call(nil, query_602971, nil, nil, nil)

var listProjects* = Call_ListProjects_602754(name: "listProjects",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com", route: "/projects",
    validator: validate_ListProjects_602755, base: "/", url: url_ListProjects_602756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_603029 = ref object of OpenApiRestCall_602417
proc url_DeleteProject_603031(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "projectId" in path, "`projectId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/projects/"),
               (kind: VariableSegment, value: "projectId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteProject_603030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603046 = path.getOrDefault("projectId")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = nil)
  if valid_603046 != nil:
    section.add "projectId", valid_603046
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
  var valid_603047 = header.getOrDefault("X-Amz-Date")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Date", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Security-Token")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Security-Token", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Content-Sha256", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Algorithm")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Algorithm", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Signature")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Signature", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-SignedHeaders", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603054: Call_DeleteProject_603029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delets a project in AWS Mobile Hub. 
  ## 
  let valid = call_603054.validator(path, query, header, formData, body)
  let scheme = call_603054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603054.url(scheme.get, call_603054.host, call_603054.base,
                         call_603054.route, valid.getOrDefault("path"))
  result = hook(call_603054, url, valid)

proc call*(call_603055: Call_DeleteProject_603029; projectId: string): Recallable =
  ## deleteProject
  ##  Delets a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_603056 = newJObject()
  add(path_603056, "projectId", newJString(projectId))
  result = call_603055.call(path_603056, nil, nil, nil, nil)

var deleteProject* = Call_DeleteProject_603029(name: "deleteProject",
    meth: HttpMethod.HttpDelete, host: "mobile.amazonaws.com",
    route: "/projects/{projectId}", validator: validate_DeleteProject_603030,
    base: "/", url: url_DeleteProject_603031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBundle_603071 = ref object of OpenApiRestCall_602417
proc url_ExportBundle_603073(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "bundleId" in path, "`bundleId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bundles/"),
               (kind: VariableSegment, value: "bundleId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ExportBundle_603072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603074 = path.getOrDefault("bundleId")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "bundleId", valid_603074
  result.add "path", section
  ## parameters in `query` object:
  ##   projectId: JString
  ##            :  Unique project identifier. 
  ##   platform: JString
  ##           :  Developer desktop or target mobile app or website platform. 
  section = newJObject()
  var valid_603075 = query.getOrDefault("projectId")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "projectId", valid_603075
  var valid_603089 = query.getOrDefault("platform")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = newJString("OSX"))
  if valid_603089 != nil:
    section.add "platform", valid_603089
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Content-Sha256", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Algorithm")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Algorithm", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-SignedHeaders", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_ExportBundle_603071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_ExportBundle_603071; bundleId: string;
          projectId: string = ""; platform: string = "OSX"): Recallable =
  ## exportBundle
  ##  Generates customized software development kit (SDK) and or tool packages used to integrate mobile web or mobile app clients with backend AWS resources. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  ##   projectId: string
  ##            :  Unique project identifier. 
  ##   platform: string
  ##           :  Developer desktop or target mobile app or website platform. 
  var path_603099 = newJObject()
  var query_603100 = newJObject()
  add(path_603099, "bundleId", newJString(bundleId))
  add(query_603100, "projectId", newJString(projectId))
  add(query_603100, "platform", newJString(platform))
  result = call_603098.call(path_603099, query_603100, nil, nil, nil)

var exportBundle* = Call_ExportBundle_603071(name: "exportBundle",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_ExportBundle_603072,
    base: "/", url: url_ExportBundle_603073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBundle_603057 = ref object of OpenApiRestCall_602417
proc url_DescribeBundle_603059(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "bundleId" in path, "`bundleId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bundles/"),
               (kind: VariableSegment, value: "bundleId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeBundle_603058(path: JsonNode; query: JsonNode;
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
  var valid_603060 = path.getOrDefault("bundleId")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = nil)
  if valid_603060 != nil:
    section.add "bundleId", valid_603060
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
  var valid_603061 = header.getOrDefault("X-Amz-Date")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Date", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Security-Token")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Security-Token", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Content-Sha256", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Algorithm")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Algorithm", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Signature")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Signature", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-SignedHeaders", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Credential")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Credential", valid_603067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603068: Call_DescribeBundle_603057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get the bundle details for the requested bundle id. 
  ## 
  let valid = call_603068.validator(path, query, header, formData, body)
  let scheme = call_603068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603068.url(scheme.get, call_603068.host, call_603068.base,
                         call_603068.route, valid.getOrDefault("path"))
  result = hook(call_603068, url, valid)

proc call*(call_603069: Call_DescribeBundle_603057; bundleId: string): Recallable =
  ## describeBundle
  ##  Get the bundle details for the requested bundle id. 
  ##   bundleId: string (required)
  ##           :  Unique bundle identifier. 
  var path_603070 = newJObject()
  add(path_603070, "bundleId", newJString(bundleId))
  result = call_603069.call(path_603070, nil, nil, nil, nil)

var describeBundle* = Call_DescribeBundle_603057(name: "describeBundle",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/bundles/{bundleId}", validator: validate_DescribeBundle_603058,
    base: "/", url: url_DescribeBundle_603059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProject_603101 = ref object of OpenApiRestCall_602417
proc url_DescribeProject_603103(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProject_603102(path: JsonNode; query: JsonNode;
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
  var valid_603104 = query.getOrDefault("projectId")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = nil)
  if valid_603104 != nil:
    section.add "projectId", valid_603104
  var valid_603105 = query.getOrDefault("syncFromResources")
  valid_603105 = validateParameter(valid_603105, JBool, required = false, default = nil)
  if valid_603105 != nil:
    section.add "syncFromResources", valid_603105
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
  var valid_603106 = header.getOrDefault("X-Amz-Date")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Date", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Security-Token")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Security-Token", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603113: Call_DescribeProject_603101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets details about a project in AWS Mobile Hub. 
  ## 
  let valid = call_603113.validator(path, query, header, formData, body)
  let scheme = call_603113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603113.url(scheme.get, call_603113.host, call_603113.base,
                         call_603113.route, valid.getOrDefault("path"))
  result = hook(call_603113, url, valid)

proc call*(call_603114: Call_DescribeProject_603101; projectId: string;
          syncFromResources: bool = false): Recallable =
  ## describeProject
  ##  Gets details about a project in AWS Mobile Hub. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   syncFromResources: bool
  ##                    :  If set to true, causes AWS Mobile Hub to synchronize information from other services, e.g., update state of AWS CloudFormation stacks in the AWS Mobile Hub project. 
  var query_603115 = newJObject()
  add(query_603115, "projectId", newJString(projectId))
  add(query_603115, "syncFromResources", newJBool(syncFromResources))
  result = call_603114.call(nil, query_603115, nil, nil, nil)

var describeProject* = Call_DescribeProject_603101(name: "describeProject",
    meth: HttpMethod.HttpGet, host: "mobile.amazonaws.com",
    route: "/project#projectId", validator: validate_DescribeProject_603102,
    base: "/", url: url_DescribeProject_603103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportProject_603116 = ref object of OpenApiRestCall_602417
proc url_ExportProject_603118(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "projectId" in path, "`projectId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/exports/"),
               (kind: VariableSegment, value: "projectId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ExportProject_603117(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603119 = path.getOrDefault("projectId")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = nil)
  if valid_603119 != nil:
    section.add "projectId", valid_603119
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Algorithm")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Algorithm", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_ExportProject_603116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_ExportProject_603116; projectId: string): Recallable =
  ## exportProject
  ##  Exports project configuration to a snapshot which can be downloaded and shared. Note that mobile app push credentials are encrypted in exported projects, so they can only be shared successfully within the same AWS account. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  var path_603129 = newJObject()
  add(path_603129, "projectId", newJString(projectId))
  result = call_603128.call(path_603129, nil, nil, nil, nil)

var exportProject* = Call_ExportProject_603116(name: "exportProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/exports/{projectId}", validator: validate_ExportProject_603117,
    base: "/", url: url_ExportProject_603118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBundles_603130 = ref object of OpenApiRestCall_602417
proc url_ListBundles_603132(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBundles_603131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603133 = query.getOrDefault("maxResults")
  valid_603133 = validateParameter(valid_603133, JInt, required = false, default = nil)
  if valid_603133 != nil:
    section.add "maxResults", valid_603133
  var valid_603134 = query.getOrDefault("nextToken")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "nextToken", valid_603134
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Signature")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Signature", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Credential")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Credential", valid_603141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_ListBundles_603130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List all available bundles. 
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"))
  result = hook(call_603142, url, valid)

proc call*(call_603143: Call_ListBundles_603130; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBundles
  ##  List all available bundles. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing records from start. If non-null pagination token is returned in a result, then pass its value in here in another request to list more entries. 
  var query_603144 = newJObject()
  add(query_603144, "maxResults", newJInt(maxResults))
  add(query_603144, "nextToken", newJString(nextToken))
  result = call_603143.call(nil, query_603144, nil, nil, nil)

var listBundles* = Call_ListBundles_603130(name: "listBundles",
                                        meth: HttpMethod.HttpGet,
                                        host: "mobile.amazonaws.com",
                                        route: "/bundles",
                                        validator: validate_ListBundles_603131,
                                        base: "/", url: url_ListBundles_603132,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_603145 = ref object of OpenApiRestCall_602417
proc url_UpdateProject_603147(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProject_603146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603148 = query.getOrDefault("projectId")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "projectId", valid_603148
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
  var valid_603149 = header.getOrDefault("X-Amz-Date")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Date", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Security-Token")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Security-Token", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Content-Sha256", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Algorithm")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Algorithm", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Signature")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Signature", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603157: Call_UpdateProject_603145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update an existing project. 
  ## 
  let valid = call_603157.validator(path, query, header, formData, body)
  let scheme = call_603157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603157.url(scheme.get, call_603157.host, call_603157.base,
                         call_603157.route, valid.getOrDefault("path"))
  result = hook(call_603157, url, valid)

proc call*(call_603158: Call_UpdateProject_603145; projectId: string; body: JsonNode): Recallable =
  ## updateProject
  ##  Update an existing project. 
  ##   projectId: string (required)
  ##            :  Unique project identifier. 
  ##   body: JObject (required)
  var query_603159 = newJObject()
  var body_603160 = newJObject()
  add(query_603159, "projectId", newJString(projectId))
  if body != nil:
    body_603160 = body
  result = call_603158.call(nil, query_603159, nil, nil, body_603160)

var updateProject* = Call_UpdateProject_603145(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "mobile.amazonaws.com",
    route: "/update#projectId", validator: validate_UpdateProject_603146, base: "/",
    url: url_UpdateProject_603147, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
