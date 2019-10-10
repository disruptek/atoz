
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeBuild
## version: 2016-10-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeBuild</fullname> <p>AWS CodeBuild is a fully managed build service in the cloud. AWS CodeBuild compiles your source code, runs unit tests, and produces artifacts that are ready to deploy. AWS CodeBuild eliminates the need to provision, manage, and scale your own build servers. It provides prepackaged build environments for the most popular programming languages and build tools, such as Apache Maven, Gradle, and more. You can also fully customize build environments in AWS CodeBuild to use your own build tools. AWS CodeBuild scales automatically to meet peak build requests. You pay only for the build time you consume. For more information about AWS CodeBuild, see the <i>AWS CodeBuild User Guide</i>.</p> <p>AWS CodeBuild supports these operations:</p> <ul> <li> <p> <code>BatchDeleteBuilds</code>: Deletes one or more builds.</p> </li> <li> <p> <code>BatchGetProjects</code>: Gets information about one or more build projects. A <i>build project</i> defines how AWS CodeBuild runs a build. This includes information such as where to get the source code to build, the build environment to use, the build commands to run, and where to store the build output. A <i>build environment</i> is a representation of operating system, programming language runtime, and tools that AWS CodeBuild uses to run a build. You can add tags to build projects to help manage your resources and costs.</p> </li> <li> <p> <code>CreateProject</code>: Creates a build project.</p> </li> <li> <p> <code>CreateWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>UpdateWebhook</code>: Changes the settings of an existing webhook.</p> </li> <li> <p> <code>DeleteProject</code>: Deletes a build project.</p> </li> <li> <p> <code>DeleteWebhook</code>: For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.</p> </li> <li> <p> <code>ListProjects</code>: Gets a list of build project names, with each build project name representing a single build project.</p> </li> <li> <p> <code>UpdateProject</code>: Changes the settings of an existing build project.</p> </li> <li> <p> <code>BatchGetBuilds</code>: Gets information about one or more builds.</p> </li> <li> <p> <code>ListBuilds</code>: Gets a list of build IDs, with each build ID representing a single build.</p> </li> <li> <p> <code>ListBuildsForProject</code>: Gets a list of build IDs for the specified build project, with each build ID representing a single build.</p> </li> <li> <p> <code>StartBuild</code>: Starts running a build.</p> </li> <li> <p> <code>StopBuild</code>: Attempts to stop running a build.</p> </li> <li> <p> <code>ListCuratedEnvironmentImages</code>: Gets information about Docker images that are managed by AWS CodeBuild.</p> </li> <li> <p> <code>DeleteSourceCredentials</code>: Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.</p> </li> <li> <p> <code>ImportSourceCredentials</code>: Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.</p> </li> <li> <p> <code>ListSourceCredentials</code>: Returns a list of <code>SourceCredentialsInfo</code> objects. Each <code>SourceCredentialsInfo</code> object includes the authentication type, token ARN, and type of source provider for one set of credentials.</p> </li> </ul>
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

  OpenApiRestCall_602467 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602467](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602467): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDeleteBuilds_602804 = ref object of OpenApiRestCall_602467
proc url_BatchDeleteBuilds_602806(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteBuilds_602805(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Security-Token")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Security-Token", valid_602919
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602933 = header.getOrDefault("X-Amz-Target")
  valid_602933 = validateParameter(valid_602933, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_602933 != nil:
    section.add "X-Amz-Target", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Content-Sha256", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_BatchDeleteBuilds_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602962, url, valid)

proc call*(call_603033: Call_BatchDeleteBuilds_602804; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_603034 = newJObject()
  if body != nil:
    body_603034 = body
  result = call_603033.call(nil, nil, nil, nil, body_603034)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_602804(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_602805, base: "/",
    url: url_BatchDeleteBuilds_602806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_603073 = ref object of OpenApiRestCall_602467
proc url_BatchGetBuilds_603075(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetBuilds_603074(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about builds.
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
  var valid_603076 = header.getOrDefault("X-Amz-Date")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Date", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Security-Token")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Security-Token", valid_603077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603078 = header.getOrDefault("X-Amz-Target")
  valid_603078 = validateParameter(valid_603078, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_603078 != nil:
    section.add "X-Amz-Target", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-SignedHeaders", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_BatchGetBuilds_603073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about builds.
  ## 
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603085, url, valid)

proc call*(call_603086: Call_BatchGetBuilds_603073; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about builds.
  ##   body: JObject (required)
  var body_603087 = newJObject()
  if body != nil:
    body_603087 = body
  result = call_603086.call(nil, nil, nil, nil, body_603087)

var batchGetBuilds* = Call_BatchGetBuilds_603073(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_603074, base: "/", url: url_BatchGetBuilds_603075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_603088 = ref object of OpenApiRestCall_602467
proc url_BatchGetProjects_603090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetProjects_603089(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about build projects.
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
  var valid_603091 = header.getOrDefault("X-Amz-Date")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Date", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Security-Token")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Security-Token", valid_603092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603093 = header.getOrDefault("X-Amz-Target")
  valid_603093 = validateParameter(valid_603093, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_603093 != nil:
    section.add "X-Amz-Target", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Content-Sha256", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Algorithm")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Algorithm", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Signature")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Signature", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-SignedHeaders", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Credential")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Credential", valid_603098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603100: Call_BatchGetProjects_603088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about build projects.
  ## 
  let valid = call_603100.validator(path, query, header, formData, body)
  let scheme = call_603100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603100.url(scheme.get, call_603100.host, call_603100.base,
                         call_603100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603100, url, valid)

proc call*(call_603101: Call_BatchGetProjects_603088; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about build projects.
  ##   body: JObject (required)
  var body_603102 = newJObject()
  if body != nil:
    body_603102 = body
  result = call_603101.call(nil, nil, nil, nil, body_603102)

var batchGetProjects* = Call_BatchGetProjects_603088(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_603089, base: "/",
    url: url_BatchGetProjects_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_603103 = ref object of OpenApiRestCall_602467
proc url_CreateProject_603105(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_603104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603108 = header.getOrDefault("X-Amz-Target")
  valid_603108 = validateParameter(valid_603108, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_603108 != nil:
    section.add "X-Amz-Target", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Content-Sha256", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Algorithm")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Algorithm", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Signature")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Signature", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-SignedHeaders", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_CreateProject_603103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_CreateProject_603103; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_603117 = newJObject()
  if body != nil:
    body_603117 = body
  result = call_603116.call(nil, nil, nil, nil, body_603117)

var createProject* = Call_CreateProject_603103(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_603104, base: "/", url: url_CreateProject_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_603118 = ref object of OpenApiRestCall_602467
proc url_CreateWebhook_603120(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWebhook_603119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Security-Token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Security-Token", valid_603122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603123 = header.getOrDefault("X-Amz-Target")
  valid_603123 = validateParameter(valid_603123, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_603123 != nil:
    section.add "X-Amz-Target", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_CreateWebhook_603118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_CreateWebhook_603118; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_603132 = newJObject()
  if body != nil:
    body_603132 = body
  result = call_603131.call(nil, nil, nil, nil, body_603132)

var createWebhook* = Call_CreateWebhook_603118(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_603119, base: "/", url: url_CreateWebhook_603120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_603133 = ref object of OpenApiRestCall_602467
proc url_DeleteProject_603135(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProject_603134(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a build project.
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
  var valid_603136 = header.getOrDefault("X-Amz-Date")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Date", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Security-Token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Security-Token", valid_603137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603138 = header.getOrDefault("X-Amz-Target")
  valid_603138 = validateParameter(valid_603138, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_603138 != nil:
    section.add "X-Amz-Target", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603145: Call_DeleteProject_603133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a build project.
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603145, url, valid)

proc call*(call_603146: Call_DeleteProject_603133; body: JsonNode): Recallable =
  ## deleteProject
  ## Deletes a build project.
  ##   body: JObject (required)
  var body_603147 = newJObject()
  if body != nil:
    body_603147 = body
  result = call_603146.call(nil, nil, nil, nil, body_603147)

var deleteProject* = Call_DeleteProject_603133(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_603134, base: "/", url: url_DeleteProject_603135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_603148 = ref object of OpenApiRestCall_602467
proc url_DeleteSourceCredentials_603150(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSourceCredentials_603149(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603153 = header.getOrDefault("X-Amz-Target")
  valid_603153 = validateParameter(valid_603153, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_603153 != nil:
    section.add "X-Amz-Target", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Content-Sha256", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Algorithm")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Algorithm", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Signature")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Signature", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_DeleteSourceCredentials_603148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603160, url, valid)

proc call*(call_603161: Call_DeleteSourceCredentials_603148; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_603162 = newJObject()
  if body != nil:
    body_603162 = body
  result = call_603161.call(nil, nil, nil, nil, body_603162)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_603148(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_603149, base: "/",
    url: url_DeleteSourceCredentials_603150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_603163 = ref object of OpenApiRestCall_602467
proc url_DeleteWebhook_603165(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWebhook_603164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603166 = header.getOrDefault("X-Amz-Date")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Date", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603168 = header.getOrDefault("X-Amz-Target")
  valid_603168 = validateParameter(valid_603168, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_603168 != nil:
    section.add "X-Amz-Target", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Algorithm")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Algorithm", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Signature")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Signature", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-SignedHeaders", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603175: Call_DeleteWebhook_603163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_603175.validator(path, query, header, formData, body)
  let scheme = call_603175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603175.url(scheme.get, call_603175.host, call_603175.base,
                         call_603175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603175, url, valid)

proc call*(call_603176: Call_DeleteWebhook_603163; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_603177 = newJObject()
  if body != nil:
    body_603177 = body
  result = call_603176.call(nil, nil, nil, nil, body_603177)

var deleteWebhook* = Call_DeleteWebhook_603163(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_603164, base: "/", url: url_DeleteWebhook_603165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_603178 = ref object of OpenApiRestCall_602467
proc url_ImportSourceCredentials_603180(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportSourceCredentials_603179(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603181 = header.getOrDefault("X-Amz-Date")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Date", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Security-Token")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Security-Token", valid_603182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603183 = header.getOrDefault("X-Amz-Target")
  valid_603183 = validateParameter(valid_603183, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_603183 != nil:
    section.add "X-Amz-Target", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Algorithm")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Algorithm", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Signature")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Signature", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-SignedHeaders", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Credential")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Credential", valid_603188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603190: Call_ImportSourceCredentials_603178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_603190.validator(path, query, header, formData, body)
  let scheme = call_603190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603190.url(scheme.get, call_603190.host, call_603190.base,
                         call_603190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603190, url, valid)

proc call*(call_603191: Call_ImportSourceCredentials_603178; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_603192 = newJObject()
  if body != nil:
    body_603192 = body
  result = call_603191.call(nil, nil, nil, nil, body_603192)

var importSourceCredentials* = Call_ImportSourceCredentials_603178(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_603179, base: "/",
    url: url_ImportSourceCredentials_603180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_603193 = ref object of OpenApiRestCall_602467
proc url_InvalidateProjectCache_603195(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InvalidateProjectCache_603194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603196 = header.getOrDefault("X-Amz-Date")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Date", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Security-Token")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Security-Token", valid_603197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603198 = header.getOrDefault("X-Amz-Target")
  valid_603198 = validateParameter(valid_603198, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_603198 != nil:
    section.add "X-Amz-Target", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603205: Call_InvalidateProjectCache_603193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_603205.validator(path, query, header, formData, body)
  let scheme = call_603205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603205.url(scheme.get, call_603205.host, call_603205.base,
                         call_603205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603205, url, valid)

proc call*(call_603206: Call_InvalidateProjectCache_603193; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_603207 = newJObject()
  if body != nil:
    body_603207 = body
  result = call_603206.call(nil, nil, nil, nil, body_603207)

var invalidateProjectCache* = Call_InvalidateProjectCache_603193(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_603194, base: "/",
    url: url_InvalidateProjectCache_603195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_603208 = ref object of OpenApiRestCall_602467
proc url_ListBuilds_603210(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuilds_603209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603211 = header.getOrDefault("X-Amz-Date")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Date", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Security-Token")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Security-Token", valid_603212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603213 = header.getOrDefault("X-Amz-Target")
  valid_603213 = validateParameter(valid_603213, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_603213 != nil:
    section.add "X-Amz-Target", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Content-Sha256", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Algorithm")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Algorithm", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Signature")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Signature", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-SignedHeaders", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Credential")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Credential", valid_603218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603220: Call_ListBuilds_603208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_603220.validator(path, query, header, formData, body)
  let scheme = call_603220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603220.url(scheme.get, call_603220.host, call_603220.base,
                         call_603220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603220, url, valid)

proc call*(call_603221: Call_ListBuilds_603208; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_603222 = newJObject()
  if body != nil:
    body_603222 = body
  result = call_603221.call(nil, nil, nil, nil, body_603222)

var listBuilds* = Call_ListBuilds_603208(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                      validator: validate_ListBuilds_603209,
                                      base: "/", url: url_ListBuilds_603210,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_603223 = ref object of OpenApiRestCall_602467
proc url_ListBuildsForProject_603225(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuildsForProject_603224(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603226 = header.getOrDefault("X-Amz-Date")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Date", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Security-Token")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Security-Token", valid_603227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603228 = header.getOrDefault("X-Amz-Target")
  valid_603228 = validateParameter(valid_603228, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_603228 != nil:
    section.add "X-Amz-Target", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Content-Sha256", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Signature")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Signature", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-SignedHeaders", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603235: Call_ListBuildsForProject_603223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_603235.validator(path, query, header, formData, body)
  let scheme = call_603235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603235.url(scheme.get, call_603235.host, call_603235.base,
                         call_603235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603235, url, valid)

proc call*(call_603236: Call_ListBuildsForProject_603223; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_603237 = newJObject()
  if body != nil:
    body_603237 = body
  result = call_603236.call(nil, nil, nil, nil, body_603237)

var listBuildsForProject* = Call_ListBuildsForProject_603223(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_603224, base: "/",
    url: url_ListBuildsForProject_603225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_603238 = ref object of OpenApiRestCall_602467
proc url_ListCuratedEnvironmentImages_603240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCuratedEnvironmentImages_603239(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603241 = header.getOrDefault("X-Amz-Date")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Date", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Security-Token")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Security-Token", valid_603242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603243 = header.getOrDefault("X-Amz-Target")
  valid_603243 = validateParameter(valid_603243, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_603243 != nil:
    section.add "X-Amz-Target", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Signature")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Signature", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-SignedHeaders", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_ListCuratedEnvironmentImages_603238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603250, url, valid)

proc call*(call_603251: Call_ListCuratedEnvironmentImages_603238; body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_603252 = newJObject()
  if body != nil:
    body_603252 = body
  result = call_603251.call(nil, nil, nil, nil, body_603252)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_603238(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_603239, base: "/",
    url: url_ListCuratedEnvironmentImages_603240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_603253 = ref object of OpenApiRestCall_602467
proc url_ListProjects_603255(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_603254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603256 = header.getOrDefault("X-Amz-Date")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Date", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Security-Token")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Security-Token", valid_603257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603258 = header.getOrDefault("X-Amz-Target")
  valid_603258 = validateParameter(valid_603258, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_603258 != nil:
    section.add "X-Amz-Target", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Content-Sha256", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Algorithm")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Algorithm", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Signature")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Signature", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-SignedHeaders", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Credential")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Credential", valid_603263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_ListProjects_603253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_ListProjects_603253; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_603267 = newJObject()
  if body != nil:
    body_603267 = body
  result = call_603266.call(nil, nil, nil, nil, body_603267)

var listProjects* = Call_ListProjects_603253(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_603254, base: "/", url: url_ListProjects_603255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_603268 = ref object of OpenApiRestCall_602467
proc url_ListSourceCredentials_603270(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSourceCredentials_603269(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603271 = header.getOrDefault("X-Amz-Date")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Date", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Security-Token")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Security-Token", valid_603272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603273 = header.getOrDefault("X-Amz-Target")
  valid_603273 = validateParameter(valid_603273, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_603273 != nil:
    section.add "X-Amz-Target", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Signature")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Signature", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603280: Call_ListSourceCredentials_603268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_603280.validator(path, query, header, formData, body)
  let scheme = call_603280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603280.url(scheme.get, call_603280.host, call_603280.base,
                         call_603280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603280, url, valid)

proc call*(call_603281: Call_ListSourceCredentials_603268; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_603282 = newJObject()
  if body != nil:
    body_603282 = body
  result = call_603281.call(nil, nil, nil, nil, body_603282)

var listSourceCredentials* = Call_ListSourceCredentials_603268(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_603269, base: "/",
    url: url_ListSourceCredentials_603270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_603283 = ref object of OpenApiRestCall_602467
proc url_StartBuild_603285(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBuild_603284(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603288 = header.getOrDefault("X-Amz-Target")
  valid_603288 = validateParameter(valid_603288, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_603288 != nil:
    section.add "X-Amz-Target", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603295: Call_StartBuild_603283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_603295.validator(path, query, header, formData, body)
  let scheme = call_603295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603295.url(scheme.get, call_603295.host, call_603295.base,
                         call_603295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603295, url, valid)

proc call*(call_603296: Call_StartBuild_603283; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_603297 = newJObject()
  if body != nil:
    body_603297 = body
  result = call_603296.call(nil, nil, nil, nil, body_603297)

var startBuild* = Call_StartBuild_603283(name: "startBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                      validator: validate_StartBuild_603284,
                                      base: "/", url: url_StartBuild_603285,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_603298 = ref object of OpenApiRestCall_602467
proc url_StopBuild_603300(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopBuild_603299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603301 = header.getOrDefault("X-Amz-Date")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Date", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Security-Token")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Security-Token", valid_603302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603303 = header.getOrDefault("X-Amz-Target")
  valid_603303 = validateParameter(valid_603303, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_603303 != nil:
    section.add "X-Amz-Target", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603310: Call_StopBuild_603298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_603310.validator(path, query, header, formData, body)
  let scheme = call_603310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603310.url(scheme.get, call_603310.host, call_603310.base,
                         call_603310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603310, url, valid)

proc call*(call_603311: Call_StopBuild_603298; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_603312 = newJObject()
  if body != nil:
    body_603312 = body
  result = call_603311.call(nil, nil, nil, nil, body_603312)

var stopBuild* = Call_StopBuild_603298(name: "stopBuild", meth: HttpMethod.HttpPost,
                                    host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                    validator: validate_StopBuild_603299,
                                    base: "/", url: url_StopBuild_603300,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_603313 = ref object of OpenApiRestCall_602467
proc url_UpdateProject_603315(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_603314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603318 = header.getOrDefault("X-Amz-Target")
  valid_603318 = validateParameter(valid_603318, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_603318 != nil:
    section.add "X-Amz-Target", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Signature")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Signature", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_UpdateProject_603313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_UpdateProject_603313; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_603327 = newJObject()
  if body != nil:
    body_603327 = body
  result = call_603326.call(nil, nil, nil, nil, body_603327)

var updateProject* = Call_UpdateProject_603313(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_603314, base: "/", url: url_UpdateProject_603315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_603328 = ref object of OpenApiRestCall_602467
proc url_UpdateWebhook_603330(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWebhook_603329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Security-Token")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Security-Token", valid_603332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603333 = header.getOrDefault("X-Amz-Target")
  valid_603333 = validateParameter(valid_603333, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_603333 != nil:
    section.add "X-Amz-Target", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Content-Sha256", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Algorithm")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Algorithm", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Signature")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Signature", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-SignedHeaders", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Credential")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Credential", valid_603338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603340: Call_UpdateWebhook_603328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_603340.validator(path, query, header, formData, body)
  let scheme = call_603340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603340.url(scheme.get, call_603340.host, call_603340.base,
                         call_603340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603340, url, valid)

proc call*(call_603341: Call_UpdateWebhook_603328; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_603342 = newJObject()
  if body != nil:
    body_603342 = body
  result = call_603341.call(nil, nil, nil, nil, body_603342)

var updateWebhook* = Call_UpdateWebhook_603328(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_603329, base: "/", url: url_UpdateWebhook_603330,
    schemes: {Scheme.Https, Scheme.Http})
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
