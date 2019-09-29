
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

  OpenApiRestCall_593438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593438): Option[Scheme] {.used.} =
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
  Call_BatchDeleteBuilds_593775 = ref object of OpenApiRestCall_593438
proc url_BatchDeleteBuilds_593777(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteBuilds_593776(path: JsonNode; query: JsonNode;
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
  var valid_593889 = header.getOrDefault("X-Amz-Date")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Date", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593904 = header.getOrDefault("X-Amz-Target")
  valid_593904 = validateParameter(valid_593904, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchDeleteBuilds"))
  if valid_593904 != nil:
    section.add "X-Amz-Target", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Signature")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Signature", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-SignedHeaders", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Credential")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Credential", valid_593909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593933: Call_BatchDeleteBuilds_593775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more builds.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_BatchDeleteBuilds_593775; body: JsonNode): Recallable =
  ## batchDeleteBuilds
  ## Deletes one or more builds.
  ##   body: JObject (required)
  var body_594005 = newJObject()
  if body != nil:
    body_594005 = body
  result = call_594004.call(nil, nil, nil, nil, body_594005)

var batchDeleteBuilds* = Call_BatchDeleteBuilds_593775(name: "batchDeleteBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds",
    validator: validate_BatchDeleteBuilds_593776, base: "/",
    url: url_BatchDeleteBuilds_593777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetBuilds_594044 = ref object of OpenApiRestCall_593438
proc url_BatchGetBuilds_594046(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetBuilds_594045(path: JsonNode; query: JsonNode;
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
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Security-Token")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Security-Token", valid_594048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594049 = header.getOrDefault("X-Amz-Target")
  valid_594049 = validateParameter(valid_594049, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetBuilds"))
  if valid_594049 != nil:
    section.add "X-Amz-Target", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Content-Sha256", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Algorithm")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Algorithm", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Signature")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Signature", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-SignedHeaders", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594056: Call_BatchGetBuilds_594044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about builds.
  ## 
  let valid = call_594056.validator(path, query, header, formData, body)
  let scheme = call_594056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594056.url(scheme.get, call_594056.host, call_594056.base,
                         call_594056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594056, url, valid)

proc call*(call_594057: Call_BatchGetBuilds_594044; body: JsonNode): Recallable =
  ## batchGetBuilds
  ## Gets information about builds.
  ##   body: JObject (required)
  var body_594058 = newJObject()
  if body != nil:
    body_594058 = body
  result = call_594057.call(nil, nil, nil, nil, body_594058)

var batchGetBuilds* = Call_BatchGetBuilds_594044(name: "batchGetBuilds",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds",
    validator: validate_BatchGetBuilds_594045, base: "/", url: url_BatchGetBuilds_594046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetProjects_594059 = ref object of OpenApiRestCall_593438
proc url_BatchGetProjects_594061(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetProjects_594060(path: JsonNode; query: JsonNode;
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
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Security-Token")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Security-Token", valid_594063
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594064 = header.getOrDefault("X-Amz-Target")
  valid_594064 = validateParameter(valid_594064, JString, required = true, default = newJString(
      "CodeBuild_20161006.BatchGetProjects"))
  if valid_594064 != nil:
    section.add "X-Amz-Target", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Content-Sha256", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Algorithm")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Algorithm", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Signature")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Signature", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-SignedHeaders", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Credential")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Credential", valid_594069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_BatchGetProjects_594059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about build projects.
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_BatchGetProjects_594059; body: JsonNode): Recallable =
  ## batchGetProjects
  ## Gets information about build projects.
  ##   body: JObject (required)
  var body_594073 = newJObject()
  if body != nil:
    body_594073 = body
  result = call_594072.call(nil, nil, nil, nil, body_594073)

var batchGetProjects* = Call_BatchGetProjects_594059(name: "batchGetProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects",
    validator: validate_BatchGetProjects_594060, base: "/",
    url: url_BatchGetProjects_594061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_594074 = ref object of OpenApiRestCall_593438
proc url_CreateProject_594076(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProject_594075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Security-Token")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Security-Token", valid_594078
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594079 = header.getOrDefault("X-Amz-Target")
  valid_594079 = validateParameter(valid_594079, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateProject"))
  if valid_594079 != nil:
    section.add "X-Amz-Target", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Signature")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Signature", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_CreateProject_594074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a build project.
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_CreateProject_594074; body: JsonNode): Recallable =
  ## createProject
  ## Creates a build project.
  ##   body: JObject (required)
  var body_594088 = newJObject()
  if body != nil:
    body_594088 = body
  result = call_594087.call(nil, nil, nil, nil, body_594088)

var createProject* = Call_CreateProject_594074(name: "createProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateProject",
    validator: validate_CreateProject_594075, base: "/", url: url_CreateProject_594076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_594089 = ref object of OpenApiRestCall_593438
proc url_CreateWebhook_594091(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWebhook_594090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Security-Token")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Security-Token", valid_594093
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594094 = header.getOrDefault("X-Amz-Target")
  valid_594094 = validateParameter(valid_594094, JString, required = true, default = newJString(
      "CodeBuild_20161006.CreateWebhook"))
  if valid_594094 != nil:
    section.add "X-Amz-Target", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Content-Sha256", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Credential")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Credential", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_CreateWebhook_594089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_CreateWebhook_594089; body: JsonNode): Recallable =
  ## createWebhook
  ## <p>For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables AWS CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an AWS CodeBuild project, and the project is used as a build step in AWS CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through AWS CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using AWS CodePipeline, we recommend that you disable webhooks in AWS CodeBuild. In the AWS CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
  ##   body: JObject (required)
  var body_594103 = newJObject()
  if body != nil:
    body_594103 = body
  result = call_594102.call(nil, nil, nil, nil, body_594103)

var createWebhook* = Call_CreateWebhook_594089(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook",
    validator: validate_CreateWebhook_594090, base: "/", url: url_CreateWebhook_594091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProject_594104 = ref object of OpenApiRestCall_593438
proc url_DeleteProject_594106(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProject_594105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594107 = header.getOrDefault("X-Amz-Date")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Date", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Security-Token")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Security-Token", valid_594108
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594109 = header.getOrDefault("X-Amz-Target")
  valid_594109 = validateParameter(valid_594109, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteProject"))
  if valid_594109 != nil:
    section.add "X-Amz-Target", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Algorithm")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Algorithm", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-SignedHeaders", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_DeleteProject_594104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a build project.
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_DeleteProject_594104; body: JsonNode): Recallable =
  ## deleteProject
  ## Deletes a build project.
  ##   body: JObject (required)
  var body_594118 = newJObject()
  if body != nil:
    body_594118 = body
  result = call_594117.call(nil, nil, nil, nil, body_594118)

var deleteProject* = Call_DeleteProject_594104(name: "deleteProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteProject",
    validator: validate_DeleteProject_594105, base: "/", url: url_DeleteProject_594106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSourceCredentials_594119 = ref object of OpenApiRestCall_593438
proc url_DeleteSourceCredentials_594121(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSourceCredentials_594120(path: JsonNode; query: JsonNode;
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
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Security-Token")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Security-Token", valid_594123
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594124 = header.getOrDefault("X-Amz-Target")
  valid_594124 = validateParameter(valid_594124, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteSourceCredentials"))
  if valid_594124 != nil:
    section.add "X-Amz-Target", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Algorithm")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Algorithm", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-SignedHeaders", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Credential")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Credential", valid_594129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594131: Call_DeleteSourceCredentials_594119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ## 
  let valid = call_594131.validator(path, query, header, formData, body)
  let scheme = call_594131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594131.url(scheme.get, call_594131.host, call_594131.base,
                         call_594131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594131, url, valid)

proc call*(call_594132: Call_DeleteSourceCredentials_594119; body: JsonNode): Recallable =
  ## deleteSourceCredentials
  ##  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
  ##   body: JObject (required)
  var body_594133 = newJObject()
  if body != nil:
    body_594133 = body
  result = call_594132.call(nil, nil, nil, nil, body_594133)

var deleteSourceCredentials* = Call_DeleteSourceCredentials_594119(
    name: "deleteSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials",
    validator: validate_DeleteSourceCredentials_594120, base: "/",
    url: url_DeleteSourceCredentials_594121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_594134 = ref object of OpenApiRestCall_593438
proc url_DeleteWebhook_594136(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWebhook_594135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Security-Token")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Security-Token", valid_594138
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594139 = header.getOrDefault("X-Amz-Target")
  valid_594139 = validateParameter(valid_594139, JString, required = true, default = newJString(
      "CodeBuild_20161006.DeleteWebhook"))
  if valid_594139 != nil:
    section.add "X-Amz-Target", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Content-Sha256", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Algorithm")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Algorithm", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Signature")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Signature", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-SignedHeaders", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Credential")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Credential", valid_594144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594146: Call_DeleteWebhook_594134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ## 
  let valid = call_594146.validator(path, query, header, formData, body)
  let scheme = call_594146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594146.url(scheme.get, call_594146.host, call_594146.base,
                         call_594146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594146, url, valid)

proc call*(call_594147: Call_DeleteWebhook_594134; body: JsonNode): Recallable =
  ## deleteWebhook
  ## For an existing AWS CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops AWS CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
  ##   body: JObject (required)
  var body_594148 = newJObject()
  if body != nil:
    body_594148 = body
  result = call_594147.call(nil, nil, nil, nil, body_594148)

var deleteWebhook* = Call_DeleteWebhook_594134(name: "deleteWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook",
    validator: validate_DeleteWebhook_594135, base: "/", url: url_DeleteWebhook_594136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSourceCredentials_594149 = ref object of OpenApiRestCall_593438
proc url_ImportSourceCredentials_594151(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportSourceCredentials_594150(path: JsonNode; query: JsonNode;
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
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Security-Token")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Security-Token", valid_594153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594154 = header.getOrDefault("X-Amz-Target")
  valid_594154 = validateParameter(valid_594154, JString, required = true, default = newJString(
      "CodeBuild_20161006.ImportSourceCredentials"))
  if valid_594154 != nil:
    section.add "X-Amz-Target", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Content-Sha256", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Algorithm")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Algorithm", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Signature")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Signature", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-SignedHeaders", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Credential")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Credential", valid_594159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594161: Call_ImportSourceCredentials_594149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ## 
  let valid = call_594161.validator(path, query, header, formData, body)
  let scheme = call_594161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594161.url(scheme.get, call_594161.host, call_594161.base,
                         call_594161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594161, url, valid)

proc call*(call_594162: Call_ImportSourceCredentials_594149; body: JsonNode): Recallable =
  ## importSourceCredentials
  ##  Imports the source repository credentials for an AWS CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
  ##   body: JObject (required)
  var body_594163 = newJObject()
  if body != nil:
    body_594163 = body
  result = call_594162.call(nil, nil, nil, nil, body_594163)

var importSourceCredentials* = Call_ImportSourceCredentials_594149(
    name: "importSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials",
    validator: validate_ImportSourceCredentials_594150, base: "/",
    url: url_ImportSourceCredentials_594151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvalidateProjectCache_594164 = ref object of OpenApiRestCall_593438
proc url_InvalidateProjectCache_594166(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InvalidateProjectCache_594165(path: JsonNode; query: JsonNode;
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
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Security-Token")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Security-Token", valid_594168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594169 = header.getOrDefault("X-Amz-Target")
  valid_594169 = validateParameter(valid_594169, JString, required = true, default = newJString(
      "CodeBuild_20161006.InvalidateProjectCache"))
  if valid_594169 != nil:
    section.add "X-Amz-Target", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Content-Sha256", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Algorithm")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Algorithm", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Signature")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Signature", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-SignedHeaders", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Credential")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Credential", valid_594174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594176: Call_InvalidateProjectCache_594164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the cache for a project.
  ## 
  let valid = call_594176.validator(path, query, header, formData, body)
  let scheme = call_594176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594176.url(scheme.get, call_594176.host, call_594176.base,
                         call_594176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594176, url, valid)

proc call*(call_594177: Call_InvalidateProjectCache_594164; body: JsonNode): Recallable =
  ## invalidateProjectCache
  ## Resets the cache for a project.
  ##   body: JObject (required)
  var body_594178 = newJObject()
  if body != nil:
    body_594178 = body
  result = call_594177.call(nil, nil, nil, nil, body_594178)

var invalidateProjectCache* = Call_InvalidateProjectCache_594164(
    name: "invalidateProjectCache", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache",
    validator: validate_InvalidateProjectCache_594165, base: "/",
    url: url_InvalidateProjectCache_594166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_594179 = ref object of OpenApiRestCall_593438
proc url_ListBuilds_594181(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuilds_594180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Security-Token")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Security-Token", valid_594183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594184 = header.getOrDefault("X-Amz-Target")
  valid_594184 = validateParameter(valid_594184, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuilds"))
  if valid_594184 != nil:
    section.add "X-Amz-Target", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Content-Sha256", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Algorithm")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Algorithm", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Signature")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Signature", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-SignedHeaders", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Credential")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Credential", valid_594189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594191: Call_ListBuilds_594179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs, with each build ID representing a single build.
  ## 
  let valid = call_594191.validator(path, query, header, formData, body)
  let scheme = call_594191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594191.url(scheme.get, call_594191.host, call_594191.base,
                         call_594191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594191, url, valid)

proc call*(call_594192: Call_ListBuilds_594179; body: JsonNode): Recallable =
  ## listBuilds
  ## Gets a list of build IDs, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_594193 = newJObject()
  if body != nil:
    body_594193 = body
  result = call_594192.call(nil, nil, nil, nil, body_594193)

var listBuilds* = Call_ListBuilds_594179(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.ListBuilds",
                                      validator: validate_ListBuilds_594180,
                                      base: "/", url: url_ListBuilds_594181,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuildsForProject_594194 = ref object of OpenApiRestCall_593438
proc url_ListBuildsForProject_594196(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuildsForProject_594195(path: JsonNode; query: JsonNode;
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
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Security-Token")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Security-Token", valid_594198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594199 = header.getOrDefault("X-Amz-Target")
  valid_594199 = validateParameter(valid_594199, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListBuildsForProject"))
  if valid_594199 != nil:
    section.add "X-Amz-Target", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Content-Sha256", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Algorithm")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Algorithm", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Signature")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Signature", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-SignedHeaders", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Credential")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Credential", valid_594204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594206: Call_ListBuildsForProject_594194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ## 
  let valid = call_594206.validator(path, query, header, formData, body)
  let scheme = call_594206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594206.url(scheme.get, call_594206.host, call_594206.base,
                         call_594206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594206, url, valid)

proc call*(call_594207: Call_ListBuildsForProject_594194; body: JsonNode): Recallable =
  ## listBuildsForProject
  ## Gets a list of build IDs for the specified build project, with each build ID representing a single build.
  ##   body: JObject (required)
  var body_594208 = newJObject()
  if body != nil:
    body_594208 = body
  result = call_594207.call(nil, nil, nil, nil, body_594208)

var listBuildsForProject* = Call_ListBuildsForProject_594194(
    name: "listBuildsForProject", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject",
    validator: validate_ListBuildsForProject_594195, base: "/",
    url: url_ListBuildsForProject_594196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCuratedEnvironmentImages_594209 = ref object of OpenApiRestCall_593438
proc url_ListCuratedEnvironmentImages_594211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCuratedEnvironmentImages_594210(path: JsonNode; query: JsonNode;
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
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Security-Token")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Security-Token", valid_594213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594214 = header.getOrDefault("X-Amz-Target")
  valid_594214 = validateParameter(valid_594214, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListCuratedEnvironmentImages"))
  if valid_594214 != nil:
    section.add "X-Amz-Target", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Content-Sha256", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Algorithm")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Algorithm", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Signature")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Signature", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-SignedHeaders", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Credential")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Credential", valid_594219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594221: Call_ListCuratedEnvironmentImages_594209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ## 
  let valid = call_594221.validator(path, query, header, formData, body)
  let scheme = call_594221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594221.url(scheme.get, call_594221.host, call_594221.base,
                         call_594221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594221, url, valid)

proc call*(call_594222: Call_ListCuratedEnvironmentImages_594209; body: JsonNode): Recallable =
  ## listCuratedEnvironmentImages
  ## Gets information about Docker images that are managed by AWS CodeBuild.
  ##   body: JObject (required)
  var body_594223 = newJObject()
  if body != nil:
    body_594223 = body
  result = call_594222.call(nil, nil, nil, nil, body_594223)

var listCuratedEnvironmentImages* = Call_ListCuratedEnvironmentImages_594209(
    name: "listCuratedEnvironmentImages", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages",
    validator: validate_ListCuratedEnvironmentImages_594210, base: "/",
    url: url_ListCuratedEnvironmentImages_594211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProjects_594224 = ref object of OpenApiRestCall_593438
proc url_ListProjects_594226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProjects_594225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Security-Token")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Security-Token", valid_594228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594229 = header.getOrDefault("X-Amz-Target")
  valid_594229 = validateParameter(valid_594229, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListProjects"))
  if valid_594229 != nil:
    section.add "X-Amz-Target", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Content-Sha256", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Algorithm")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Algorithm", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Signature")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Signature", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-SignedHeaders", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-Credential")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Credential", valid_594234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594236: Call_ListProjects_594224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of build project names, with each build project name representing a single build project.
  ## 
  let valid = call_594236.validator(path, query, header, formData, body)
  let scheme = call_594236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594236.url(scheme.get, call_594236.host, call_594236.base,
                         call_594236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594236, url, valid)

proc call*(call_594237: Call_ListProjects_594224; body: JsonNode): Recallable =
  ## listProjects
  ## Gets a list of build project names, with each build project name representing a single build project.
  ##   body: JObject (required)
  var body_594238 = newJObject()
  if body != nil:
    body_594238 = body
  result = call_594237.call(nil, nil, nil, nil, body_594238)

var listProjects* = Call_ListProjects_594224(name: "listProjects",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListProjects",
    validator: validate_ListProjects_594225, base: "/", url: url_ListProjects_594226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSourceCredentials_594239 = ref object of OpenApiRestCall_593438
proc url_ListSourceCredentials_594241(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSourceCredentials_594240(path: JsonNode; query: JsonNode;
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
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Security-Token")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Security-Token", valid_594243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594244 = header.getOrDefault("X-Amz-Target")
  valid_594244 = validateParameter(valid_594244, JString, required = true, default = newJString(
      "CodeBuild_20161006.ListSourceCredentials"))
  if valid_594244 != nil:
    section.add "X-Amz-Target", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Content-Sha256", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Algorithm")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Algorithm", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Signature")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Signature", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-SignedHeaders", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594251: Call_ListSourceCredentials_594239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ## 
  let valid = call_594251.validator(path, query, header, formData, body)
  let scheme = call_594251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594251.url(scheme.get, call_594251.host, call_594251.base,
                         call_594251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594251, url, valid)

proc call*(call_594252: Call_ListSourceCredentials_594239; body: JsonNode): Recallable =
  ## listSourceCredentials
  ##  Returns a list of <code>SourceCredentialsInfo</code> objects. 
  ##   body: JObject (required)
  var body_594253 = newJObject()
  if body != nil:
    body_594253 = body
  result = call_594252.call(nil, nil, nil, nil, body_594253)

var listSourceCredentials* = Call_ListSourceCredentials_594239(
    name: "listSourceCredentials", meth: HttpMethod.HttpPost,
    host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials",
    validator: validate_ListSourceCredentials_594240, base: "/",
    url: url_ListSourceCredentials_594241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBuild_594254 = ref object of OpenApiRestCall_593438
proc url_StartBuild_594256(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBuild_594255(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Security-Token")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Security-Token", valid_594258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594259 = header.getOrDefault("X-Amz-Target")
  valid_594259 = validateParameter(valid_594259, JString, required = true, default = newJString(
      "CodeBuild_20161006.StartBuild"))
  if valid_594259 != nil:
    section.add "X-Amz-Target", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Content-Sha256", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Algorithm")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Algorithm", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Signature")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Signature", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-SignedHeaders", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Credential")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Credential", valid_594264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594266: Call_StartBuild_594254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts running a build.
  ## 
  let valid = call_594266.validator(path, query, header, formData, body)
  let scheme = call_594266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594266.url(scheme.get, call_594266.host, call_594266.base,
                         call_594266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594266, url, valid)

proc call*(call_594267: Call_StartBuild_594254; body: JsonNode): Recallable =
  ## startBuild
  ## Starts running a build.
  ##   body: JObject (required)
  var body_594268 = newJObject()
  if body != nil:
    body_594268 = body
  result = call_594267.call(nil, nil, nil, nil, body_594268)

var startBuild* = Call_StartBuild_594254(name: "startBuild",
                                      meth: HttpMethod.HttpPost,
                                      host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StartBuild",
                                      validator: validate_StartBuild_594255,
                                      base: "/", url: url_StartBuild_594256,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBuild_594269 = ref object of OpenApiRestCall_593438
proc url_StopBuild_594271(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopBuild_594270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Security-Token")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Security-Token", valid_594273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594274 = header.getOrDefault("X-Amz-Target")
  valid_594274 = validateParameter(valid_594274, JString, required = true, default = newJString(
      "CodeBuild_20161006.StopBuild"))
  if valid_594274 != nil:
    section.add "X-Amz-Target", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Content-Sha256", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Algorithm")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Algorithm", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Signature")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Signature", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-SignedHeaders", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Credential")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Credential", valid_594279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594281: Call_StopBuild_594269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop running a build.
  ## 
  let valid = call_594281.validator(path, query, header, formData, body)
  let scheme = call_594281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594281.url(scheme.get, call_594281.host, call_594281.base,
                         call_594281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594281, url, valid)

proc call*(call_594282: Call_StopBuild_594269; body: JsonNode): Recallable =
  ## stopBuild
  ## Attempts to stop running a build.
  ##   body: JObject (required)
  var body_594283 = newJObject()
  if body != nil:
    body_594283 = body
  result = call_594282.call(nil, nil, nil, nil, body_594283)

var stopBuild* = Call_StopBuild_594269(name: "stopBuild", meth: HttpMethod.HttpPost,
                                    host: "codebuild.amazonaws.com", route: "/#X-Amz-Target=CodeBuild_20161006.StopBuild",
                                    validator: validate_StopBuild_594270,
                                    base: "/", url: url_StopBuild_594271,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProject_594284 = ref object of OpenApiRestCall_593438
proc url_UpdateProject_594286(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProject_594285(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Security-Token")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Security-Token", valid_594288
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594289 = header.getOrDefault("X-Amz-Target")
  valid_594289 = validateParameter(valid_594289, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateProject"))
  if valid_594289 != nil:
    section.add "X-Amz-Target", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Content-Sha256", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Algorithm")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Algorithm", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Signature")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Signature", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-SignedHeaders", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Credential")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Credential", valid_594294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594296: Call_UpdateProject_594284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of a build project.
  ## 
  let valid = call_594296.validator(path, query, header, formData, body)
  let scheme = call_594296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594296.url(scheme.get, call_594296.host, call_594296.base,
                         call_594296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594296, url, valid)

proc call*(call_594297: Call_UpdateProject_594284; body: JsonNode): Recallable =
  ## updateProject
  ## Changes the settings of a build project.
  ##   body: JObject (required)
  var body_594298 = newJObject()
  if body != nil:
    body_594298 = body
  result = call_594297.call(nil, nil, nil, nil, body_594298)

var updateProject* = Call_UpdateProject_594284(name: "updateProject",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateProject",
    validator: validate_UpdateProject_594285, base: "/", url: url_UpdateProject_594286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_594299 = ref object of OpenApiRestCall_593438
proc url_UpdateWebhook_594301(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWebhook_594300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594302 = header.getOrDefault("X-Amz-Date")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Date", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Security-Token")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Security-Token", valid_594303
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594304 = header.getOrDefault("X-Amz-Target")
  valid_594304 = validateParameter(valid_594304, JString, required = true, default = newJString(
      "CodeBuild_20161006.UpdateWebhook"))
  if valid_594304 != nil:
    section.add "X-Amz-Target", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Content-Sha256", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Signature")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Signature", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-SignedHeaders", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Credential")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Credential", valid_594309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594311: Call_UpdateWebhook_594299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ## 
  let valid = call_594311.validator(path, query, header, formData, body)
  let scheme = call_594311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594311.url(scheme.get, call_594311.host, call_594311.base,
                         call_594311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594311, url, valid)

proc call*(call_594312: Call_UpdateWebhook_594299; body: JsonNode): Recallable =
  ## updateWebhook
  ## <p> Updates the webhook associated with an AWS CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
  ##   body: JObject (required)
  var body_594313 = newJObject()
  if body != nil:
    body_594313 = body
  result = call_594312.call(nil, nil, nil, nil, body_594313)

var updateWebhook* = Call_UpdateWebhook_594299(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "codebuild.amazonaws.com",
    route: "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook",
    validator: validate_UpdateWebhook_594300, base: "/", url: url_UpdateWebhook_594301,
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
