
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
## <fullname>AWS CodeBuild</fullname> <p>AWS CodeBuild is a fully managed build service in the cloud. AWS CodeBuild compiles your source code, runs unit tests, and produces artifacts that are ready to deploy. AWS CodeBuild eliminates the need to provision, manage, and scale your own build servers. It provides prepackaged build environments for the most popular programming languages and build tools, such as Apache Maven, Gradle, and more. You can also fully customize build environments in AWS CodeBuild to use your own build tools. AWS CodeBuild scales automatically to meet peak build requests. You pay only for the build time you consume. For more information about AWS CodeBuild, see the <i> <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html">AWS CodeBuild User Guide</a>.</i> </p> <p>AWS CodeBuild supports these operations:</p> <ul> <li> <p> <code>BatchDeleteBuilds</code>: Deletes one or more builds.</p> </li> <li> <p> <code>BatchGetBuilds</code>: Gets information about one or more builds.</p> </li> <li> <p> <code>BatchGetProjects</code>: Gets information about one or more build projects. A <i>build project</i> defines how AWS CodeBuild runs a build. This includes information such as where to get the source code to build, the build environment to use, the build commands to run, and where to store the build output. A <i>build environment</i> is a representation of operating system, programming language runtime, and tools that AWS CodeBuild uses to run a build. You can add tags to build projects to help manage your resources and costs.</p> </li> <li> <p> <code>BatchGetReportGroups</code>: Returns an array of report groups. </p> </li> <li> <p> <code>BatchGetReports</code>: Returns an array of reports. </p> </li> <li> <p> <code>CreateProject</code>: Creates a build project.</p> </li> <li> <p> <code>CreateReportGroup</code>: Creates a report group. A report group contains a collection of reports. </p> </li> <li> <p> <code>CreateWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DeleteProject</code>: Deletes a build project.</p> </li> <li> <p> <code>DeleteReport</code>: Deletes a report. </p> </li> <li> <p> <code>DeleteReportGroup</code>: Deletes a report group. </p> </li> <li> <p> <code>DeleteResourcePolicy</code>: Deletes a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>DeleteSourceCredentials</code>: Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.</p> </li> <li> <p> <code>DeleteWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>DescribeTestCases</code>: Returns a list of details about test cases for a report. </p> </li> <li> <p> <code>GetResourcePolicy</code>: Gets a resource policy that is identified by its resource ARN. </p> </li> <li> <p> <code>ImportSourceCredentials</code>: Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.</p> </li> <li> <p> <code>InvalidateProjectCache</code>: Resets the cache for a project.</p> </li> <li> <p> <code>ListBuilds</code>: Gets a list of build IDs, with each build ID representing a single build.</p> </li> <li> <p> <code>ListBuildsForProject</code>: Gets a list of build IDs for the specified build project, with each build ID representing a single build.</p> </li> <li> <p> <code>ListCuratedEnvironmentImages</code>: Gets information about Docker images that are managed by AWS CodeBuild.</p> </li> <li> <p> <code>ListProjects</code>: Gets a list of build project names, with each build project name representing a single build project.</p> </li> <li> <p> <code>ListReportGroups</code>: Gets a list ARNs for the report groups in the current AWS account. </p> </li> <li> <p> <code>ListReports</code>: Gets a list ARNs for the reports in the current AWS account. </p> </li> <li> <p> <code>ListReportsForReportGroup</code>: Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. </p> </li> <li> <p> <code>ListSharedProjects</code>: Gets a list of ARNs associated with projects shared with the current AWS account or user.</p> </li> <li> <p> <code>ListSharedReportGroups</code>: Gets a list of ARNs associated with report groups shared with the current AWS account or user</p> </li> <li> <p> <code>ListSourceCredentials</code>: Returns a list of <code>SourceCredentialsInfo</code> objects. Each <code>SourceCredentialsInfo</code> object includes the authentication type, token ARN, and type of source provider for one set of credentials.</p> </li> <li> <p> <code>PutResourcePolicy</code>: Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. </p> </li> <li> <p> <code>StartBuild</code>: Starts running a build.</p> </li> <li> <p> <code>StopBuild</code>: Attempts to stop running a build.</p> </li> <li> <p> <code>UpdateProject</code>: Changes the settings of an existing build project.</p> </li> <li> <p> <code>UpdateReportGroup</code>: Changes a report group.</p> </li> <li> <p> <code>UpdateWebhook</code>: Changes the settings of an existing webhook.</p> </li> </ul>
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

  OpenApiRestCall_605590 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605590](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605590): Option[Scheme] {.used.} =
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
  Call_BatchDeleteBuilds_605928 = ref object of OpenApiRestCall_605590
proc url_BatchDeleteBuilds_605930(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteBuilds_605929(path: JsonNode; query: JsonNode;
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
  var valid_606055 = header.getOrDefault("X-Amz-Target")
  valid_606055 = validateParameter(valid_606055, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_606055 != nil:
    section.add "X-Amz-Target", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_BatchDeleteBuilds_605928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_BatchDeleteBuilds_605928; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_606158 = newJObject()
  if body != nil:
    body_606158 = body
  result = call_606157.call(nil, nil, nil, nil, body_606158)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_605928(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_605929, base: "/",
    url: url_BatchDeleteBuilds_605930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_606197 = ref object of OpenApiRestCall_605590
proc url_BatchGetBuilds_606199(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetBuilds_606198(path: JsonNode; query: JsonNode;
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
  var valid_606200 = header.getOrDefault("X-Amz-Target")
  valid_606200 = validateParameter(valid_606200, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_606200 != nil:
    section.add "X-Amz-Target", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_BatchGetBuilds_606197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more builds.
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_BatchGetBuilds_606197; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about one or more builds.
  ##   body: JObject (required)
  var body_606211 = newJObject()
  if body != nil:
    body_606211 = body
  result = call_606210.call(nil, nil, nil, nil, body_606211)

var batchGetBuilds* = Call_BatchGetBuilds_606197(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_606198, base: "/", url: url_BatchGetBuilds_606199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_606212 = ref object of OpenApiRestCall_605590
proc url_BatchGetProjects_606214(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetProjects_606213(path: JsonNode; query: JsonNode;
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
  var valid_606215 = header.getOrDefault("X-Amz-Target")
  valid_606215 = validateParameter(valid_606215, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_606215 != nil:
    section.add "X-Amz-Target", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-SignedHeaders", valid_606222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_BatchGetProjects_606212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more build projects.
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_BatchGetProjects_606212; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about one or more build projects.
  ##   body: JObject (required)
  var body_606226 = newJObject()
  if body != nil:
    body_606226 = body
  result = call_606225.call(nil, nil, nil, nil, body_606226)

var batchGetProjects* = Call_BatchGetProjects_606212(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_606213, base: "/",
    url: url_BatchGetProjects_606214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReportGroups_606227 = ref object of OpenApiRestCall_605590
proc url_BatchGetReportGroups_606229(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetReportGroups_606228(path: JsonNode; query: JsonNode;
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
  var valid_606230 = header.getOrDefault("X-Amz-Target")
  valid_606230 = validateParameter(valid_606230, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReportGroups"))
  if valid_606230 != nil:
    section.add "X-Amz-Target", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Signature")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Signature", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Content-Sha256", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Date")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Date", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Credential")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Credential", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Security-Token")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Security-Token", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Algorithm")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Algorithm", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-SignedHeaders", valid_606237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_BatchGetReportGroups_606227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of report groups. 
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_BatchGetReportGroups_606227; body: JsonNode): Recallable =
  ## batchGetReportGroups
  ##  Returns an array of report groups. 
  ##   body: JObject (required)
  var body_606241 = newJObject()
  if body != nil:
    body_606241 = body
  result = call_606240.call(nil, nil, nil, nil, body_606241)

var batchGetReportGroups* = Call_BatchGetReportGroups_606227(
    name: "batchGetReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups",
    validator: validate_BatchGetReportGroups_606228, base: "/",
    url: url_BatchGetReportGroups_606229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetReports_606242 = ref object of OpenApiRestCall_605590
proc url_BatchGetReports_606244(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetReports_606243(path: JsonNode; query: JsonNode;
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
  var valid_606245 = header.getOrDefault("X-Amz-Target")
  valid_606245 = validateParameter(valid_606245, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetReports"))
  if valid_606245 != nil:
    section.add "X-Amz-Target", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_BatchGetReports_606242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of reports. 
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_BatchGetReports_606242; body: JsonNode): Recallable =
  ## batchGetReports
  ##  Returns an array of reports. 
  ##   body: JObject (required)
  var body_606256 = newJObject()
  if body != nil:
    body_606256 = body
  result = call_606255.call(nil, nil, nil, nil, body_606256)

var batchGetReports* = Call_BatchGetReports_606242(name: "batchGetReports",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetReports",
    validator: validate_BatchGetReports_606243, base: "/", url: url_BatchGetReports_606244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_606257 = ref object of OpenApiRestCall_605590
proc url_CreateProject_606259(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_606258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606260 = header.getOrDefault("X-Amz-Target")
  valid_606260 = validateParameter(valid_606260, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_606260 != nil:
    section.add "X-Amz-Target", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606269: Call_CreateProject_606257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_606269.validator(path, query, header, formData, body)
  let scheme = call_606269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606269.url(scheme.get, call_606269.host, call_606269.base,
                         call_606269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606269, url, valid)

proc call*(call_606270: Call_CreateProject_606257; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_606271 = newJObject()
  if body != nil:
    body_606271 = body
  result = call_606270.call(nil, nil, nil, nil, body_606271)

var createProject* = Call_CreateProject_606257(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_606258, base: "/", url: url_CreateProject_606259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReportGroup_606272 = ref object of OpenApiRestCall_605590
proc url_CreateReportGroup_606274(protocol: Scheme; host: string; base: string;
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

proc validate_CreateReportGroup_606273(path: JsonNode; query: JsonNode;
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
  var valid_606275 = header.getOrDefault("X-Amz-Target")
  valid_606275 = validateParameter(valid_606275, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateReportGroup"))
  if valid_606275 != nil:
    section.add "X-Amz-Target", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Signature")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Signature", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Content-Sha256", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Date")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Date", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Credential")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Credential", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Security-Token")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Security-Token", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Algorithm")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Algorithm", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-SignedHeaders", valid_606282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606284: Call_CreateReportGroup_606272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a report group. A report group contains a collection of reports. 
  ## 
  let valid = call_606284.validator(path, query, header, formData, body)
  let scheme = call_606284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606284.url(scheme.get, call_606284.host, call_606284.base,
                         call_606284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606284, url, valid)

proc call*(call_606285: Call_CreateReportGroup_606272; body: JsonNode): Recallable =
  ## createReportGroup
  ##  Creates a report group. A report group contains a collection of reports. 
  ##   body: JObject (required)
  var body_606286 = newJObject()
  if body != nil:
    body_606286 = body
  result = call_606285.call(nil, nil, nil, nil, body_606286)

var createReportGroup* = Call_CreateReportGroup_606272(name: "createReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateReportGroup",
    validator: validate_CreateReportGroup_606273, base: "/",
    url: url_CreateReportGroup_606274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_606287 = ref object of OpenApiRestCall_605590
proc url_CreateWebhook_606289(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_606288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606290 = header.getOrDefault("X-Amz-Target")
  valid_606290 = validateParameter(valid_606290, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_606290 != nil:
    section.add "X-Amz-Target", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Signature")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Signature", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Content-Sha256", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Date")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Date", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Credential")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Credential", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Security-Token")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Security-Token", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Algorithm")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Algorithm", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-SignedHeaders", valid_606297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606299: Call_CreateWebhook_606287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_606299.validator(path, query, header, formData, body)
  let scheme = call_606299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606299.url(scheme.get, call_606299.host, call_606299.base,
                         call_606299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606299, url, valid)

proc call*(call_606300: Call_CreateWebhook_606287; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_606301 = newJObject()
  if body != nil:
    body_606301 = body
  result = call_606300.call(nil, nil, nil, nil, body_606301)

var createWebhook* = Call_CreateWebhook_606287(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_606288, base: "/", url: url_CreateWebhook_606289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_606302 = ref object of OpenApiRestCall_605590
proc url_DeleteProject_606304(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProject_606303(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606305 = header.getOrDefault("X-Amz-Target")
  valid_606305 = validateParameter(valid_606305, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_606305 != nil:
    section.add "X-Amz-Target", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Signature")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Signature", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Content-Sha256", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Date")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Date", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Credential")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Credential", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Security-Token")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Security-Token", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Algorithm")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Algorithm", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-SignedHeaders", valid_606312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_DeleteProject_606302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_DeleteProject_606302; body: JsonNode): Recallable =
  ## deleteProject
  ##  Deletes a build project. When you delete a project, its builds are not deleted. 
  ##   body: JObject (required)
  var body_606316 = newJObject()
  if body != nil:
    body_606316 = body
  result = call_606315.call(nil, nil, nil, nil, body_606316)

var deleteProject* = Call_DeleteProject_606302(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_606303, base: "/", url: url_DeleteProject_606304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReport_606317 = ref object of OpenApiRestCall_605590
proc url_DeleteReport_606319(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReport_606318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606320 = header.getOrDefault("X-Amz-Target")
  valid_606320 = validateParameter(valid_606320, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReport"))
  if valid_606320 != nil:
    section.add "X-Amz-Target", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Signature")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Signature", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Content-Sha256", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Date")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Date", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Credential")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Credential", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Security-Token")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Security-Token", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606329: Call_DeleteReport_606317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a report. 
  ## 
  let valid = call_606329.validator(path, query, header, formData, body)
  let scheme = call_606329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606329.url(scheme.get, call_606329.host, call_606329.base,
                         call_606329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606329, url, valid)

proc call*(call_606330: Call_DeleteReport_606317; body: JsonNode): Recallable =
  ## deleteReport
  ##  Deletes a report. 
  ##   body: JObject (required)
  var body_606331 = newJObject()
  if body != nil:
    body_606331 = body
  result = call_606330.call(nil, nil, nil, nil, body_606331)

var deleteReport* = Call_DeleteReport_606317(name: "deleteReport",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReport",
    validator: validate_DeleteReport_606318, base: "/", url: url_DeleteReport_606319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReportGroup_606332 = ref object of OpenApiRestCall_605590
proc url_DeleteReportGroup_606334(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReportGroup_606333(path: JsonNode; query: JsonNode;
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
  var valid_606335 = header.getOrDefault("X-Amz-Target")
  valid_606335 = validateParameter(valid_606335, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteReportGroup"))
  if valid_606335 != nil:
    section.add "X-Amz-Target", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Signature")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Signature", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Content-Sha256", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Date")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Date", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Credential")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Credential", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Security-Token")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Security-Token", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Algorithm")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Algorithm", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-SignedHeaders", valid_606342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606344: Call_DeleteReportGroup_606332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ## 
  let valid = call_606344.validator(path, query, header, formData, body)
  let scheme = call_606344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606344.url(scheme.get, call_606344.host, call_606344.base,
                         call_606344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606344, url, valid)

proc call*(call_606345: Call_DeleteReportGroup_606332; body: JsonNode): Recallable =
  ## deleteReportGroup
  ##  <code>DeleteReportGroup</code>: Deletes a report group. Before you delete a report group, you must delete its reports. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html">ListReportsForReportGroup</a> to get the reports in a report group. Use <a href="https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html">DeleteReport</a> to delete the reports. If you call <code>DeleteReportGroup</code> for a report group that contains one or more reports, an exception is thrown. 
  ##   body: JObject (required)
  var body_606346 = newJObject()
  if body != nil:
    body_606346 = body
  result = call_606345.call(nil, nil, nil, nil, body_606346)

var deleteReportGroup* = Call_DeleteReportGroup_606332(name: "deleteReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup",
    validator: validate_DeleteReportGroup_606333, base: "/",
    url: url_DeleteReportGroup_606334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_606347 = ref object of OpenApiRestCall_605590
proc url_DeleteResourcePolicy_606349(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_606348(path: JsonNode; query: JsonNode;
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
  var valid_606350 = header.getOrDefault("X-Amz-Target")
  valid_606350 = validateParameter(valid_606350, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteResourcePolicy"))
  if valid_606350 != nil:
    section.add "X-Amz-Target", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Signature")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Signature", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Content-Sha256", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Date")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Date", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Credential")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Credential", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Security-Token")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Security-Token", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Algorithm")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Algorithm", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-SignedHeaders", valid_606357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_DeleteResourcePolicy_606347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_DeleteResourcePolicy_606347; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ##  Deletes a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_606361 = newJObject()
  if body != nil:
    body_606361 = body
  result = call_606360.call(nil, nil, nil, nil, body_606361)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_606347(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_606348, base: "/",
    url: url_DeleteResourcePolicy_606349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_606362 = ref object of OpenApiRestCall_605590
proc url_DeleteSourceCredentials_606364(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSourceCredentials_606363(path: JsonNode; query: JsonNode;
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
  var valid_606365 = header.getOrDefault("X-Amz-Target")
  valid_606365 = validateParameter(valid_606365, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_606365 != nil:
    section.add "X-Amz-Target", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Signature")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Signature", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Content-Sha256", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Date")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Date", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Credential")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Credential", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Security-Token")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Security-Token", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Algorithm")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Algorithm", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-SignedHeaders", valid_606372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606374: Call_DeleteSourceCredentials_606362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_606374.validator(path, query, header, formData, body)
  let scheme = call_606374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606374.url(scheme.get, call_606374.host, call_606374.base,
                         call_606374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606374, url, valid)

proc call*(call_606375: Call_DeleteSourceCredentials_606362; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_606376 = newJObject()
  if body != nil:
    body_606376 = body
  result = call_606375.call(nil, nil, nil, nil, body_606376)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_606362(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_606363, base: "/",
    url: url_DeleteSourceCredentials_606364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_606377 = ref object of OpenApiRestCall_605590
proc url_DeleteWebhook_606379(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_606378(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606380 = header.getOrDefault("X-Amz-Target")
  valid_606380 = validateParameter(valid_606380, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_606380 != nil:
    section.add "X-Amz-Target", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Signature")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Signature", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Content-Sha256", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Date")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Date", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Credential")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Credential", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Security-Token")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Security-Token", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Algorithm")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Algorithm", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-SignedHeaders", valid_606387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606389: Call_DeleteWebhook_606377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_606389.validator(path, query, header, formData, body)
  let scheme = call_606389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606389.url(scheme.get, call_606389.host, call_606389.base,
                         call_606389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606389, url, valid)

proc call*(call_606390: Call_DeleteWebhook_606377; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_606391 = newJObject()
  if body != nil:
    body_606391 = body
  result = call_606390.call(nil, nil, nil, nil, body_606391)

var deleteWebhook* = Call_DeleteWebhook_606377(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_606378, base: "/", url: url_DeleteWebhook_606379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTestCases_606392 = ref object of OpenApiRestCall_605590
proc url_DescribeTestCases_606394(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTestCases_606393(path: JsonNode; query: JsonNode;
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
  var valid_606395 = header.getOrDefault("X-Amz-Target")
  valid_606395 = validateParameter(valid_606395, JString, required = true, default = newJString(
      "CodeBuild_20161006.DescribeTestCases"))
  if valid_606395 != nil:
    section.add "X-Amz-Target", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Signature")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Signature", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Content-Sha256", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Date")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Date", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Credential")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Credential", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Security-Token")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Security-Token", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Algorithm")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Algorithm", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-SignedHeaders", valid_606402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606404: Call_DescribeTestCases_606392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of details about test cases for a report. 
  ## 
  let valid = call_606404.validator(path, query, header, formData, body)
  let scheme = call_606404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606404.url(scheme.get, call_606404.host, call_606404.base,
                         call_606404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606404, url, valid)

proc call*(call_606405: Call_DescribeTestCases_606392; body: JsonNode): Recallable =
  ## describeTestCases
  ##  Returns a list of details about test cases for a report. 
  ##   body: JObject (required)
  var body_606406 = newJObject()
  if body != nil:
    body_606406 = body
  result = call_606405.call(nil, nil, nil, nil, body_606406)

var describeTestCases* = Call_DescribeTestCases_606392(name: "describeTestCases",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DescribeTestCases",
    validator: validate_DescribeTestCases_606393, base: "/",
    url: url_DescribeTestCases_606394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_606407 = ref object of OpenApiRestCall_605590
proc url_GetResourcePolicy_606409(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_606408(path: JsonNode; query: JsonNode;
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
  var valid_606410 = header.getOrDefault("X-Amz-Target")
  valid_606410 = validateParameter(valid_606410, JString, required = true, default = newJString(
      "CodeBuild_20161006.GetResourcePolicy"))
  if valid_606410 != nil:
    section.add "X-Amz-Target", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Security-Token")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Security-Token", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Algorithm")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Algorithm", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-SignedHeaders", valid_606417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606419: Call_GetResourcePolicy_606407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a resource policy that is identified by its resource ARN. 
  ## 
  let valid = call_606419.validator(path, query, header, formData, body)
  let scheme = call_606419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606419.url(scheme.get, call_606419.host, call_606419.base,
                         call_606419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606419, url, valid)

proc call*(call_606420: Call_GetResourcePolicy_606407; body: JsonNode): Recallable =
  ## getResourcePolicy
  ##  Gets a resource policy that is identified by its resource ARN. 
  ##   body: JObject (required)
  var body_606421 = newJObject()
  if body != nil:
    body_606421 = body
  result = call_606420.call(nil, nil, nil, nil, body_606421)

var getResourcePolicy* = Call_GetResourcePolicy_606407(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy",
    validator: validate_GetResourcePolicy_606408, base: "/",
    url: url_GetResourcePolicy_606409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_606422 = ref object of OpenApiRestCall_605590
proc url_ImportSourceCredentials_606424(protocol: Scheme; host: string; base: string;
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

proc validate_ImportSourceCredentials_606423(path: JsonNode; query: JsonNode;
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
  var valid_606425 = header.getOrDefault("X-Amz-Target")
  valid_606425 = validateParameter(valid_606425, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_606425 != nil:
    section.add "X-Amz-Target", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Signature")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Signature", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Content-Sha256", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Date")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Date", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Credential")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Credential", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Security-Token")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Security-Token", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Algorithm")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Algorithm", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-SignedHeaders", valid_606432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606434: Call_ImportSourceCredentials_606422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_606434.validator(path, query, header, formData, body)
  let scheme = call_606434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606434.url(scheme.get, call_606434.host, call_606434.base,
                         call_606434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606434, url, valid)

proc call*(call_606435: Call_ImportSourceCredentials_606422; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_606436 = newJObject()
  if body != nil:
    body_606436 = body
  result = call_606435.call(nil, nil, nil, nil, body_606436)

var importSourceCredentials* = Call_ImportSourceCredentials_606422(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_606423, base: "/",
    url: url_ImportSourceCredentials_606424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_606437 = ref object of OpenApiRestCall_605590
proc url_InvalidateProjectCache_606439(protocol: Scheme; host: string; base: string;
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

proc validate_InvalidateProjectCache_606438(path: JsonNode; query: JsonNode;
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
  var valid_606440 = header.getOrDefault("X-Amz-Target")
  valid_606440 = validateParameter(valid_606440, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_606440 != nil:
    section.add "X-Amz-Target", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Signature")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Signature", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Content-Sha256", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Date")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Date", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Credential")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Credential", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Security-Token")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Security-Token", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Algorithm")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Algorithm", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-SignedHeaders", valid_606447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606449: Call_InvalidateProjectCache_606437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_606449.validator(path, query, header, formData, body)
  let scheme = call_606449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606449.url(scheme.get, call_606449.host, call_606449.base,
                         call_606449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606449, url, valid)

proc call*(call_606450: Call_InvalidateProjectCache_606437; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_606451 = newJObject()
  if body != nil:
    body_606451 = body
  result = call_606450.call(nil, nil, nil, nil, body_606451)

var invalidateProjectCache* = Call_InvalidateProjectCache_606437(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_606438, base: "/",
    url: url_InvalidateProjectCache_606439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_606452 = ref object of OpenApiRestCall_605590
proc url_ListBuilds_606454(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBuilds_606453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606455 = header.getOrDefault("X-Amz-Target")
  valid_606455 = validateParameter(valid_606455, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_606455 != nil:
    section.add "X-Amz-Target", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Signature")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Signature", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Content-Sha256", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Date")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Date", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Credential")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Credential", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Security-Token")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Security-Token", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Algorithm")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Algorithm", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-SignedHeaders", valid_606462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606464: Call_ListBuilds_606452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_606464.validator(path, query, header, formData, body)
  let scheme = call_606464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606464.url(scheme.get, call_606464.host, call_606464.base,
                         call_606464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606464, url, valid)

proc call*(call_606465: Call_ListBuilds_606452; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_606466 = newJObject()
  if body != nil:
    body_606466 = body
  result = call_606465.call(nil, nil, nil, nil, body_606466)

var listBuilds* = Call_ListBuilds_606452(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                      validator: validate_ListBuilds_606453,
                                      base: "/", url: url_ListBuilds_606454,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_606467 = ref object of OpenApiRestCall_605590
proc url_ListBuildsForProject_606469(protocol: Scheme; host: string; base: string;
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

proc validate_ListBuildsForProject_606468(path: JsonNode; query: JsonNode;
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
  var valid_606470 = header.getOrDefault("X-Amz-Target")
  valid_606470 = validateParameter(valid_606470, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_606470 != nil:
    section.add "X-Amz-Target", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Signature")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Signature", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Content-Sha256", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Date")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Date", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Credential")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Credential", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Security-Token")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Security-Token", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Algorithm")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Algorithm", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-SignedHeaders", valid_606477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606479: Call_ListBuildsForProject_606467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_606479.validator(path, query, header, formData, body)
  let scheme = call_606479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606479.url(scheme.get, call_606479.host, call_606479.base,
                         call_606479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606479, url, valid)

proc call*(call_606480: Call_ListBuildsForProject_606467; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_606481 = newJObject()
  if body != nil:
    body_606481 = body
  result = call_606480.call(nil, nil, nil, nil, body_606481)

var listBuildsForProject* = Call_ListBuildsForProject_606467(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_606468, base: "/",
    url: url_ListBuildsForProject_606469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_606482 = ref object of OpenApiRestCall_605590
proc url_ListCuratedEnvironmentImages_606484(protocol: Scheme; host: string;
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

proc validate_ListCuratedEnvironmentImages_606483(path: JsonNode; query: JsonNode;
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
  var valid_606485 = header.getOrDefault("X-Amz-Target")
  valid_606485 = validateParameter(valid_606485, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_606485 != nil:
    section.add "X-Amz-Target", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Signature")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Signature", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Content-Sha256", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Date")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Date", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Credential")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Credential", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Security-Token")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Security-Token", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Algorithm")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Algorithm", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-SignedHeaders", valid_606492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_ListCuratedEnvironmentImages_606482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_ListCuratedEnvironmentImages_606482; body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_606496 = newJObject()
  if body != nil:
    body_606496 = body
  result = call_606495.call(nil, nil, nil, nil, body_606496)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_606482(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_606483, base: "/",
    url: url_ListCuratedEnvironmentImages_606484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_606497 = ref object of OpenApiRestCall_605590
proc url_ListProjects_606499(protocol: Scheme; host: string; base: string;
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

proc validate_ListProjects_606498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606500 = header.getOrDefault("X-Amz-Target")
  valid_606500 = validateParameter(valid_606500, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_606500 != nil:
    section.add "X-Amz-Target", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Signature")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Signature", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Content-Sha256", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Date")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Date", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Credential")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Credential", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Security-Token")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Security-Token", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Algorithm")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Algorithm", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-SignedHeaders", valid_606507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606509: Call_ListProjects_606497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_606509.validator(path, query, header, formData, body)
  let scheme = call_606509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606509.url(scheme.get, call_606509.host, call_606509.base,
                         call_606509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606509, url, valid)

proc call*(call_606510: Call_ListProjects_606497; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_606511 = newJObject()
  if body != nil:
    body_606511 = body
  result = call_606510.call(nil, nil, nil, nil, body_606511)

var listProjects* = Call_ListProjects_606497(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_606498, base: "/", url: url_ListProjects_606499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportGroups_606512 = ref object of OpenApiRestCall_605590
proc url_ListReportGroups_606514(protocol: Scheme; host: string; base: string;
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

proc validate_ListReportGroups_606513(path: JsonNode; query: JsonNode;
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
  var valid_606515 = header.getOrDefault("X-Amz-Target")
  valid_606515 = validateParameter(valid_606515, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportGroups"))
  if valid_606515 != nil:
    section.add "X-Amz-Target", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Signature")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Signature", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Content-Sha256", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Date")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Date", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Credential")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Credential", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Security-Token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Security-Token", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Algorithm")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Algorithm", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-SignedHeaders", valid_606522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606524: Call_ListReportGroups_606512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ## 
  let valid = call_606524.validator(path, query, header, formData, body)
  let scheme = call_606524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606524.url(scheme.get, call_606524.host, call_606524.base,
                         call_606524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606524, url, valid)

proc call*(call_606525: Call_ListReportGroups_606512; body: JsonNode): Recallable =
  ## listReportGroups
  ##  Gets a list ARNs for the report groups in the current AWS account. 
  ##   body: JObject (required)
  var body_606526 = newJObject()
  if body != nil:
    body_606526 = body
  result = call_606525.call(nil, nil, nil, nil, body_606526)

var listReportGroups* = Call_ListReportGroups_606512(name: "listReportGroups",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportGroups",
    validator: validate_ListReportGroups_606513, base: "/",
    url: url_ListReportGroups_606514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReports_606527 = ref object of OpenApiRestCall_605590
proc url_ListReports_606529(protocol: Scheme; host: string; base: string;
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

proc validate_ListReports_606528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606530 = header.getOrDefault("X-Amz-Target")
  valid_606530 = validateParameter(valid_606530, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReports"))
  if valid_606530 != nil:
    section.add "X-Amz-Target", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Security-Token")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Security-Token", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Algorithm")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Algorithm", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-SignedHeaders", valid_606537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_ListReports_606527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_ListReports_606527; body: JsonNode): Recallable =
  ## listReports
  ##  Returns a list of ARNs for the reports in the current AWS account. 
  ##   body: JObject (required)
  var body_606541 = newJObject()
  if body != nil:
    body_606541 = body
  result = call_606540.call(nil, nil, nil, nil, body_606541)

var listReports* = Call_ListReports_606527(name: "listReports",
                                        meth: HttpMethod.HttpPost,
                                        host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListReports",
                                        validator: validate_ListReports_606528,
                                        base: "/", url: url_ListReports_606529,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReportsForReportGroup_606542 = ref object of OpenApiRestCall_605590
proc url_ListReportsForReportGroup_606544(protocol: Scheme; host: string;
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

proc validate_ListReportsForReportGroup_606543(path: JsonNode; query: JsonNode;
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
  var valid_606545 = header.getOrDefault("X-Amz-Target")
  valid_606545 = validateParameter(valid_606545, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListReportsForReportGroup"))
  if valid_606545 != nil:
    section.add "X-Amz-Target", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_ListReportsForReportGroup_606542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_ListReportsForReportGroup_606542; body: JsonNode): Recallable =
  ## listReportsForReportGroup
  ##  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
  ##   body: JObject (required)
  var body_606556 = newJObject()
  if body != nil:
    body_606556 = body
  result = call_606555.call(nil, nil, nil, nil, body_606556)

var listReportsForReportGroup* = Call_ListReportsForReportGroup_606542(
    name: "listReportsForReportGroup", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup",
    validator: validate_ListReportsForReportGroup_606543, base: "/",
    url: url_ListReportsForReportGroup_606544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedProjects_606557 = ref object of OpenApiRestCall_605590
proc url_ListSharedProjects_606559(protocol: Scheme; host: string; base: string;
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

proc validate_ListSharedProjects_606558(path: JsonNode; query: JsonNode;
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
  var valid_606560 = header.getOrDefault("X-Amz-Target")
  valid_606560 = validateParameter(valid_606560, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedProjects"))
  if valid_606560 != nil:
    section.add "X-Amz-Target", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Signature")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Signature", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Content-Sha256", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Date")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Date", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Credential")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Credential", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Security-Token")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Security-Token", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Algorithm")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Algorithm", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-SignedHeaders", valid_606567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_ListSharedProjects_606557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_ListSharedProjects_606557; body: JsonNode): Recallable =
  ## listSharedProjects
  ##  Gets a list of projects that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_606571 = newJObject()
  if body != nil:
    body_606571 = body
  result = call_606570.call(nil, nil, nil, nil, body_606571)

var listSharedProjects* = Call_ListSharedProjects_606557(
    name: "listSharedProjects", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedProjects",
    validator: validate_ListSharedProjects_606558, base: "/",
    url: url_ListSharedProjects_606559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSharedReportGroups_606572 = ref object of OpenApiRestCall_605590
proc url_ListSharedReportGroups_606574(protocol: Scheme; host: string; base: string;
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

proc validate_ListSharedReportGroups_606573(path: JsonNode; query: JsonNode;
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
  var valid_606575 = header.getOrDefault("X-Amz-Target")
  valid_606575 = validateParameter(valid_606575, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSharedReportGroups"))
  if valid_606575 != nil:
    section.add "X-Amz-Target", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Signature")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Signature", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Content-Sha256", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Date")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Date", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Credential")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Credential", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Security-Token")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Security-Token", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Algorithm")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Algorithm", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-SignedHeaders", valid_606582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606584: Call_ListSharedReportGroups_606572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ## 
  let valid = call_606584.validator(path, query, header, formData, body)
  let scheme = call_606584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606584.url(scheme.get, call_606584.host, call_606584.base,
                         call_606584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606584, url, valid)

proc call*(call_606585: Call_ListSharedReportGroups_606572; body: JsonNode): Recallable =
  ## listSharedReportGroups
  ##  Gets a list of report groups that are shared with other AWS accounts or users. 
  ##   body: JObject (required)
  var body_606586 = newJObject()
  if body != nil:
    body_606586 = body
  result = call_606585.call(nil, nil, nil, nil, body_606586)

var listSharedReportGroups* = Call_ListSharedReportGroups_606572(
    name: "listSharedReportGroups", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups",
    validator: validate_ListSharedReportGroups_606573, base: "/",
    url: url_ListSharedReportGroups_606574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_606587 = ref object of OpenApiRestCall_605590
proc url_ListSourceCredentials_606589(protocol: Scheme; host: string; base: string;
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

proc validate_ListSourceCredentials_606588(path: JsonNode; query: JsonNode;
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
  var valid_606590 = header.getOrDefault("X-Amz-Target")
  valid_606590 = validateParameter(valid_606590, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_606590 != nil:
    section.add "X-Amz-Target", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Signature")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Signature", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Content-Sha256", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Date")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Date", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Credential")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Credential", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Security-Token")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Security-Token", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Algorithm")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Algorithm", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-SignedHeaders", valid_606597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606599: Call_ListSourceCredentials_606587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_606599.validator(path, query, header, formData, body)
  let scheme = call_606599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606599.url(scheme.get, call_606599.host, call_606599.base,
                         call_606599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606599, url, valid)

proc call*(call_606600: Call_ListSourceCredentials_606587; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_606601 = newJObject()
  if body != nil:
    body_606601 = body
  result = call_606600.call(nil, nil, nil, nil, body_606601)

var listSourceCredentials* = Call_ListSourceCredentials_606587(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_606588, base: "/",
    url: url_ListSourceCredentials_606589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_606602 = ref object of OpenApiRestCall_605590
proc url_PutResourcePolicy_606604(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_606603(path: JsonNode; query: JsonNode;
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
  var valid_606605 = header.getOrDefault("X-Amz-Target")
  valid_606605 = validateParameter(valid_606605, JString, required = true, default = newJString(
      "CodeBuild_20161006.PutResourcePolicy"))
  if valid_606605 != nil:
    section.add "X-Amz-Target", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Signature")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Signature", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Content-Sha256", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Date")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Date", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Credential")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Credential", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Security-Token")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Security-Token", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Algorithm")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Algorithm", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-SignedHeaders", valid_606612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606614: Call_PutResourcePolicy_606602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ## 
  let valid = call_606614.validator(path, query, header, formData, body)
  let scheme = call_606614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606614.url(scheme.get, call_606614.host, call_606614.base,
                         call_606614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606614, url, valid)

proc call*(call_606615: Call_PutResourcePolicy_606602; body: JsonNode): Recallable =
  ## putResourcePolicy
  ##  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
  ##   body: JObject (required)
  var body_606616 = newJObject()
  if body != nil:
    body_606616 = body
  result = call_606615.call(nil, nil, nil, nil, body_606616)

var putResourcePolicy* = Call_PutResourcePolicy_606602(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy",
    validator: validate_PutResourcePolicy_606603, base: "/",
    url: url_PutResourcePolicy_606604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_606617 = ref object of OpenApiRestCall_605590
proc url_StartBuild_606619(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartBuild_606618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606620 = header.getOrDefault("X-Amz-Target")
  valid_606620 = validateParameter(valid_606620, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_606620 != nil:
    section.add "X-Amz-Target", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Signature")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Signature", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Content-Sha256", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Date")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Date", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Credential")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Credential", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Security-Token")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Security-Token", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Algorithm")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Algorithm", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-SignedHeaders", valid_606627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606629: Call_StartBuild_606617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_606629.validator(path, query, header, formData, body)
  let scheme = call_606629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606629.url(scheme.get, call_606629.host, call_606629.base,
                         call_606629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606629, url, valid)

proc call*(call_606630: Call_StartBuild_606617; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_606631 = newJObject()
  if body != nil:
    body_606631 = body
  result = call_606630.call(nil, nil, nil, nil, body_606631)

var startBuild* = Call_StartBuild_606617(name: "startBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                      validator: validate_StartBuild_606618,
                                      base: "/", url: url_StartBuild_606619,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_606632 = ref object of OpenApiRestCall_605590
proc url_StopBuild_606634(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopBuild_606633(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606635 = header.getOrDefault("X-Amz-Target")
  valid_606635 = validateParameter(valid_606635, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_606635 != nil:
    section.add "X-Amz-Target", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Signature")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Signature", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Content-Sha256", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Date")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Date", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Credential")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Credential", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Security-Token")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Security-Token", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Algorithm")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Algorithm", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-SignedHeaders", valid_606642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606644: Call_StopBuild_606632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_606644.validator(path, query, header, formData, body)
  let scheme = call_606644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606644.url(scheme.get, call_606644.host, call_606644.base,
                         call_606644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606644, url, valid)

proc call*(call_606645: Call_StopBuild_606632; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_606646 = newJObject()
  if body != nil:
    body_606646 = body
  result = call_606645.call(nil, nil, nil, nil, body_606646)

var stopBuild* = Call_StopBuild_606632(name: "stopBuild", meth: HttpMethod.HttpPost,
                                    host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                    validator: validate_StopBuild_606633,
                                    base: "/", url: url_StopBuild_606634,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_606647 = ref object of OpenApiRestCall_605590
proc url_UpdateProject_606649(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProject_606648(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606650 = header.getOrDefault("X-Amz-Target")
  valid_606650 = validateParameter(valid_606650, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_606650 != nil:
    section.add "X-Amz-Target", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Signature")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Signature", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Content-Sha256", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Date")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Date", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Credential")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Credential", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Security-Token")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Security-Token", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Algorithm")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Algorithm", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-SignedHeaders", valid_606657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606659: Call_UpdateProject_606647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_606659.validator(path, query, header, formData, body)
  let scheme = call_606659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606659.url(scheme.get, call_606659.host, call_606659.base,
                         call_606659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606659, url, valid)

proc call*(call_606660: Call_UpdateProject_606647; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_606661 = newJObject()
  if body != nil:
    body_606661 = body
  result = call_606660.call(nil, nil, nil, nil, body_606661)

var updateProject* = Call_UpdateProject_606647(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_606648, base: "/", url: url_UpdateProject_606649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReportGroup_606662 = ref object of OpenApiRestCall_605590
proc url_UpdateReportGroup_606664(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReportGroup_606663(path: JsonNode; query: JsonNode;
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
  var valid_606665 = header.getOrDefault("X-Amz-Target")
  valid_606665 = validateParameter(valid_606665, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateReportGroup"))
  if valid_606665 != nil:
    section.add "X-Amz-Target", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Signature")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Signature", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Content-Sha256", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Date")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Date", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Credential")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Credential", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Security-Token")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Security-Token", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Algorithm")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Algorithm", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-SignedHeaders", valid_606672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606674: Call_UpdateReportGroup_606662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a report group. 
  ## 
  let valid = call_606674.validator(path, query, header, formData, body)
  let scheme = call_606674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606674.url(scheme.get, call_606674.host, call_606674.base,
                         call_606674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606674, url, valid)

proc call*(call_606675: Call_UpdateReportGroup_606662; body: JsonNode): Recallable =
  ## updateReportGroup
  ##  Updates a report group. 
  ##   body: JObject (required)
  var body_606676 = newJObject()
  if body != nil:
    body_606676 = body
  result = call_606675.call(nil, nil, nil, nil, body_606676)

var updateReportGroup* = Call_UpdateReportGroup_606662(name: "updateReportGroup",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup",
    validator: validate_UpdateReportGroup_606663, base: "/",
    url: url_UpdateReportGroup_606664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_606677 = ref object of OpenApiRestCall_605590
proc url_UpdateWebhook_606679(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_606678(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606680 = header.getOrDefault("X-Amz-Target")
  valid_606680 = validateParameter(valid_606680, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_606680 != nil:
    section.add "X-Amz-Target", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Signature")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Signature", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Content-Sha256", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Date")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Date", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Credential")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Credential", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Security-Token")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Security-Token", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Algorithm")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Algorithm", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-SignedHeaders", valid_606687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606689: Call_UpdateWebhook_606677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_606689.validator(path, query, header, formData, body)
  let scheme = call_606689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606689.url(scheme.get, call_606689.host, call_606689.base,
                         call_606689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606689, url, valid)

proc call*(call_606690: Call_UpdateWebhook_606677; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_606691 = newJObject()
  if body != nil:
    body_606691 = body
  result = call_606690.call(nil, nil, nil, nil, body_606691)

var updateWebhook* = Call_UpdateWebhook_606677(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_606678, base: "/", url: url_UpdateWebhook_606679,
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
