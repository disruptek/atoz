
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeBuild
## version: 2016-10-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeBuild</fullname> <p>AWS CodeBuild is a fully managed build service in the cloud. AWS CodeBuild compiles your source code, runs unit tests, and produces artifacts that are ready to deploy. AWS CodeBuild eliminates the need to provision, manage, and scale your own build servers. It provides prepackaged build environments for the most popular programming languages and build tools, such as Apache Maven, Gradle, and more. You can also fully customize build environments in AWS CodeBuild to use your own build tools. AWS CodeBuild scales automatically to meet peak build requests. You pay only for the build time you consume. For more information about AWS CodeBuild, see the <i> <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html">AWS CodeBuild User Guide</a>.</i> </p> <p>AWS CodeBuild supports these operations:</p> <ul> <li> <p> <code>BatchDeleteBuilds</code>: Deletes one or more builds.</p> </li> <li> <p> <code>BatchGetBuilds</code>: Gets information about one or more builds.</p> </li> <li> <p> <code>BatchGetProjects</code>: Gets information about one or more build projects. A <i>build project</i> defines how AWS CodeBuild runs a build. This includes information such as where to get the source code to build, the build environment to use, the build commands to run, and where to store the build output. A <i>build environment</i> is a representation of operating system, programming language runtime, and tools that AWS CodeBuild uses to run a build. You can add tags to build projects to help manage your resources and costs.</p> </li> <li> <p> <code>CreateProject</code>: Creates a build project.</p> </li> <li> <p> <code>CreateReportGroup</code>: Creates a report group. A report group contains a collection of reports. </p> </li> <li> <p> <code>CreateWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DeleteProject</code>: Deletes a build project.</p> </li> <li> <p> <code>DeleteReport</code>: Deletes a report. </p> </li> <li> <p> <code>DeleteReportGroup</code>: Deletes a report group. </p> </li> <li> <p> <code>DeleteResourcePolicy</code>: Deletes a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>DeleteSourceCredentials</code>: Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.</p> </li> <li> <p> <code>DeleteWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DescribeTestCases</code>: Returns a list of details about test cases for a report. </p> </li> <li> <p> <code>GetResourcePolicy</code>: Gets a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>ImportSourceCredentials</code>: Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.</p> </li> <li> <p> <code>InvalidateProjectCache</code>: Resets the cache for a project.</p> </li> <li> <p> <code>ListBuilds</code>: Gets a list of build IDs, with each build ID representing a single build.</p> </li> <li> <p> <code>ListBuildsForProject</code>: Gets a list of build IDs for the specified build project, with each build ID representing a single build.</p> </li> <li> <p> <code>ListCuratedEnvironmentImages</code>: Gets information about Docker images that are managed by AWS CodeBuild.</p> </li> <li> <p> <code>ListProjects</code>: Gets a list of build project names, with each build project name representing a single build project.</p> </li> <li> <p> <code>ListReportGroups</code>: Gets a list ARNs for the report groups in the current AWS account. </p> </li> <li> <p> <code>ListReports</code>: Gets a list ARNs for the reports in the current AWS account. </p> </li> <li> <p> <code>ListReportsForReportGroup</code>: Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. </p> </li> <li> <p> <code>ListSharedProjects</code>: Gets a list of ARNs associated with projects shared with the current AWS account or user.</p> </li> <li> <p> <code>ListSharedReportGroups</code>: Gets a list of ARNs associated with report groups shared with the current AWS account or user</p> </li> <li> <p> <code>ListSourceCredentials</code>: Returns a list of <code>SourceCredentialsInfo</code> objects. Each <code>SourceCredentialsInfo</code> object includes the authentication type, token ARN, and type of source provider for one set of credentials.</p> </li> <li> <p> <code>PutResourcePolicy</code>: Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. </p> </li> <li> <p> <code>StartBuild</code>: Starts running a build.</p> </li> <li> <p> <code>StopBuild</code>: Attempts to stop running a build.</p> </li> <li> <p> <code>UpdateProject</code>: Changes the settings of an existing build project.</p> </li> <li> <p> <code>UpdateReportGroup</code>: Changes a report group.</p> </li> <li> <p> <code>UpdateWebhook</code>: Changes the settings of an existing webhook.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codebuild/
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

  OpenApiRestCall_601390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601390): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codebuild.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codebuild.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codebuild.us-west-2.amazonaws.com",
                           "eu-west-2": "codebuild.eu-west-2.amazonaws.com", "ap-northeast-3": "codebuild.ap-northeast-3.amazonaws.com", "eu-central-1": "codebuild.eu-central-1.amazonaws.com",
                           "us-east-2": "codebuild.us-east-2.amazonaws.com",
                           "us-east-1": "codebuild.us-east-1.amazonaws.com", "cn-northwest-1": "codebuild.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codebuild.ap-south-1.amazonaws.com",
                           "eu-north-1": "codebuild.eu-north-1.amazonaws.com", "ap-northeast-2": "codebuild.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codebuild.us-west-1.amazonaws.com", "us-gov-east-1": "codebuild.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codebuild.eu-west-3.amazonaws.com", "cn-north-1": "codebuild.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codebuild.sa-east-1.amazonaws.com",
                           "eu-west-1": "codebuild.eu-west-1.amazonaws.com", "us-gov-west-1": "codebuild.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codebuild.ap-southeast-2.amazonaws.com", "ca-central-1": "codebuild.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codebuild.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codebuild.ap-southeast-1.amazonaws.com",
      "us-west-2": "codebuild.us-west-2.amazonaws.com",
      "eu-west-2": "codebuild.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codebuild.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codebuild.eu-central-1.amazonaws.com",
      "us-east-2": "codebuild.us-east-2.amazonaws.com",
      "us-east-1": "codebuild.us-east-1.amazonaws.com",
      "cn-northwest-1": "codebuild.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codebuild.ap-south-1.amazonaws.com",
      "eu-north-1": "codebuild.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codebuild.ap-northeast-2.amazonaws.com",
      "us-west-1": "codebuild.us-west-1.amazonaws.com",
      "us-gov-east-1": "codebuild.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codebuild.eu-west-3.amazonaws.com",
      "cn-north-1": "codebuild.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codebuild.sa-east-1.amazonaws.com",
      "eu-west-1": "codebuild.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codebuild.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codebuild.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codebuild.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codebuild"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDeleteBuilds_601728 = ref object of OpenApiRestCall_601390
proc url_BatchDeleteBuilds_601730(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteBuilds_601729(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes one or more builds.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601855 = header.getOrDefault("X-Amz-Target")
  valid_601855 = validateParameter(valid_601855, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_601855 != nil:
    section.add "X-Amz-Target", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_BatchDeleteBuilds_601728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_BatchDeleteBuilds_601728; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_601958 = newJObject()
  if body != nil:
    body_601958 = body
  result = call_601957.call(nil, nil, nil, nil, body_601958)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_601728(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_601729, base: "/",
    url: url_BatchDeleteBuilds_601730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_601997 = ref object of OpenApiRestCall_601390
proc url_BatchGetBuilds_601999(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetBuilds_601998(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about one or more builds.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602000 = header.getOrDefault("X-Amz-Target")
  valid_602000 = validateParameter(valid_602000, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_602000 != nil:
    section.add "X-Amz-Target", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_BatchGetBuilds_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more builds.
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_BatchGetBuilds_601997; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about one or more builds.
  ##   body: JObject (required)
  var body_602011 = newJObject()
  if body != nil:
    body_602011 = body
  result = call_602010.call(nil, nil, nil, nil, body_602011)

var batchGetBuilds* = Call_BatchGetBuilds_601997(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_601998, base: "/", url: url_BatchGetBuilds_601999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_602012 = ref object of OpenApiRestCall_601390
proc url_BatchGetProjects_602014(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetProjects_602013(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about one or more build projects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602015 = header.getOrDefault("X-Amz-Target")
  valid_602015 = validateParameter(valid_602015, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_602015 != nil:
    section.add "X-Amz-Target", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_BatchGetProjects_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more build projects.
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_BatchGetProjects_602012; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about one or more build projects.
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var batchGetProjects* = Call_BatchGetProjects_602012(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_602013, base: "/",
    url: url_BatchGetProjects_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReportGroups_602027 = ref object of OpenApiRestCall_601390
proc url_BatchGetReportGroups_602029(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetReportGroups_602028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns an array of report groups. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602030 = header.getOrDefault("X-Amz-Target")
  valid_602030 = validateParameter(valid_602030, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReportGroups"))
  if valid_602030 != nil:
    section.add "X-Amz-Target", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_BatchGetReportGroups_602027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of report groups. 
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_BatchGetReportGroups_602027; body: JsonNode): Recallable =
  ## batchGetReportGroups
  ##  Returns an array of report groups. 
  ##   body: JObject (required)
  var body_602041 = newJObject()
  if body != nil:
    body_602041 = body
  result = call_602040.call(nil, nil, nil, nil, body_602041)

var batchGetReportGroups* = Call_BatchGetReportGroups_602027(
    name: "batchGetReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups",
    validator: validate_BatchGetReportGroups_602028, base: "/",
    url: url_BatchGetReportGroups_602029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReports_602042 = ref object of OpenApiRestCall_601390
proc url_BatchGetReports_602044(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetReports_602043(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Returns an array of reports. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602045 = header.getOrDefault("X-Amz-Target")
  valid_602045 = validateParameter(valid_602045, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReports"))
  if valid_602045 != nil:
    section.add "X-Amz-Target", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_BatchGetReports_602042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of reports. 
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_BatchGetReports_602042; body: JsonNode): Recallable =
  ## batchGetReports
  ##  Returns an array of reports. 
  ##   body: JObject (required)
  var body_602056 = newJObject()
  if body != nil:
    body_602056 = body
  result = call_602055.call(nil, nil, nil, nil, body_602056)

var batchGetReports* = Call_BatchGetReports_602042(name: "batchGetReports",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReports",
    validator: validate_BatchGetReports_602043, base: "/", url: url_BatchGetReports_602044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_602057 = ref object of OpenApiRestCall_601390
proc url_CreateProject_602059(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_602058(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602060 = header.getOrDefault("X-Amz-Target")
  valid_602060 = validateParameter(valid_602060, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_602060 != nil:
    section.add "X-Amz-Target", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_CreateProject_602057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_CreateProject_602057; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_602071 = newJObject()
  if body != nil:
    body_602071 = body
  result = call_602070.call(nil, nil, nil, nil, body_602071)

var createProject* = Call_CreateProject_602057(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_602058, base: "/", url: url_CreateProject_602059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReportGroup_602072 = ref object of OpenApiRestCall_601390
proc url_CreateReportGroup_602074(protocol: Scheme; host: string; base: string;
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

proc validate_CreateReportGroup_602073(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Creates a report group. A report group contains a collection of reports. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602075 = header.getOrDefault("X-Amz-Target")
  valid_602075 = validateParameter(valid_602075, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateReportGroup"))
  if valid_602075 != nil:
    section.add "X-Amz-Target", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_CreateReportGroup_602072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a report group. A report group contains a collection of reports. 
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_CreateReportGroup_602072; body: JsonNode): Recallable =
  ## createReportGroup
  ##  Creates a report group. A report group contains a collection of reports. 
  ##   body: JObject (required)
  var body_602086 = newJObject()
  if body != nil:
    body_602086 = body
  result = call_602085.call(nil, nil, nil, nil, body_602086)

var createReportGroup* = Call_CreateReportGroup_602072(name: "createReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateReportGroup",
    validator: validate_CreateReportGroup_602073, base: "/",
    url: url_CreateReportGroup_602074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_602087 = ref object of OpenApiRestCall_601390
proc url_CreateWebhook_602089(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_602088(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602090 = header.getOrDefault("X-Amz-Target")
  valid_602090 = validateParameter(valid_602090, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_602090 != nil:
    section.add "X-Amz-Target", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Content-Sha256", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Credential")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Credential", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Security-Token")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Security-Token", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_CreateWebhook_602087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_CreateWebhook_602087; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_602101 = newJObject()
  if body != nil:
    body_602101 = body
  result = call_602100.call(nil, nil, nil, nil, body_602101)

var createWebhook* = Call_CreateWebhook_602087(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_602088, base: "/", url: url_CreateWebhook_602089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_602102 = ref object of OpenApiRestCall_601390
proc url_DeleteProject_602104(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_602103(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602105 = header.getOrDefault("X-Amz-Target")
  valid_602105 = validateParameter(valid_602105, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_602105 != nil:
    section.add "X-Amz-Target", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Signature")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Signature", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Content-Sha256", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Date")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Date", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Security-Token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Security-Token", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Algorithm")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Algorithm", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602114: Call_DeleteProject_602102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ## 
  let valid = call_602114.validator(path, query, header, formData, body)
  let scheme = call_602114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602114.url(scheme.get, call_602114.host, call_602114.base,
                         call_602114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602114, url, valid)

proc call*(call_602115: Call_DeleteProject_602102; body: JsonNode): Recallable =
  ## deleteProject
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ##   body: JObject (required)
  var body_602116 = newJObject()
  if body != nil:
    body_602116 = body
  result = call_602115.call(nil, nil, nil, nil, body_602116)

var deleteProject* = Call_DeleteProject_602102(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_602103, base: "/", url: url_DeleteProject_602104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReport_602117 = ref object of OpenApiRestCall_601390
proc url_DeleteReport_602119(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReport_602118(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a report. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602120 = header.getOrDefault("X-Amz-Target")
  valid_602120 = validateParameter(valid_602120, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReport"))
  if valid_602120 != nil:
    section.add "X-Amz-Target", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Signature")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Signature", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Content-Sha256", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Date")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Date", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602129: Call_DeleteReport_602117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a report. 
  ## 
  let valid = call_602129.validator(path, query, header, formData, body)
  let scheme = call_602129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602129.url(scheme.get, call_602129.host, call_602129.base,
                         call_602129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602129, url, valid)

proc call*(call_602130: Call_DeleteReport_602117; body: JsonNode): Recallable =
  ## deleteReport
  ##  Deletes a report. 
  ##   body: JObject (required)
  var body_602131 = newJObject()
  if body != nil:
    body_602131 = body
  result = call_602130.call(nil, nil, nil, nil, body_602131)

var deleteReport* = Call_DeleteReport_602117(name: "deleteReport",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReport",
    validator: validate_DeleteReport_602118, base: "/", url: url_DeleteReport_602119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReportGroup_602132 = ref object of OpenApiRestCall_601390
proc url_DeleteReportGroup_602134(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReportGroup_602133(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602135 = header.getOrDefault("X-Amz-Target")
  valid_602135 = validateParameter(valid_602135, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReportGroup"))
  if valid_602135 != nil:
    section.add "X-Amz-Target", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Signature")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Signature", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Content-Sha256", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Date")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Date", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Credential")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Credential", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Security-Token")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Security-Token", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Algorithm")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Algorithm", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-SignedHeaders", valid_602142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602144: Call_DeleteReportGroup_602132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ## 
  let valid = call_602144.validator(path, query, header, formData, body)
  let scheme = call_602144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602144.url(scheme.get, call_602144.host, call_602144.base,
                         call_602144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602144, url, valid)

proc call*(call_602145: Call_DeleteReportGroup_602132; body: JsonNode): Recallable =
  ## deleteReportGroup
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ##   body: JObject (required)
  var body_602146 = newJObject()
  if body != nil:
    body_602146 = body
  result = call_602145.call(nil, nil, nil, nil, body_602146)

var deleteReportGroup* = Call_DeleteReportGroup_602132(name: "deleteReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup",
    validator: validate_DeleteReportGroup_602133, base: "/",
    url: url_DeleteReportGroup_602134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_602147 = ref object of OpenApiRestCall_601390
proc url_DeleteResourcePolicy_602149(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_602148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602150 = header.getOrDefault("X-Amz-Target")
  valid_602150 = validateParameter(valid_602150, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteResourcePolicy"))
  if valid_602150 != nil:
    section.add "X-Amz-Target", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Signature")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Signature", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Content-Sha256", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Date")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Date", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Credential")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Credential", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Security-Token")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Security-Token", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Algorithm")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Algorithm", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-SignedHeaders", valid_602157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602159: Call_DeleteResourcePolicy_602147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_602159.validator(path, query, header, formData, body)
  let scheme = call_602159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602159.url(scheme.get, call_602159.host, call_602159.base,
                         call_602159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602159, url, valid)

proc call*(call_602160: Call_DeleteResourcePolicy_602147; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_602161 = newJObject()
  if body != nil:
    body_602161 = body
  result = call_602160.call(nil, nil, nil, nil, body_602161)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_602147(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_602148, base: "/",
    url: url_DeleteResourcePolicy_602149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_602162 = ref object of OpenApiRestCall_601390
proc url_DeleteSourceCredentials_602164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSourceCredentials_602163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602165 = header.getOrDefault("X-Amz-Target")
  valid_602165 = validateParameter(valid_602165, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_602165 != nil:
    section.add "X-Amz-Target", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Content-Sha256", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Date")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Date", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Credential")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Credential", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Security-Token")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Security-Token", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Algorithm")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Algorithm", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-SignedHeaders", valid_602172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602174: Call_DeleteSourceCredentials_602162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_602174.validator(path, query, header, formData, body)
  let scheme = call_602174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602174.url(scheme.get, call_602174.host, call_602174.base,
                         call_602174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602174, url, valid)

proc call*(call_602175: Call_DeleteSourceCredentials_602162; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_602176 = newJObject()
  if body != nil:
    body_602176 = body
  result = call_602175.call(nil, nil, nil, nil, body_602176)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_602162(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_602163, base: "/",
    url: url_DeleteSourceCredentials_602164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_602177 = ref object of OpenApiRestCall_601390
proc url_DeleteWebhook_602179(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_602178(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602180 = header.getOrDefault("X-Amz-Target")
  valid_602180 = validateParameter(valid_602180, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_602180 != nil:
    section.add "X-Amz-Target", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Signature", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Content-Sha256", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Date")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Date", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Credential")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Credential", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Security-Token")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Security-Token", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Algorithm")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Algorithm", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-SignedHeaders", valid_602187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602189: Call_DeleteWebhook_602177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_602189.validator(path, query, header, formData, body)
  let scheme = call_602189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602189.url(scheme.get, call_602189.host, call_602189.base,
                         call_602189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602189, url, valid)

proc call*(call_602190: Call_DeleteWebhook_602177; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_602191 = newJObject()
  if body != nil:
    body_602191 = body
  result = call_602190.call(nil, nil, nil, nil, body_602191)

var deleteWebhook* = Call_DeleteWebhook_602177(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_602178, base: "/", url: url_DeleteWebhook_602179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTestCases_602192 = ref object of OpenApiRestCall_601390
proc url_DescribeTestCases_602194(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTestCases_602193(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Returns a list of details about test cases for a report. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602195 = header.getOrDefault("X-Amz-Target")
  valid_602195 = validateParameter(valid_602195, JString, required = true, default = newJString(
      "CodeBuild_20161006.DescribeTestCases"))
  if valid_602195 != nil:
    section.add "X-Amz-Target", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Signature")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Signature", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Content-Sha256", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Date")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Date", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Credential")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Credential", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Security-Token")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Security-Token", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Algorithm")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Algorithm", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-SignedHeaders", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_DescribeTestCases_602192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of details about test cases for a report. 
  ## 
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602204, url, valid)

proc call*(call_602205: Call_DescribeTestCases_602192; body: JsonNode): Recallable =
  ## describeTestCases
  ##  Returns a list of details about test cases for a report. 
  ##   body: JObject (required)
  var body_602206 = newJObject()
  if body != nil:
    body_602206 = body
  result = call_602205.call(nil, nil, nil, nil, body_602206)

var describeTestCases* = Call_DescribeTestCases_602192(name: "describeTestCases",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DescribeTestCases",
    validator: validate_DescribeTestCases_602193, base: "/",
    url: url_DescribeTestCases_602194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_602207 = ref object of OpenApiRestCall_601390
proc url_GetResourcePolicy_602209(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_602208(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Gets a resource policy that is identified by its resource ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602210 = header.getOrDefault("X-Amz-Target")
  valid_602210 = validateParameter(valid_602210, JString, required = true, default = newJString(
      "CodeBuild_20161006.GetResourcePolicy"))
  if valid_602210 != nil:
    section.add "X-Amz-Target", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_GetResourcePolicy_602207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602219, url, valid)

proc call*(call_602220: Call_GetResourcePolicy_602207; body: JsonNode): Recallable =
  ## getResourcePolicy
  ##  Gets a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_602221 = newJObject()
  if body != nil:
    body_602221 = body
  result = call_602220.call(nil, nil, nil, nil, body_602221)

var getResourcePolicy* = Call_GetResourcePolicy_602207(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy",
    validator: validate_GetResourcePolicy_602208, base: "/",
    url: url_GetResourcePolicy_602209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_602222 = ref object of OpenApiRestCall_601390
proc url_ImportSourceCredentials_602224(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportSourceCredentials_602223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602225 = header.getOrDefault("X-Amz-Target")
  valid_602225 = validateParameter(valid_602225, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_602225 != nil:
    section.add "X-Amz-Target", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Signature")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Signature", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Content-Sha256", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Date")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Date", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Credential")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Credential", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Security-Token")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Security-Token", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602234: Call_ImportSourceCredentials_602222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_602234.validator(path, query, header, formData, body)
  let scheme = call_602234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602234.url(scheme.get, call_602234.host, call_602234.base,
                         call_602234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602234, url, valid)

proc call*(call_602235: Call_ImportSourceCredentials_602222; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_602236 = newJObject()
  if body != nil:
    body_602236 = body
  result = call_602235.call(nil, nil, nil, nil, body_602236)

var importSourceCredentials* = Call_ImportSourceCredentials_602222(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_602223, base: "/",
    url: url_ImportSourceCredentials_602224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_602237 = ref object of OpenApiRestCall_601390
proc url_InvalidateProjectCache_602239(protocol: Scheme; host: string; base: string;
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

proc validate_InvalidateProjectCache_602238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Resets the cache for a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602240 = header.getOrDefault("X-Amz-Target")
  valid_602240 = validateParameter(valid_602240, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_602240 != nil:
    section.add "X-Amz-Target", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Signature")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Signature", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Content-Sha256", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Date")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Date", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Credential")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Credential", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Security-Token")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Security-Token", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Algorithm")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Algorithm", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602249: Call_InvalidateProjectCache_602237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_602249.validator(path, query, header, formData, body)
  let scheme = call_602249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602249.url(scheme.get, call_602249.host, call_602249.base,
                         call_602249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602249, url, valid)

proc call*(call_602250: Call_InvalidateProjectCache_602237; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_602251 = newJObject()
  if body != nil:
    body_602251 = body
  result = call_602250.call(nil, nil, nil, nil, body_602251)

var invalidateProjectCache* = Call_InvalidateProjectCache_602237(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_602238, base: "/",
    url: url_InvalidateProjectCache_602239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_602252 = ref object of OpenApiRestCall_601390
proc url_ListBuilds_602254(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBuilds_602253(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602255 = header.getOrDefault("X-Amz-Target")
  valid_602255 = validateParameter(valid_602255, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_602255 != nil:
    section.add "X-Amz-Target", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Signature")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Signature", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Content-Sha256", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Date")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Date", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Credential")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Credential", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Security-Token")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Security-Token", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Algorithm")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Algorithm", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-SignedHeaders", valid_602262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602264: Call_ListBuilds_602252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_602264.validator(path, query, header, formData, body)
  let scheme = call_602264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602264.url(scheme.get, call_602264.host, call_602264.base,
                         call_602264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602264, url, valid)

proc call*(call_602265: Call_ListBuilds_602252; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_602266 = newJObject()
  if body != nil:
    body_602266 = body
  result = call_602265.call(nil, nil, nil, nil, body_602266)

var listBuilds* = Call_ListBuilds_602252(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                      validator: validate_ListBuilds_602253,
                                      base: "/", url: url_ListBuilds_602254,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_602267 = ref object of OpenApiRestCall_601390
proc url_ListBuildsForProject_602269(protocol: Scheme; host: string; base: string;
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

proc validate_ListBuildsForProject_602268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602270 = header.getOrDefault("X-Amz-Target")
  valid_602270 = validateParameter(valid_602270, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_602270 != nil:
    section.add "X-Amz-Target", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Signature")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Signature", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Content-Sha256", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Date")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Date", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Credential")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Credential", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Security-Token")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Security-Token", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Algorithm")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Algorithm", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602279: Call_ListBuildsForProject_602267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_602279.validator(path, query, header, formData, body)
  let scheme = call_602279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602279.url(scheme.get, call_602279.host, call_602279.base,
                         call_602279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602279, url, valid)

proc call*(call_602280: Call_ListBuildsForProject_602267; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_602281 = newJObject()
  if body != nil:
    body_602281 = body
  result = call_602280.call(nil, nil, nil, nil, body_602281)

var listBuildsForProject* = Call_ListBuildsForProject_602267(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_602268, base: "/",
    url: url_ListBuildsForProject_602269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_602282 = ref object of OpenApiRestCall_601390
proc url_ListCuratedEnvironmentImages_602284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCuratedEnvironmentImages_602283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602285 = header.getOrDefault("X-Amz-Target")
  valid_602285 = validateParameter(valid_602285, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_602285 != nil:
    section.add "X-Amz-Target", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Signature")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Signature", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Content-Sha256", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Date")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Date", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Credential")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Credential", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Security-Token")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Security-Token", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Algorithm")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Algorithm", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602294: Call_ListCuratedEnvironmentImages_602282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_602294.validator(path, query, header, formData, body)
  let scheme = call_602294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602294.url(scheme.get, call_602294.host, call_602294.base,
                         call_602294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602294, url, valid)

proc call*(call_602295: Call_ListCuratedEnvironmentImages_602282; body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_602296 = newJObject()
  if body != nil:
    body_602296 = body
  result = call_602295.call(nil, nil, nil, nil, body_602296)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_602282(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_602283, base: "/",
    url: url_ListCuratedEnvironmentImages_602284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_602297 = ref object of OpenApiRestCall_601390
proc url_ListProjects_602299(protocol: Scheme; host: string; base: string;
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

proc validate_ListProjects_602298(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602300 = header.getOrDefault("X-Amz-Target")
  valid_602300 = validateParameter(valid_602300, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_602300 != nil:
    section.add "X-Amz-Target", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Signature")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Signature", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Content-Sha256", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Date")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Date", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Credential")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Credential", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Security-Token")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Security-Token", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Algorithm")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Algorithm", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-SignedHeaders", valid_602307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602309: Call_ListProjects_602297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_602309.validator(path, query, header, formData, body)
  let scheme = call_602309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602309.url(scheme.get, call_602309.host, call_602309.base,
                         call_602309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602309, url, valid)

proc call*(call_602310: Call_ListProjects_602297; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_602311 = newJObject()
  if body != nil:
    body_602311 = body
  result = call_602310.call(nil, nil, nil, nil, body_602311)

var listProjects* = Call_ListProjects_602297(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_602298, base: "/", url: url_ListProjects_602299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportGroups_602312 = ref object of OpenApiRestCall_601390
proc url_ListReportGroups_602314(protocol: Scheme; host: string; base: string;
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

proc validate_ListReportGroups_602313(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602315 = header.getOrDefault("X-Amz-Target")
  valid_602315 = validateParameter(valid_602315, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportGroups"))
  if valid_602315 != nil:
    section.add "X-Amz-Target", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Signature")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Signature", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Content-Sha256", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Date")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Date", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Credential")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Credential", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Security-Token")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Security-Token", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Algorithm")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Algorithm", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-SignedHeaders", valid_602322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602324: Call_ListReportGroups_602312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ## 
  let valid = call_602324.validator(path, query, header, formData, body)
  let scheme = call_602324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602324.url(scheme.get, call_602324.host, call_602324.base,
                         call_602324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602324, url, valid)

proc call*(call_602325: Call_ListReportGroups_602312; body: JsonNode): Recallable =
  ## listReportGroups
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ##   body: JObject (required)
  var body_602326 = newJObject()
  if body != nil:
    body_602326 = body
  result = call_602325.call(nil, nil, nil, nil, body_602326)

var listReportGroups* = Call_ListReportGroups_602312(name: "listReportGroups",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportGroups",
    validator: validate_ListReportGroups_602313, base: "/",
    url: url_ListReportGroups_602314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReports_602327 = ref object of OpenApiRestCall_601390
proc url_ListReports_602329(protocol: Scheme; host: string; base: string;
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

proc validate_ListReports_602328(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602330 = header.getOrDefault("X-Amz-Target")
  valid_602330 = validateParameter(valid_602330, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReports"))
  if valid_602330 != nil:
    section.add "X-Amz-Target", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Signature")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Signature", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Date")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Date", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Security-Token")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Security-Token", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Algorithm")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Algorithm", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-SignedHeaders", valid_602337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_ListReports_602327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ## 
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602339, url, valid)

proc call*(call_602340: Call_ListReports_602327; body: JsonNode): Recallable =
  ## listReports
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ##   body: JObject (required)
  var body_602341 = newJObject()
  if body != nil:
    body_602341 = body
  result = call_602340.call(nil, nil, nil, nil, body_602341)

var listReports* = Call_ListReports_602327(name: "listReports",
                                        meth: HttpMethod.HttpPost,
                                        host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListReports",
                                        validator: validate_ListReports_602328,
                                        base: "/", url: url_ListReports_602329,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportsForReportGroup_602342 = ref object of OpenApiRestCall_601390
proc url_ListReportsForReportGroup_602344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReportsForReportGroup_602343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602345 = header.getOrDefault("X-Amz-Target")
  valid_602345 = validateParameter(valid_602345, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportsForReportGroup"))
  if valid_602345 != nil:
    section.add "X-Amz-Target", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Signature")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Signature", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Content-Sha256", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Date")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Date", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Credential")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Credential", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Security-Token")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Security-Token", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Algorithm")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Algorithm", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-SignedHeaders", valid_602352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602354: Call_ListReportsForReportGroup_602342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ## 
  let valid = call_602354.validator(path, query, header, formData, body)
  let scheme = call_602354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602354.url(scheme.get, call_602354.host, call_602354.base,
                         call_602354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602354, url, valid)

proc call*(call_602355: Call_ListReportsForReportGroup_602342; body: JsonNode): Recallable =
  ## listReportsForReportGroup
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ##   body: JObject (required)
  var body_602356 = newJObject()
  if body != nil:
    body_602356 = body
  result = call_602355.call(nil, nil, nil, nil, body_602356)

var listReportsForReportGroup* = Call_ListReportsForReportGroup_602342(
    name: "listReportsForReportGroup", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup",
    validator: validate_ListReportsForReportGroup_602343, base: "/",
    url: url_ListReportsForReportGroup_602344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedProjects_602357 = ref object of OpenApiRestCall_601390
proc url_ListSharedProjects_602359(protocol: Scheme; host: string; base: string;
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

proc validate_ListSharedProjects_602358(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602360 = header.getOrDefault("X-Amz-Target")
  valid_602360 = validateParameter(valid_602360, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedProjects"))
  if valid_602360 != nil:
    section.add "X-Amz-Target", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Signature")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Signature", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Content-Sha256", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Date")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Date", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Credential")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Credential", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Security-Token")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Security-Token", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Algorithm")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Algorithm", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-SignedHeaders", valid_602367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602369: Call_ListSharedProjects_602357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ## 
  let valid = call_602369.validator(path, query, header, formData, body)
  let scheme = call_602369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602369.url(scheme.get, call_602369.host, call_602369.base,
                         call_602369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602369, url, valid)

proc call*(call_602370: Call_ListSharedProjects_602357; body: JsonNode): Recallable =
  ## listSharedProjects
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_602371 = newJObject()
  if body != nil:
    body_602371 = body
  result = call_602370.call(nil, nil, nil, nil, body_602371)

var listSharedProjects* = Call_ListSharedProjects_602357(
    name: "listSharedProjects", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedProjects",
    validator: validate_ListSharedProjects_602358, base: "/",
    url: url_ListSharedProjects_602359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedReportGroups_602372 = ref object of OpenApiRestCall_601390
proc url_ListSharedReportGroups_602374(protocol: Scheme; host: string; base: string;
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

proc validate_ListSharedReportGroups_602373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602375 = header.getOrDefault("X-Amz-Target")
  valid_602375 = validateParameter(valid_602375, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedReportGroups"))
  if valid_602375 != nil:
    section.add "X-Amz-Target", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Signature")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Signature", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Content-Sha256", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Date")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Date", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Credential")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Credential", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Security-Token")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Security-Token", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Algorithm")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Algorithm", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-SignedHeaders", valid_602382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602384: Call_ListSharedReportGroups_602372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ## 
  let valid = call_602384.validator(path, query, header, formData, body)
  let scheme = call_602384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602384.url(scheme.get, call_602384.host, call_602384.base,
                         call_602384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602384, url, valid)

proc call*(call_602385: Call_ListSharedReportGroups_602372; body: JsonNode): Recallable =
  ## listSharedReportGroups
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_602386 = newJObject()
  if body != nil:
    body_602386 = body
  result = call_602385.call(nil, nil, nil, nil, body_602386)

var listSharedReportGroups* = Call_ListSharedReportGroups_602372(
    name: "listSharedReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups",
    validator: validate_ListSharedReportGroups_602373, base: "/",
    url: url_ListSharedReportGroups_602374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_602387 = ref object of OpenApiRestCall_601390
proc url_ListSourceCredentials_602389(protocol: Scheme; host: string; base: string;
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

proc validate_ListSourceCredentials_602388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602390 = header.getOrDefault("X-Amz-Target")
  valid_602390 = validateParameter(valid_602390, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_602390 != nil:
    section.add "X-Amz-Target", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Signature")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Signature", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Content-Sha256", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Date")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Date", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Credential")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Credential", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Security-Token")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Security-Token", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Algorithm")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Algorithm", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-SignedHeaders", valid_602397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602399: Call_ListSourceCredentials_602387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_602399.validator(path, query, header, formData, body)
  let scheme = call_602399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602399.url(scheme.get, call_602399.host, call_602399.base,
                         call_602399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602399, url, valid)

proc call*(call_602400: Call_ListSourceCredentials_602387; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_602401 = newJObject()
  if body != nil:
    body_602401 = body
  result = call_602400.call(nil, nil, nil, nil, body_602401)

var listSourceCredentials* = Call_ListSourceCredentials_602387(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_602388, base: "/",
    url: url_ListSourceCredentials_602389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_602402 = ref object of OpenApiRestCall_601390
proc url_PutResourcePolicy_602404(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_602403(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602405 = header.getOrDefault("X-Amz-Target")
  valid_602405 = validateParameter(valid_602405, JString, required = true, default = newJString(
      "CodeBuild_20161006.PutResourcePolicy"))
  if valid_602405 != nil:
    section.add "X-Amz-Target", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Signature")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Signature", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Content-Sha256", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Date")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Date", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Credential")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Credential", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Security-Token")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Security-Token", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Algorithm")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Algorithm", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-SignedHeaders", valid_602412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602414: Call_PutResourcePolicy_602402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ## 
  let valid = call_602414.validator(path, query, header, formData, body)
  let scheme = call_602414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602414.url(scheme.get, call_602414.host, call_602414.base,
                         call_602414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602414, url, valid)

proc call*(call_602415: Call_PutResourcePolicy_602402; body: JsonNode): Recallable =
  ## putResourcePolicy
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ##   body: JObject (required)
  var body_602416 = newJObject()
  if body != nil:
    body_602416 = body
  result = call_602415.call(nil, nil, nil, nil, body_602416)

var putResourcePolicy* = Call_PutResourcePolicy_602402(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy",
    validator: validate_PutResourcePolicy_602403, base: "/",
    url: url_PutResourcePolicy_602404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_602417 = ref object of OpenApiRestCall_601390
proc url_StartBuild_602419(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBuild_602418(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts running a build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602420 = header.getOrDefault("X-Amz-Target")
  valid_602420 = validateParameter(valid_602420, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_602420 != nil:
    section.add "X-Amz-Target", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Signature")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Signature", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Content-Sha256", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Date")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Date", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Credential")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Credential", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Security-Token")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Security-Token", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Algorithm")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Algorithm", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-SignedHeaders", valid_602427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602429: Call_StartBuild_602417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_602429.validator(path, query, header, formData, body)
  let scheme = call_602429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602429.url(scheme.get, call_602429.host, call_602429.base,
                         call_602429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602429, url, valid)

proc call*(call_602430: Call_StartBuild_602417; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_602431 = newJObject()
  if body != nil:
    body_602431 = body
  result = call_602430.call(nil, nil, nil, nil, body_602431)

var startBuild* = Call_StartBuild_602417(name: "startBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                      validator: validate_StartBuild_602418,
                                      base: "/", url: url_StartBuild_602419,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_602432 = ref object of OpenApiRestCall_601390
proc url_StopBuild_602434(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopBuild_602433(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to stop running a build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602435 = header.getOrDefault("X-Amz-Target")
  valid_602435 = validateParameter(valid_602435, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_602435 != nil:
    section.add "X-Amz-Target", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Signature")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Signature", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Content-Sha256", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Date")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Date", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Credential")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Credential", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Security-Token")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Security-Token", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Algorithm")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Algorithm", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-SignedHeaders", valid_602442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602444: Call_StopBuild_602432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_602444.validator(path, query, header, formData, body)
  let scheme = call_602444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602444.url(scheme.get, call_602444.host, call_602444.base,
                         call_602444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602444, url, valid)

proc call*(call_602445: Call_StopBuild_602432; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_602446 = newJObject()
  if body != nil:
    body_602446 = body
  result = call_602445.call(nil, nil, nil, nil, body_602446)

var stopBuild* = Call_StopBuild_602432(name: "stopBuild", meth: HttpMethod.HttpPost,
                                    host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                    validator: validate_StopBuild_602433,
                                    base: "/", url: url_StopBuild_602434,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_602447 = ref object of OpenApiRestCall_601390
proc url_UpdateProject_602449(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_602448(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the settings of a build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602450 = header.getOrDefault("X-Amz-Target")
  valid_602450 = validateParameter(valid_602450, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_602450 != nil:
    section.add "X-Amz-Target", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Signature")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Signature", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Content-Sha256", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Date")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Date", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Credential")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Credential", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Security-Token")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Security-Token", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Algorithm")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Algorithm", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-SignedHeaders", valid_602457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602459: Call_UpdateProject_602447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_602459.validator(path, query, header, formData, body)
  let scheme = call_602459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602459.url(scheme.get, call_602459.host, call_602459.base,
                         call_602459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602459, url, valid)

proc call*(call_602460: Call_UpdateProject_602447; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_602461 = newJObject()
  if body != nil:
    body_602461 = body
  result = call_602460.call(nil, nil, nil, nil, body_602461)

var updateProject* = Call_UpdateProject_602447(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_602448, base: "/", url: url_UpdateProject_602449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReportGroup_602462 = ref object of OpenApiRestCall_601390
proc url_UpdateReportGroup_602464(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReportGroup_602463(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  Updates a report group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602465 = header.getOrDefault("X-Amz-Target")
  valid_602465 = validateParameter(valid_602465, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateReportGroup"))
  if valid_602465 != nil:
    section.add "X-Amz-Target", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Signature")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Signature", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Content-Sha256", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Date")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Date", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Credential")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Credential", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Security-Token")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Security-Token", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Algorithm")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Algorithm", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-SignedHeaders", valid_602472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602474: Call_UpdateReportGroup_602462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a report group. 
  ## 
  let valid = call_602474.validator(path, query, header, formData, body)
  let scheme = call_602474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602474.url(scheme.get, call_602474.host, call_602474.base,
                         call_602474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602474, url, valid)

proc call*(call_602475: Call_UpdateReportGroup_602462; body: JsonNode): Recallable =
  ## updateReportGroup
  ##  Updates a report group. 
  ##   body: JObject (required)
  var body_602476 = newJObject()
  if body != nil:
    body_602476 = body
  result = call_602475.call(nil, nil, nil, nil, body_602476)

var updateReportGroup* = Call_UpdateReportGroup_602462(name: "updateReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup",
    validator: validate_UpdateReportGroup_602463, base: "/",
    url: url_UpdateReportGroup_602464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_602477 = ref object of OpenApiRestCall_601390
proc url_UpdateWebhook_602479(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_602478(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602480 = header.getOrDefault("X-Amz-Target")
  valid_602480 = validateParameter(valid_602480, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_602480 != nil:
    section.add "X-Amz-Target", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Signature")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Signature", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Content-Sha256", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Date")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Date", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Credential")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Credential", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Security-Token")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Security-Token", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Algorithm")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Algorithm", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-SignedHeaders", valid_602487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602489: Call_UpdateWebhook_602477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_602489.validator(path, query, header, formData, body)
  let scheme = call_602489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602489.url(scheme.get, call_602489.host, call_602489.base,
                         call_602489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602489, url, valid)

proc call*(call_602490: Call_UpdateWebhook_602477; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_602491 = newJObject()
  if body != nil:
    body_602491 = body
  result = call_602490.call(nil, nil, nil, nil, body_602491)

var updateWebhook* = Call_UpdateWebhook_602477(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_602478, base: "/", url: url_UpdateWebhook_602479,
    schemes: {Scheme.Https, Scheme.Http})
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
