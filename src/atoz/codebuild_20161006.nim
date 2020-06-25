
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeBuild
## version: 2016-10-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeBuild</fullname> <p>AWS CodeBuild is a fully managed build service in the cloud. AWS CodeBuild compiles your source code, runs unit tests, and produces artifacts that are ready to deploy. AWS CodeBuild eliminates the need to provision, manage, and scale your own build servers. It provides prepackaged build environments for the most popular programming languages and build tools, such as Apache Maven, Gradle, and more. You can also fully customize build environments in AWS CodeBuild to use your own build tools. AWS CodeBuild scales automatically to meet peak build requests. You pay only for the build time you consume. For more information about AWS CodeBuild, see the <i> <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html">AWS CodeBuild User Guide</a>.</i> </p> <p>AWS CodeBuild supports these operations:</p> <ul> <li> <p> <code>BatchDeleteBuilds</code>: Deletes one or more builds.</p> </li> <li> <p> <code>BatchGetBuilds</code>: Gets information about one or more builds.</p> </li> <li> <p> <code>BatchGetProjects</code>: Gets information about one or more build projects. A <i>build project</i> defines how AWS CodeBuild runs a build. This includes information such as where to get the source code to build, the build environment to use, the build commands to run, and where to store the build output. A <i>build environment</i> is a representation of operating system, programming language runtime, and tools that AWS CodeBuild uses to run a build. You can add tags to build projects to help manage your resources and costs.</p> </li> <li> <p> <code>BatchGetReportGroups</code>: Returns an array of report groups. </p> </li> <li> <p> <code>BatchGetReports</code>: Returns an array of reports. </p> </li> <li> <p> <code>CreateProject</code>: Creates a build project.</p> </li> <li> <p> <code>CreateReportGroup</code>: Creates a report group. A report group contains a collection of reports. </p> </li> <li> <p> <code>CreateWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DeleteProject</code>: Deletes a build project.</p> </li> <li> <p> <code>DeleteReport</code>: Deletes a report. </p> </li> <li> <p> <code>DeleteReportGroup</code>: Deletes a report group. </p> </li> <li> <p> <code>DeleteResourcePolicy</code>: Deletes a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>DeleteSourceCredentials</code>: Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.</p> </li> <li> <p> <code>DeleteWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DescribeTestCases</code>: Returns a list of details about test cases for a report. </p> </li> <li> <p> <code>GetResourcePolicy</code>: Gets a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>ImportSourceCredentials</code>: Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.</p> </li> <li> <p> <code>InvalidateProjectCache</code>: Resets the cache for a project.</p> </li> <li> <p> <code>ListBuilds</code>: Gets a list of build IDs, with each build ID representing a single build.</p> </li> <li> <p> <code>ListBuildsForProject</code>: Gets a list of build IDs for the specified build project, with each build ID representing a single build.</p> </li> <li> <p> <code>ListCuratedEnvironmentImages</code>: Gets information about Docker images that are managed by AWS CodeBuild.</p> </li> <li> <p> <code>ListProjects</code>: Gets a list of build project names, with each build project name representing a single build project.</p> </li> <li> <p> <code>ListReportGroups</code>: Gets a list ARNs for the report groups in the current AWS account. </p> </li> <li> <p> <code>ListReports</code>: Gets a list ARNs for the reports in the current AWS account. </p> </li> <li> <p> <code>ListReportsForReportGroup</code>: Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. </p> </li> <li> <p> <code>ListSharedProjects</code>: Gets a list of ARNs associated with projects shared with the current AWS account or user.</p> </li> <li> <p> <code>ListSharedReportGroups</code>: Gets a list of ARNs associated with report groups shared with the current AWS account or user</p> </li> <li> <p> <code>ListSourceCredentials</code>: Returns a list of <code>SourceCredentialsInfo</code> objects. Each <code>SourceCredentialsInfo</code> object includes the authentication type, token ARN, and type of source provider for one set of credentials.</p> </li> <li> <p> <code>PutResourcePolicy</code>: Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. </p> </li> <li> <p> <code>StartBuild</code>: Starts running a build.</p> </li> <li> <p> <code>StopBuild</code>: Attempts to stop running a build.</p> </li> <li> <p> <code>UpdateProject</code>: Changes the settings of an existing build project.</p> </li> <li> <p> <code>UpdateReportGroup</code>: Changes a report group.</p> </li> <li> <p> <code>UpdateWebhook</code>: Changes the settings of an existing webhook.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codebuild/
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

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchDeleteBuilds_21625781 = ref object of OpenApiRestCall_21625437
proc url_BatchDeleteBuilds_21625783(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteBuilds_21625782(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes one or more builds.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625900 = header.getOrDefault("X-Amz-Target")
  valid_21625900 = validateParameter(valid_21625900, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_21625900 != nil:
    section.add "X-Amz-Target", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
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

proc call*(call_21625931: Call_BatchDeleteBuilds_21625781; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_BatchDeleteBuilds_21625781; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_21625995 = newJObject()
  if body != nil:
    body_21625995 = body
  result = call_21625994.call(nil, nil, nil, nil, body_21625995)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_21625781(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_21625782, base: "/",
    makeUrl: url_BatchDeleteBuilds_21625783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_21626031 = ref object of OpenApiRestCall_21625437
proc url_BatchGetBuilds_21626033(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetBuilds_21626032(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about one or more builds.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Target")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_21626036 != nil:
    section.add "X-Amz-Target", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Algorithm", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Signature")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Signature", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Credential")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Credential", valid_21626041
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

proc call*(call_21626043: Call_BatchGetBuilds_21626031; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more builds.
  ## 
  let valid = call_21626043.validator(path, query, header, formData, body, _)
  let scheme = call_21626043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626043.makeUrl(scheme.get, call_21626043.host, call_21626043.base,
                               call_21626043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626043, uri, valid, _)

proc call*(call_21626044: Call_BatchGetBuilds_21626031; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about one or more builds.
  ##   body: JObject (required)
  var body_21626045 = newJObject()
  if body != nil:
    body_21626045 = body
  result = call_21626044.call(nil, nil, nil, nil, body_21626045)

var batchGetBuilds* = Call_BatchGetBuilds_21626031(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_21626032, base: "/",
    makeUrl: url_BatchGetBuilds_21626033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_21626046 = ref object of OpenApiRestCall_21625437
proc url_BatchGetProjects_21626048(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetProjects_21626047(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about one or more build projects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626049 = header.getOrDefault("X-Amz-Date")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Date", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Security-Token", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Target")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_21626051 != nil:
    section.add "X-Amz-Target", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
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

proc call*(call_21626058: Call_BatchGetProjects_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more build projects.
  ## 
  let valid = call_21626058.validator(path, query, header, formData, body, _)
  let scheme = call_21626058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626058.makeUrl(scheme.get, call_21626058.host, call_21626058.base,
                               call_21626058.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626058, uri, valid, _)

proc call*(call_21626059: Call_BatchGetProjects_21626046; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about one or more build projects.
  ##   body: JObject (required)
  var body_21626060 = newJObject()
  if body != nil:
    body_21626060 = body
  result = call_21626059.call(nil, nil, nil, nil, body_21626060)

var batchGetProjects* = Call_BatchGetProjects_21626046(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_21626047, base: "/",
    makeUrl: url_BatchGetProjects_21626048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReportGroups_21626061 = ref object of OpenApiRestCall_21625437
proc url_BatchGetReportGroups_21626063(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetReportGroups_21626062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns an array of report groups. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Target")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReportGroups"))
  if valid_21626066 != nil:
    section.add "X-Amz-Target", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Algorithm", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Signature")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Signature", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Credential")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Credential", valid_21626071
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

proc call*(call_21626073: Call_BatchGetReportGroups_21626061; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns an array of report groups. 
  ## 
  let valid = call_21626073.validator(path, query, header, formData, body, _)
  let scheme = call_21626073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626073.makeUrl(scheme.get, call_21626073.host, call_21626073.base,
                               call_21626073.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626073, uri, valid, _)

proc call*(call_21626074: Call_BatchGetReportGroups_21626061; body: JsonNode): Recallable =
  ## batchGetReportGroups
  ##  Returns an array of report groups. 
  ##   body: JObject (required)
  var body_21626075 = newJObject()
  if body != nil:
    body_21626075 = body
  result = call_21626074.call(nil, nil, nil, nil, body_21626075)

var batchGetReportGroups* = Call_BatchGetReportGroups_21626061(
    name: "batchGetReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups",
    validator: validate_BatchGetReportGroups_21626062, base: "/",
    makeUrl: url_BatchGetReportGroups_21626063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReports_21626076 = ref object of OpenApiRestCall_21625437
proc url_BatchGetReports_21626078(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetReports_21626077(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns an array of reports. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Target")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReports"))
  if valid_21626081 != nil:
    section.add "X-Amz-Target", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
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

proc call*(call_21626088: Call_BatchGetReports_21626076; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns an array of reports. 
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_BatchGetReports_21626076; body: JsonNode): Recallable =
  ## batchGetReports
  ##  Returns an array of reports. 
  ##   body: JObject (required)
  var body_21626090 = newJObject()
  if body != nil:
    body_21626090 = body
  result = call_21626089.call(nil, nil, nil, nil, body_21626090)

var batchGetReports* = Call_BatchGetReports_21626076(name: "batchGetReports",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReports",
    validator: validate_BatchGetReports_21626077, base: "/",
    makeUrl: url_BatchGetReports_21626078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_21626091 = ref object of OpenApiRestCall_21625437
proc url_CreateProject_21626093(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProject_21626092(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626094 = header.getOrDefault("X-Amz-Date")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Date", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Security-Token", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Target")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_21626096 != nil:
    section.add "X-Amz-Target", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Algorithm", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Signature")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Signature", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Credential")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Credential", valid_21626101
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

proc call*(call_21626103: Call_CreateProject_21626091; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_CreateProject_21626091; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_21626105 = newJObject()
  if body != nil:
    body_21626105 = body
  result = call_21626104.call(nil, nil, nil, nil, body_21626105)

var createProject* = Call_CreateProject_21626091(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_21626092, base: "/",
    makeUrl: url_CreateProject_21626093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReportGroup_21626106 = ref object of OpenApiRestCall_21625437
proc url_CreateReportGroup_21626108(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReportGroup_21626107(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a report group. A report group contains a collection of reports. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Target")
  valid_21626111 = validateParameter(valid_21626111, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateReportGroup"))
  if valid_21626111 != nil:
    section.add "X-Amz-Target", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
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

proc call*(call_21626118: Call_CreateReportGroup_21626106; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a report group. A report group contains a collection of reports. 
  ## 
  let valid = call_21626118.validator(path, query, header, formData, body, _)
  let scheme = call_21626118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626118.makeUrl(scheme.get, call_21626118.host, call_21626118.base,
                               call_21626118.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626118, uri, valid, _)

proc call*(call_21626119: Call_CreateReportGroup_21626106; body: JsonNode): Recallable =
  ## createReportGroup
  ##  Creates a report group. A report group contains a collection of reports. 
  ##   body: JObject (required)
  var body_21626120 = newJObject()
  if body != nil:
    body_21626120 = body
  result = call_21626119.call(nil, nil, nil, nil, body_21626120)

var createReportGroup* = Call_CreateReportGroup_21626106(name: "createReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateReportGroup",
    validator: validate_CreateReportGroup_21626107, base: "/",
    makeUrl: url_CreateReportGroup_21626108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_21626121 = ref object of OpenApiRestCall_21625437
proc url_CreateWebhook_21626123(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWebhook_21626122(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626124 = header.getOrDefault("X-Amz-Date")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Date", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Security-Token", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Target")
  valid_21626126 = validateParameter(valid_21626126, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_21626126 != nil:
    section.add "X-Amz-Target", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Algorithm", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Signature")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Signature", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Credential")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Credential", valid_21626131
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

proc call*(call_21626133: Call_CreateWebhook_21626121; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_CreateWebhook_21626121; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_21626135 = newJObject()
  if body != nil:
    body_21626135 = body
  result = call_21626134.call(nil, nil, nil, nil, body_21626135)

var createWebhook* = Call_CreateWebhook_21626121(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_21626122, base: "/",
    makeUrl: url_CreateWebhook_21626123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_21626136 = ref object of OpenApiRestCall_21625437
proc url_DeleteProject_21626138(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProject_21626137(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
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

proc call*(call_21626148: Call_DeleteProject_21626136; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_DeleteProject_21626136; body: JsonNode): Recallable =
  ## deleteProject
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ##   body: JObject (required)
  var body_21626150 = newJObject()
  if body != nil:
    body_21626150 = body
  result = call_21626149.call(nil, nil, nil, nil, body_21626150)

var deleteProject* = Call_DeleteProject_21626136(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_21626137, base: "/",
    makeUrl: url_DeleteProject_21626138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReport_21626151 = ref object of OpenApiRestCall_21625437
proc url_DeleteReport_21626153(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReport_21626152(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ##  Deletes a report. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626154 = header.getOrDefault("X-Amz-Date")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Date", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Security-Token", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Target")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReport"))
  if valid_21626156 != nil:
    section.add "X-Amz-Target", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
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

proc call*(call_21626163: Call_DeleteReport_21626151; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a report. 
  ## 
  let valid = call_21626163.validator(path, query, header, formData, body, _)
  let scheme = call_21626163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626163.makeUrl(scheme.get, call_21626163.host, call_21626163.base,
                               call_21626163.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626163, uri, valid, _)

proc call*(call_21626164: Call_DeleteReport_21626151; body: JsonNode): Recallable =
  ## deleteReport
  ##  Deletes a report. 
  ##   body: JObject (required)
  var body_21626165 = newJObject()
  if body != nil:
    body_21626165 = body
  result = call_21626164.call(nil, nil, nil, nil, body_21626165)

var deleteReport* = Call_DeleteReport_21626151(name: "deleteReport",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReport",
    validator: validate_DeleteReport_21626152, base: "/", makeUrl: url_DeleteReport_21626153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReportGroup_21626166 = ref object of OpenApiRestCall_21625437
proc url_DeleteReportGroup_21626168(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReportGroup_21626167(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626169 = header.getOrDefault("X-Amz-Date")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Date", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Security-Token", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Target")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReportGroup"))
  if valid_21626171 != nil:
    section.add "X-Amz-Target", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Algorithm", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Signature")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Signature", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Credential")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Credential", valid_21626176
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

proc call*(call_21626178: Call_DeleteReportGroup_21626166; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_DeleteReportGroup_21626166; body: JsonNode): Recallable =
  ## deleteReportGroup
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ##   body: JObject (required)
  var body_21626180 = newJObject()
  if body != nil:
    body_21626180 = body
  result = call_21626179.call(nil, nil, nil, nil, body_21626180)

var deleteReportGroup* = Call_DeleteReportGroup_21626166(name: "deleteReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup",
    validator: validate_DeleteReportGroup_21626167, base: "/",
    makeUrl: url_DeleteReportGroup_21626168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_21626181 = ref object of OpenApiRestCall_21625437
proc url_DeleteResourcePolicy_21626183(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_21626182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Target")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteResourcePolicy"))
  if valid_21626186 != nil:
    section.add "X-Amz-Target", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Algorithm", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Signature")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Signature", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Credential")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Credential", valid_21626191
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

proc call*(call_21626193: Call_DeleteResourcePolicy_21626181; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_21626193.validator(path, query, header, formData, body, _)
  let scheme = call_21626193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626193.makeUrl(scheme.get, call_21626193.host, call_21626193.base,
                               call_21626193.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626193, uri, valid, _)

proc call*(call_21626194: Call_DeleteResourcePolicy_21626181; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_21626195 = newJObject()
  if body != nil:
    body_21626195 = body
  result = call_21626194.call(nil, nil, nil, nil, body_21626195)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_21626181(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_21626182, base: "/",
    makeUrl: url_DeleteResourcePolicy_21626183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_21626196 = ref object of OpenApiRestCall_21625437
proc url_DeleteSourceCredentials_21626198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSourceCredentials_21626197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626199 = header.getOrDefault("X-Amz-Date")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Date", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Security-Token", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Target")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_21626201 != nil:
    section.add "X-Amz-Target", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Algorithm", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Signature")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Signature", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Credential")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Credential", valid_21626206
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

proc call*(call_21626208: Call_DeleteSourceCredentials_21626196;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_DeleteSourceCredentials_21626196; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_21626210 = newJObject()
  if body != nil:
    body_21626210 = body
  result = call_21626209.call(nil, nil, nil, nil, body_21626210)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_21626196(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_21626197, base: "/",
    makeUrl: url_DeleteSourceCredentials_21626198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_21626211 = ref object of OpenApiRestCall_21625437
proc url_DeleteWebhook_21626213(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWebhook_21626212(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626214 = header.getOrDefault("X-Amz-Date")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Date", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Security-Token", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Target")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_21626216 != nil:
    section.add "X-Amz-Target", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Algorithm", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Signature")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Signature", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Credential")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Credential", valid_21626221
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

proc call*(call_21626223: Call_DeleteWebhook_21626211; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_DeleteWebhook_21626211; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_21626225 = newJObject()
  if body != nil:
    body_21626225 = body
  result = call_21626224.call(nil, nil, nil, nil, body_21626225)

var deleteWebhook* = Call_DeleteWebhook_21626211(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_21626212, base: "/",
    makeUrl: url_DeleteWebhook_21626213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTestCases_21626226 = ref object of OpenApiRestCall_21625437
proc url_DescribeTestCases_21626228(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTestCases_21626227(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of details about test cases for a report. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626229 = header.getOrDefault("X-Amz-Date")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Date", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Security-Token", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Target")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true, default = newJString(
      "CodeBuild_20161006.DescribeTestCases"))
  if valid_21626231 != nil:
    section.add "X-Amz-Target", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Algorithm", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Signature")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Signature", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Credential")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Credential", valid_21626236
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

proc call*(call_21626238: Call_DescribeTestCases_21626226; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of details about test cases for a report. 
  ## 
  let valid = call_21626238.validator(path, query, header, formData, body, _)
  let scheme = call_21626238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626238.makeUrl(scheme.get, call_21626238.host, call_21626238.base,
                               call_21626238.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626238, uri, valid, _)

proc call*(call_21626239: Call_DescribeTestCases_21626226; body: JsonNode): Recallable =
  ## describeTestCases
  ##  Returns a list of details about test cases for a report. 
  ##   body: JObject (required)
  var body_21626240 = newJObject()
  if body != nil:
    body_21626240 = body
  result = call_21626239.call(nil, nil, nil, nil, body_21626240)

var describeTestCases* = Call_DescribeTestCases_21626226(name: "describeTestCases",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DescribeTestCases",
    validator: validate_DescribeTestCases_21626227, base: "/",
    makeUrl: url_DescribeTestCases_21626228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_21626241 = ref object of OpenApiRestCall_21625437
proc url_GetResourcePolicy_21626243(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicy_21626242(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a resource policy that is identified by its resource ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Target")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true, default = newJString(
      "CodeBuild_20161006.GetResourcePolicy"))
  if valid_21626246 != nil:
    section.add "X-Amz-Target", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
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

proc call*(call_21626253: Call_GetResourcePolicy_21626241; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_GetResourcePolicy_21626241; body: JsonNode): Recallable =
  ## getResourcePolicy
  ##  Gets a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_21626255 = newJObject()
  if body != nil:
    body_21626255 = body
  result = call_21626254.call(nil, nil, nil, nil, body_21626255)

var getResourcePolicy* = Call_GetResourcePolicy_21626241(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy",
    validator: validate_GetResourcePolicy_21626242, base: "/",
    makeUrl: url_GetResourcePolicy_21626243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_21626256 = ref object of OpenApiRestCall_21625437
proc url_ImportSourceCredentials_21626258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportSourceCredentials_21626257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Target")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_21626261 != nil:
    section.add "X-Amz-Target", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Algorithm", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Signature")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Signature", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Credential")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Credential", valid_21626266
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

proc call*(call_21626268: Call_ImportSourceCredentials_21626256;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_21626268.validator(path, query, header, formData, body, _)
  let scheme = call_21626268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626268.makeUrl(scheme.get, call_21626268.host, call_21626268.base,
                               call_21626268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626268, uri, valid, _)

proc call*(call_21626269: Call_ImportSourceCredentials_21626256; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_21626270 = newJObject()
  if body != nil:
    body_21626270 = body
  result = call_21626269.call(nil, nil, nil, nil, body_21626270)

var importSourceCredentials* = Call_ImportSourceCredentials_21626256(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_21626257, base: "/",
    makeUrl: url_ImportSourceCredentials_21626258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_21626271 = ref object of OpenApiRestCall_21625437
proc url_InvalidateProjectCache_21626273(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InvalidateProjectCache_21626272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Resets the cache for a project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626274 = header.getOrDefault("X-Amz-Date")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Date", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Security-Token", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Target")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_21626276 != nil:
    section.add "X-Amz-Target", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Algorithm", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Signature")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Signature", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Credential")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Credential", valid_21626281
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

proc call*(call_21626283: Call_InvalidateProjectCache_21626271;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_InvalidateProjectCache_21626271; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_21626285 = newJObject()
  if body != nil:
    body_21626285 = body
  result = call_21626284.call(nil, nil, nil, nil, body_21626285)

var invalidateProjectCache* = Call_InvalidateProjectCache_21626271(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_21626272, base: "/",
    makeUrl: url_InvalidateProjectCache_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_21626286 = ref object of OpenApiRestCall_21625437
proc url_ListBuilds_21626288(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBuilds_21626287(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626289 = header.getOrDefault("X-Amz-Date")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Date", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Security-Token", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Target")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_21626291 != nil:
    section.add "X-Amz-Target", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Algorithm", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Signature")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Signature", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Credential")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Credential", valid_21626296
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

proc call*(call_21626298: Call_ListBuilds_21626286; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_21626298.validator(path, query, header, formData, body, _)
  let scheme = call_21626298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626298.makeUrl(scheme.get, call_21626298.host, call_21626298.base,
                               call_21626298.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626298, uri, valid, _)

proc call*(call_21626299: Call_ListBuilds_21626286; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_21626300 = newJObject()
  if body != nil:
    body_21626300 = body
  result = call_21626299.call(nil, nil, nil, nil, body_21626300)

var listBuilds* = Call_ListBuilds_21626286(name: "listBuilds",
                                        meth: HttpMethod.HttpPost,
                                        host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                        validator: validate_ListBuilds_21626287,
                                        base: "/", makeUrl: url_ListBuilds_21626288,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_21626301 = ref object of OpenApiRestCall_21625437
proc url_ListBuildsForProject_21626303(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBuildsForProject_21626302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626304 = header.getOrDefault("X-Amz-Date")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Date", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Security-Token", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Target")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_21626306 != nil:
    section.add "X-Amz-Target", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Algorithm", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Signature")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Signature", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Credential")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Credential", valid_21626311
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

proc call*(call_21626313: Call_ListBuildsForProject_21626301; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_21626313.validator(path, query, header, formData, body, _)
  let scheme = call_21626313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626313.makeUrl(scheme.get, call_21626313.host, call_21626313.base,
                               call_21626313.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626313, uri, valid, _)

proc call*(call_21626314: Call_ListBuildsForProject_21626301; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_21626315 = newJObject()
  if body != nil:
    body_21626315 = body
  result = call_21626314.call(nil, nil, nil, nil, body_21626315)

var listBuildsForProject* = Call_ListBuildsForProject_21626301(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_21626302, base: "/",
    makeUrl: url_ListBuildsForProject_21626303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_21626316 = ref object of OpenApiRestCall_21625437
proc url_ListCuratedEnvironmentImages_21626318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCuratedEnvironmentImages_21626317(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626319 = header.getOrDefault("X-Amz-Date")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Date", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Security-Token", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Target")
  valid_21626321 = validateParameter(valid_21626321, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_21626321 != nil:
    section.add "X-Amz-Target", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
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

proc call*(call_21626328: Call_ListCuratedEnvironmentImages_21626316;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_ListCuratedEnvironmentImages_21626316;
          body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_21626330 = newJObject()
  if body != nil:
    body_21626330 = body
  result = call_21626329.call(nil, nil, nil, nil, body_21626330)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_21626316(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_21626317, base: "/",
    makeUrl: url_ListCuratedEnvironmentImages_21626318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_21626331 = ref object of OpenApiRestCall_21625437
proc url_ListProjects_21626333(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProjects_21626332(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626334 = header.getOrDefault("X-Amz-Date")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Date", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Security-Token", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Target")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_21626336 != nil:
    section.add "X-Amz-Target", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
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

proc call*(call_21626343: Call_ListProjects_21626331; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_21626343.validator(path, query, header, formData, body, _)
  let scheme = call_21626343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626343.makeUrl(scheme.get, call_21626343.host, call_21626343.base,
                               call_21626343.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626343, uri, valid, _)

proc call*(call_21626344: Call_ListProjects_21626331; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_21626345 = newJObject()
  if body != nil:
    body_21626345 = body
  result = call_21626344.call(nil, nil, nil, nil, body_21626345)

var listProjects* = Call_ListProjects_21626331(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_21626332, base: "/", makeUrl: url_ListProjects_21626333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportGroups_21626346 = ref object of OpenApiRestCall_21625437
proc url_ListReportGroups_21626348(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReportGroups_21626347(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626349 = header.getOrDefault("X-Amz-Date")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Date", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Security-Token", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Target")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportGroups"))
  if valid_21626351 != nil:
    section.add "X-Amz-Target", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Algorithm", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Signature")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Signature", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Credential")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Credential", valid_21626356
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

proc call*(call_21626358: Call_ListReportGroups_21626346; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ## 
  let valid = call_21626358.validator(path, query, header, formData, body, _)
  let scheme = call_21626358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626358.makeUrl(scheme.get, call_21626358.host, call_21626358.base,
                               call_21626358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626358, uri, valid, _)

proc call*(call_21626359: Call_ListReportGroups_21626346; body: JsonNode): Recallable =
  ## listReportGroups
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ##   body: JObject (required)
  var body_21626360 = newJObject()
  if body != nil:
    body_21626360 = body
  result = call_21626359.call(nil, nil, nil, nil, body_21626360)

var listReportGroups* = Call_ListReportGroups_21626346(name: "listReportGroups",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportGroups",
    validator: validate_ListReportGroups_21626347, base: "/",
    makeUrl: url_ListReportGroups_21626348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReports_21626361 = ref object of OpenApiRestCall_21625437
proc url_ListReports_21626363(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReports_21626362(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626364 = header.getOrDefault("X-Amz-Date")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Date", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Security-Token", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Target")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReports"))
  if valid_21626366 != nil:
    section.add "X-Amz-Target", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
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

proc call*(call_21626373: Call_ListReports_21626361; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_ListReports_21626361; body: JsonNode): Recallable =
  ## listReports
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ##   body: JObject (required)
  var body_21626375 = newJObject()
  if body != nil:
    body_21626375 = body
  result = call_21626374.call(nil, nil, nil, nil, body_21626375)

var listReports* = Call_ListReports_21626361(name: "listReports",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReports",
    validator: validate_ListReports_21626362, base: "/", makeUrl: url_ListReports_21626363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportsForReportGroup_21626376 = ref object of OpenApiRestCall_21625437
proc url_ListReportsForReportGroup_21626378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReportsForReportGroup_21626377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626379 = header.getOrDefault("X-Amz-Date")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Date", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Security-Token", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Target")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportsForReportGroup"))
  if valid_21626381 != nil:
    section.add "X-Amz-Target", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Algorithm", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Signature")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Signature", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Credential")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Credential", valid_21626386
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

proc call*(call_21626388: Call_ListReportsForReportGroup_21626376;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ## 
  let valid = call_21626388.validator(path, query, header, formData, body, _)
  let scheme = call_21626388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626388.makeUrl(scheme.get, call_21626388.host, call_21626388.base,
                               call_21626388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626388, uri, valid, _)

proc call*(call_21626389: Call_ListReportsForReportGroup_21626376; body: JsonNode): Recallable =
  ## listReportsForReportGroup
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ##   body: JObject (required)
  var body_21626390 = newJObject()
  if body != nil:
    body_21626390 = body
  result = call_21626389.call(nil, nil, nil, nil, body_21626390)

var listReportsForReportGroup* = Call_ListReportsForReportGroup_21626376(
    name: "listReportsForReportGroup", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup",
    validator: validate_ListReportsForReportGroup_21626377, base: "/",
    makeUrl: url_ListReportsForReportGroup_21626378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedProjects_21626391 = ref object of OpenApiRestCall_21625437
proc url_ListSharedProjects_21626393(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSharedProjects_21626392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Target")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedProjects"))
  if valid_21626396 != nil:
    section.add "X-Amz-Target", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Algorithm", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Signature")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Signature", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Credential")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Credential", valid_21626401
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

proc call*(call_21626403: Call_ListSharedProjects_21626391; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ## 
  let valid = call_21626403.validator(path, query, header, formData, body, _)
  let scheme = call_21626403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626403.makeUrl(scheme.get, call_21626403.host, call_21626403.base,
                               call_21626403.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626403, uri, valid, _)

proc call*(call_21626404: Call_ListSharedProjects_21626391; body: JsonNode): Recallable =
  ## listSharedProjects
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_21626405 = newJObject()
  if body != nil:
    body_21626405 = body
  result = call_21626404.call(nil, nil, nil, nil, body_21626405)

var listSharedProjects* = Call_ListSharedProjects_21626391(
    name: "listSharedProjects", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedProjects",
    validator: validate_ListSharedProjects_21626392, base: "/",
    makeUrl: url_ListSharedProjects_21626393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedReportGroups_21626406 = ref object of OpenApiRestCall_21625437
proc url_ListSharedReportGroups_21626408(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSharedReportGroups_21626407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626409 = header.getOrDefault("X-Amz-Date")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Date", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Security-Token", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Target")
  valid_21626411 = validateParameter(valid_21626411, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedReportGroups"))
  if valid_21626411 != nil:
    section.add "X-Amz-Target", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Algorithm", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Signature")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Signature", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Credential")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Credential", valid_21626416
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

proc call*(call_21626418: Call_ListSharedReportGroups_21626406;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ## 
  let valid = call_21626418.validator(path, query, header, formData, body, _)
  let scheme = call_21626418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626418.makeUrl(scheme.get, call_21626418.host, call_21626418.base,
                               call_21626418.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626418, uri, valid, _)

proc call*(call_21626419: Call_ListSharedReportGroups_21626406; body: JsonNode): Recallable =
  ## listSharedReportGroups
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_21626420 = newJObject()
  if body != nil:
    body_21626420 = body
  result = call_21626419.call(nil, nil, nil, nil, body_21626420)

var listSharedReportGroups* = Call_ListSharedReportGroups_21626406(
    name: "listSharedReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups",
    validator: validate_ListSharedReportGroups_21626407, base: "/",
    makeUrl: url_ListSharedReportGroups_21626408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_21626421 = ref object of OpenApiRestCall_21625437
proc url_ListSourceCredentials_21626423(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSourceCredentials_21626422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626424 = header.getOrDefault("X-Amz-Date")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Date", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Security-Token", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Target")
  valid_21626426 = validateParameter(valid_21626426, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_21626426 != nil:
    section.add "X-Amz-Target", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Algorithm", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Signature")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Signature", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Credential")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Credential", valid_21626431
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

proc call*(call_21626433: Call_ListSourceCredentials_21626421;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_21626433.validator(path, query, header, formData, body, _)
  let scheme = call_21626433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626433.makeUrl(scheme.get, call_21626433.host, call_21626433.base,
                               call_21626433.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626433, uri, valid, _)

proc call*(call_21626434: Call_ListSourceCredentials_21626421; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_21626435 = newJObject()
  if body != nil:
    body_21626435 = body
  result = call_21626434.call(nil, nil, nil, nil, body_21626435)

var listSourceCredentials* = Call_ListSourceCredentials_21626421(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_21626422, base: "/",
    makeUrl: url_ListSourceCredentials_21626423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_21626436 = ref object of OpenApiRestCall_21625437
proc url_PutResourcePolicy_21626438(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_21626437(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626439 = header.getOrDefault("X-Amz-Date")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Date", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Security-Token", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Target")
  valid_21626441 = validateParameter(valid_21626441, JString, required = true, default = newJString(
      "CodeBuild_20161006.PutResourcePolicy"))
  if valid_21626441 != nil:
    section.add "X-Amz-Target", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Algorithm", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Signature")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Signature", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Credential")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Credential", valid_21626446
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

proc call*(call_21626448: Call_PutResourcePolicy_21626436; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ## 
  let valid = call_21626448.validator(path, query, header, formData, body, _)
  let scheme = call_21626448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626448.makeUrl(scheme.get, call_21626448.host, call_21626448.base,
                               call_21626448.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626448, uri, valid, _)

proc call*(call_21626449: Call_PutResourcePolicy_21626436; body: JsonNode): Recallable =
  ## putResourcePolicy
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ##   body: JObject (required)
  var body_21626450 = newJObject()
  if body != nil:
    body_21626450 = body
  result = call_21626449.call(nil, nil, nil, nil, body_21626450)

var putResourcePolicy* = Call_PutResourcePolicy_21626436(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy",
    validator: validate_PutResourcePolicy_21626437, base: "/",
    makeUrl: url_PutResourcePolicy_21626438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_21626451 = ref object of OpenApiRestCall_21625437
proc url_StartBuild_21626453(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBuild_21626452(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts running a build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626454 = header.getOrDefault("X-Amz-Date")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Date", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Security-Token", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Target")
  valid_21626456 = validateParameter(valid_21626456, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_21626456 != nil:
    section.add "X-Amz-Target", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Algorithm", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Signature")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Signature", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Credential")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Credential", valid_21626461
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

proc call*(call_21626463: Call_StartBuild_21626451; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_21626463.validator(path, query, header, formData, body, _)
  let scheme = call_21626463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626463.makeUrl(scheme.get, call_21626463.host, call_21626463.base,
                               call_21626463.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626463, uri, valid, _)

proc call*(call_21626464: Call_StartBuild_21626451; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_21626465 = newJObject()
  if body != nil:
    body_21626465 = body
  result = call_21626464.call(nil, nil, nil, nil, body_21626465)

var startBuild* = Call_StartBuild_21626451(name: "startBuild",
                                        meth: HttpMethod.HttpPost,
                                        host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                        validator: validate_StartBuild_21626452,
                                        base: "/", makeUrl: url_StartBuild_21626453,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_21626466 = ref object of OpenApiRestCall_21625437
proc url_StopBuild_21626468(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopBuild_21626467(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attempts to stop running a build.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626469 = header.getOrDefault("X-Amz-Date")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Date", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Security-Token", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Target")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_21626471 != nil:
    section.add "X-Amz-Target", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Algorithm", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Signature")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Signature", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Credential")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Credential", valid_21626476
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

proc call*(call_21626478: Call_StopBuild_21626466; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_21626478.validator(path, query, header, formData, body, _)
  let scheme = call_21626478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626478.makeUrl(scheme.get, call_21626478.host, call_21626478.base,
                               call_21626478.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626478, uri, valid, _)

proc call*(call_21626479: Call_StopBuild_21626466; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_21626480 = newJObject()
  if body != nil:
    body_21626480 = body
  result = call_21626479.call(nil, nil, nil, nil, body_21626480)

var stopBuild* = Call_StopBuild_21626466(name: "stopBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                      validator: validate_StopBuild_21626467,
                                      base: "/", makeUrl: url_StopBuild_21626468,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_21626481 = ref object of OpenApiRestCall_21625437
proc url_UpdateProject_21626483(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProject_21626482(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Changes the settings of a build project.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626484 = header.getOrDefault("X-Amz-Date")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Date", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Security-Token", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Target")
  valid_21626486 = validateParameter(valid_21626486, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_21626486 != nil:
    section.add "X-Amz-Target", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Algorithm", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Signature")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Signature", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Credential")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Credential", valid_21626491
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

proc call*(call_21626493: Call_UpdateProject_21626481; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_21626493.validator(path, query, header, formData, body, _)
  let scheme = call_21626493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626493.makeUrl(scheme.get, call_21626493.host, call_21626493.base,
                               call_21626493.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626493, uri, valid, _)

proc call*(call_21626494: Call_UpdateProject_21626481; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_21626495 = newJObject()
  if body != nil:
    body_21626495 = body
  result = call_21626494.call(nil, nil, nil, nil, body_21626495)

var updateProject* = Call_UpdateProject_21626481(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_21626482, base: "/",
    makeUrl: url_UpdateProject_21626483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReportGroup_21626496 = ref object of OpenApiRestCall_21625437
proc url_UpdateReportGroup_21626498(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateReportGroup_21626497(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Updates a report group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626499 = header.getOrDefault("X-Amz-Date")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Date", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Security-Token", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Target")
  valid_21626501 = validateParameter(valid_21626501, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateReportGroup"))
  if valid_21626501 != nil:
    section.add "X-Amz-Target", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Algorithm", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Signature")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Signature", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Credential")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Credential", valid_21626506
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

proc call*(call_21626508: Call_UpdateReportGroup_21626496; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a report group. 
  ## 
  let valid = call_21626508.validator(path, query, header, formData, body, _)
  let scheme = call_21626508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626508.makeUrl(scheme.get, call_21626508.host, call_21626508.base,
                               call_21626508.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626508, uri, valid, _)

proc call*(call_21626509: Call_UpdateReportGroup_21626496; body: JsonNode): Recallable =
  ## updateReportGroup
  ##  Updates a report group. 
  ##   body: JObject (required)
  var body_21626510 = newJObject()
  if body != nil:
    body_21626510 = body
  result = call_21626509.call(nil, nil, nil, nil, body_21626510)

var updateReportGroup* = Call_UpdateReportGroup_21626496(name: "updateReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup",
    validator: validate_UpdateReportGroup_21626497, base: "/",
    makeUrl: url_UpdateReportGroup_21626498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_21626511 = ref object of OpenApiRestCall_21625437
proc url_UpdateWebhook_21626513(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWebhook_21626512(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626514 = header.getOrDefault("X-Amz-Date")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Date", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Security-Token", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Target")
  valid_21626516 = validateParameter(valid_21626516, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_21626516 != nil:
    section.add "X-Amz-Target", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Algorithm", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Signature")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Signature", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Credential")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Credential", valid_21626521
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

proc call*(call_21626523: Call_UpdateWebhook_21626511; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_21626523.validator(path, query, header, formData, body, _)
  let scheme = call_21626523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626523.makeUrl(scheme.get, call_21626523.host, call_21626523.base,
                               call_21626523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626523, uri, valid, _)

proc call*(call_21626524: Call_UpdateWebhook_21626511; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_21626525 = newJObject()
  if body != nil:
    body_21626525 = body
  result = call_21626524.call(nil, nil, nil, nil, body_21626525)

var updateWebhook* = Call_UpdateWebhook_21626511(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_21626512, base: "/",
    makeUrl: url_UpdateWebhook_21626513, schemes: {Scheme.Https, Scheme.Http})
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